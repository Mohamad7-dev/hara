import 'package:flutter/material.dart';

import '../config/colors.dart';
import '../config/locations.dart';

Future<List<String>?> showAreaMultiSelect(
  BuildContext context,
  List<String> initial,
) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _AreaMultiSelectSheet(initial: List.of(initial)),
  );
}

class AreaSelectField extends StatelessWidget {
  final String label;
  final String hint;

  const AreaSelectField({
    super.key,
    required this.label,
    this.hint = 'اختر منطقة توصيل...',
  });

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      validator: (v) => (v == null || v.isEmpty)
          ? 'اختر منطقة توصيل واحدة على الأقل'
          : null,
      builder: (state) {
        final selected = state.value ?? const <String>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final result = await showAreaMultiSelect(context, selected);
                if (result != null) state.didChange(result);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.hasError
                        ? AppColors.error
                        : AppColors.border,
                  ),
                ),
                child: selected.isEmpty
                    ? Row(
                        children: [
                          const Icon(Icons.add_location_alt_outlined,
                              color: AppColors.accent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              hint,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ),
                          const Icon(Icons.search,
                              color: AppColors.textMuted, size: 20),
                        ],
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final a in selected)
                            _chip(a, () => state.didChange(
                                selected.where((e) => e != a).toList())),
                        ],
                      ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 4),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                      color: AppColors.error, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _chip(String label, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close,
                size: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AreaMultiSelectSheet extends StatefulWidget {
  final List<String> initial;

  const _AreaMultiSelectSheet({required this.initial});

  @override
  State<_AreaMultiSelectSheet> createState() => _AreaMultiSelectSheetState();
}

class _AreaMultiSelectSheetState extends State<_AreaMultiSelectSheet> {
  final _search = TextEditingController();
  late final Set<String> _selected = Set.of(widget.initial);
  final Set<String> _expanded = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String area) {
    setState(() {
      if (!_selected.add(area)) _selected.remove(area);
    });
  }

  String _areaName(String city, String item) => '$city - $item';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  const Icon(Icons.map_outlined,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'مناطق التوصيل',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bg2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selected.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () =>
                        Navigator.of(context).pop(List.of(_selected)),
                    icon: const Icon(Icons.check_circle,
                        color: AppColors.success, size: 26),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'ابحث عن مدينة، حي أو مكان...',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search,
                        color: AppColors.textMuted, size: 20),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.border),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final q = _search.text.trim();
    if (q.isNotEmpty) return _searchResults(q);
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        for (final loc in palestineLocations) ...[
          _cityTile(loc),
          if (_expanded.contains(loc.city)) ...[
            _groupHeader('الأحياء', Icons.home_work_outlined),
            for (final n in loc.neighborhoods)
              _areaTile(
                Icons.place_outlined,
                AppColors.textSecondary,
                _areaName(loc.city, n),
              ),
            if (loc.places.isNotEmpty) ...[
              _groupHeader('الأماكن المتاحة', Icons.tour_outlined),
              for (final p in loc.places)
                _areaTile(
                  Icons.pin_drop_outlined,
                  AppColors.accent,
                  _areaName(loc.city, p),
                ),
            ],
          ],
        ],
      ],
    );
  }

  Widget _searchResults(String q) {
    final results = <Widget>[];
    final lower = q.toLowerCase();
    for (final loc in palestineLocations) {
      if (loc.city.toLowerCase().contains(lower)) {
        results.add(_areaTile(
            Icons.location_city, AppColors.primary, loc.city));
      }
      for (final n in loc.neighborhoods) {
        if (n.toLowerCase().contains(lower)) {
          results.add(_areaTile(
              Icons.place_outlined, AppColors.textSecondary,
              _areaName(loc.city, n)));
        }
      }
      for (final p in loc.places) {
        if (p.toLowerCase().contains(lower)) {
          results.add(_areaTile(
              Icons.pin_drop_outlined, AppColors.accent,
              _areaName(loc.city, p)));
        }
      }
    }
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off,
                size: 52, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(
              'لا توجد نتائج لـ "$q"',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: results,
    );
  }

  Widget _cityTile(CityLocations loc) {
    final selected = _selected.contains(loc.city);
    final expanded = _expanded.contains(loc.city);
    return InkWell(
      onTap: () => setState(() {
        if (expanded) {
          _expanded.remove(loc.city);
        } else {
          _expanded.add(loc.city);
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_city,
                  size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.city,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${loc.neighborhoods.length} حي'
                    '${loc.places.isNotEmpty ? '، ${loc.places.length} مكان' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _toggle(loc.city),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                  minWidth: 34, minHeight: 34),
              icon: Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppColors.success : AppColors.textMuted,
                size: 24,
              ),
            ),
            Icon(
              expanded
                  ? Icons.expand_less
                  : Icons.expand_more,
              color: AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 16, 2),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _areaTile(IconData icon, Color iconColor, String name) {
    final selected = _selected.contains(name);
    return InkWell(
      onTap: () => _toggle(name),
      child: Padding(
        padding: const EdgeInsets.only(right: 16, left: 24, top: 8, bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 19, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppColors.success : AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
