import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../config/colors.dart';
import '../../models/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';

class ChatScreen extends StatefulWidget {
  final String name;

  const ChatScreen({super.key, required this.name});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final Map<String, Duration> _durations = {};

  Timer? _pollTimer;
  Timer? _recTimer;
  bool _recording = false;
  String _recPath = '';
  int _recSeconds = 0;
  String? _playingId;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().markRead(widget.name);
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final chat = context.read<ChatProvider>();
      final before = chat.byName(widget.name)?.messages.length ?? 0;
      await chat.refreshConversation(widget.name);
      final after = chat.byName(widget.name)?.messages.length ?? 0;
      if (after > before) _scrollToBottom();
    });
    _audioPlayer.durationStream.listen((d) {
      final id = _playingId;
      if (id != null && d != null) {
        _durations[id] = d;
      }
    });
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && mounted) {
        setState(() {
          _playingId = null;
          _paused = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _recTimer?.cancel();
    _input.dispose();
    _scroll.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    await context.read<ChatProvider>().send(widget.name, text: text);
    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final dataUrl = await _pickCompressedImage();
    if (dataUrl == null || !mounted) return;
    await context.read<ChatProvider>().send(widget.name, img: dataUrl);
    _scrollToBottom();
  }

  Future<String?> _pickCompressedImage() async {
    final file =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length < 900 * 1024) {
      return 'data:${file.mimeType ?? 'image/jpeg'};base64,'
          '${base64Encode(bytes)}';
    }
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    const maxDim = 900.0;
    var w = img.width.toDouble();
    var h = img.height.toDouble();
    if (w > maxDim || h > maxDim) {
      final sc = maxDim / (w > h ? w : h);
      w = (w * sc).roundToDouble();
      h = (h * sc).roundToDouble();
    }
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      img,
      ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, w, h),
      ui.Paint(),
    );
    final picture = recorder.endRecording();
    final resized = await picture.toImage(w.round(), h.round());
    final data = await resized.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    resized.dispose();
    if (data == null) return null;
    return 'data:image/png;base64,${base64Encode(data.buffer.asUint8List())}';
  }

  // ---------------- التسجيل الصوتي ----------------

  Future<void> _toggleRecording() async {
    if (_recording) {
      await _stopAndSendAudio();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final hasPerm = await _audioRecorder.hasPermission();
    if (!hasPerm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('إذن المايك مطلوب لإرسال رسالة صوتية')),
        );
      }
      return;
    }
    final dir = await Directory.systemTemp.createTemp('hara_voice');
    _recPath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _recPath,
      );
      if (!mounted) return;
      setState(() {
        _recording = true;
        _recSeconds = 0;
      });
      _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recSeconds++);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر بدء التسجيل')),
        );
      }
    }
  }

  Future<void> _stopAndSendAudio() async {
    _recTimer?.cancel();
    final path = _recPath;
    if (mounted) setState(() => _recording = false);
    if (path.isEmpty || !await File(path).exists()) return;
    final bytes = await File(path).readAsBytes();
    try {
      await File(path).delete();
    } catch (_) {}
    if (bytes.isEmpty || !mounted) return;
    final dataUrl = 'data:audio/m4a;base64,${base64Encode(bytes)}';
    await context.read<ChatProvider>().send(widget.name, audio: dataUrl);
    _scrollToBottom();
  }

  // ---------------- تشغيل الصوت ----------------

  Future<void> _togglePlay(ChatMessage m) async {
    final audio = m.audio;
    if (audio == null || audio.isEmpty) return;
    if (_playingId == m.id && !_paused) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _paused = true);
      return;
    }
    if (_playingId == m.id && _paused) {
      await _audioPlayer.play();
      if (mounted) setState(() => _paused = false);
      return;
    }
    await _audioPlayer.stop();
    if (mounted) {
      setState(() {
        _playingId = m.id;
        _paused = false;
      });
    }
    final src = audio;
    final url = src.startsWith('http')
        ? src
        : '${ApiClient.instance.baseUrl}$src';
    try {
      await _audioPlayer.setUrl(url);
      if (mounted) {
        _durations[m.id] = _audioPlayer.duration ?? Duration.zero;
        setState(() {});
      }
      await _audioPlayer.play();
    } catch (_) {
      if (mounted) {
        setState(() {
          _playingId = null;
          _paused = false;
        });
      }
    }
  }

  void _viewImage(String src) {
    final isData = src.startsWith('data:');
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            maxScale: 4,
            child: Center(
              child: isData
                  ? Image.memory(
                      base64Decode(src.contains(',') ? src.split(',').last : src),
                      fit: BoxFit.contain,
                    )
                  : Image.network(
                      '${ApiClient.instance.baseUrl}$src',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image, size: 80),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final conv = chat.byName(widget.name);
    final messages = conv?.messages ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            _peerAvatar(conv),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (conv?.role.isNotEmpty ?? false)
                    Text(
                      conv!.role,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_outlined,
                            size: 44, color: AppColors.textMuted),
                        const SizedBox(height: 10),
                        const Text(
                          'ابدأ المحادثة — قل مرحباً',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(14),
                    itemCount: messages.length,
                    itemBuilder: (context, i) =>
                        _bubble(messages[i]),
                  ),
          ),
          _recordingPanel(),
          _composer(),
        ],
      ),
    );
  }

  Widget _peerAvatar(ChatConversation? conv) {
    final photo = conv?.photo;
    if (photo != null && photo.isNotEmpty && photo.startsWith('http')) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bg2,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.network(
            photo,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _avatarFallback(conv),
          ),
        ),
      );
    }
    return _avatarFallback(conv);
  }

  Widget _avatarFallback(ChatConversation? conv) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.bg2,
        shape: BoxShape.circle,
      ),
      child: Icon(chatIcon(conv?.iconKey ?? 'person'),
          color: AppColors.primary, size: 20),
    );
  }

  Widget _bubble(ChatMessage m) {
    final mine = m.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: m.img == null
            ? const EdgeInsets.symmetric(horizontal: 13, vertical: 9)
            : const EdgeInsets.all(5),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 5),
            bottomRight: Radius.circular(mine ? 5 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.img != null)
              GestureDetector(
                onTap: () => _viewImage(m.img!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: m.img!.startsWith('data:')
                      ? Image.memory(
                          base64Decode(
                              m.img!.contains(',') ? m.img!.split(',').last : m.img!),
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          '${ApiClient.instance.baseUrl}${m.img!}',
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                              width: 200, height: 200, child: Icon(Icons.image)),
                        ),
                ),
              ),
            if (m.img != null && m.text.isNotEmpty)
              const SizedBox(height: 6),
            if (m.isAudio) _audioBubble(m, mine),
            if (m.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  m.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: mine ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chatTime(m.time),
                  style: TextStyle(
                    fontSize: 10,
                    color: mine
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textMuted,
                  ),
                ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    m.read ? Icons.done_all : Icons.done,
                    size: 13,
                    color: m.read
                        ? const Color(0xFF9BE1F0)
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _audioBubble(ChatMessage m, bool mine) {
    final playing = _playingId == m.id && !_paused;
    final duration = _durations[m.id];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _togglePlay(m),
          borderRadius: BorderRadius.circular(30),
          child: Icon(
            playing
                ? Icons.pause_circle_filled
                : Icons.play_circle_fill_rounded,
            size: 36,
            color: mine ? Colors.white : AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 96,
          child: StreamBuilder<Duration>(
            stream: _audioPlayer.positionStream,
            builder: (context, snap) {
              final d = duration ?? const Duration(seconds: 1);
              final pos = (_playingId == m.id)
                  ? (snap.data ?? Duration.zero)
                  : Duration.zero;
              final progress = d.inMilliseconds <= 0
                  ? 0.0
                  : (pos.inMilliseconds / d.inMilliseconds).clamp(0.0, 1.0);
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor:
                      mine ? Colors.white24 : AppColors.bg2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      mine ? Colors.white : AppColors.accent),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(
          duration == null ? '🎤' : formatDuration(duration),
          style: TextStyle(
            fontSize: 11,
            color: mine ? Colors.white.withValues(alpha: 0.85) : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _recordingPanel() {
    if (!_recording) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFFEBEE),
        border: Border(top: BorderSide(color: Color(0xFFF5C6CB))),
      ),
      child: Row(
        children: [
          Icon(Icons.graphic_eq,
              color: Colors.red.shade700, size: 22),
          const SizedBox(width: 10),
          Text(
            'تسجيل: ${formatDuration(Duration(seconds: _recSeconds))}',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            'اضغط زر المايك للإيقاف والإرسال',
            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _sendImage,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.bg2,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.image_outlined,
                  color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _input,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك...',
                hintStyle:
                    TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AppColors.bg2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _toggleRecording,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _recording
                    ? Colors.red.shade600
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _recording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _send,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
