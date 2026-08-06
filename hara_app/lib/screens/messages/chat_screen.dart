import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

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
  Timer? _replyTimer;
  Timer? _pollTimer;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().markRead(widget.name);
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final chat = context.read<ChatProvider>();
      final before = chat.byName(widget.name)?.messages.length ?? _lastCount;
      await chat.refreshConversation(widget.name);
      final after = chat.byName(widget.name)?.messages.length ?? 0;
      if (after > before) _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _replyTimer?.cancel();
    _pollTimer?.cancel();
    _input.dispose();
    _scroll.dispose();
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
    if (!context.read<ChatProvider>().online) {
      _scheduleReply(withImage: false);
    }
  }

  Future<void> _sendImage() async {
    final dataUrl = await _pickCompressedImage();
    if (dataUrl == null || !mounted) return;
    await context.read<ChatProvider>().send(widget.name, img: dataUrl);
    if (!context.read<ChatProvider>().online) {
      _scheduleReply(withImage: true);
    }
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

  void _scheduleReply({required bool withImage}) {
    _replyTimer?.cancel();
    final chat = context.read<ChatProvider>();
    _replyTimer = Timer(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      await chat.receive(widget.name, chat.randomReply(withImage: withImage));
      _scrollToBottom();
    });
    _scrollToBottom();
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bg2,
                shape: BoxShape.circle,
              ),
              child: Icon(chatIcon(conv?.iconKey ?? 'person'),
                  color: AppColors.primary, size: 20),
            ),
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
                    child: Text(
                      'ابدأ المحادثة — قل مرحباً 👋',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textMuted),
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
          _composer(),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage m) {
    final mine = m.isMine;
    return Align(
      alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
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
            bottomLeft: Radius.circular(mine ? 5 : 16),
            bottomRight: Radius.circular(mine ? 16 : 5),
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
            Text(
              chatTime(m.time),
              style: TextStyle(
                fontSize: 10,
                color: mine
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
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
