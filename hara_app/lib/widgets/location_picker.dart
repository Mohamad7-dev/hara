import 'package:flutter/material.dart';
import '../config/colors.dart';
import '../config/locations.dart';

class AreaSelection {
  final String city;
  final String? neighborhood;

  const AreaSelection(this.city, this.neighborhood);

  String get label => neighborhood == null ? city : '$city · $neighborhood';
  String get area => neighborhood ?? city;
}

Future<AreaSelection?> showLocationPicker(
  BuildContext context, {
  required String initialCity,
  String? initialNeighborhood,
}) {
  return showModalBottomSheet<AreaSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _LocationPickerBody(
      initialCity: initialCity,
      initialNeighborhood: initialNeighborhood,
    ),
  );
}

class _LocationPickerBody extends StatefulWidget {
  final String initialCity;
  final String? initialNeighborhood;

  const _LocationPickerBody({
    required this.initialCity,
    this.initialNeighborhood,
  });

  @override
  State<_LocationPickerBody> createState() => _LocationPickerBodyState();
}

class _LocationPickerBodyState extends State<_LocationPickerBody> {
  late String _city;
  String? _neighborhood;
  bool _showNeighborhoods = false;

  @override
  void initState() {
    super.initState();
    _city = widget.initialCity;
    _neighborhood = widget.initialNeighborhood;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          _header(context),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _showNeighborhoods ? _neighborhoodsList() : _citiesList(),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 10),
      child: Row(
        children: [
          if (_showNeighborhoods)
            IconButton(
              onPressed: () => setState(() => _showNeighborhoods = false),
              icon: const Icon(Icons.arrow_forward,
                  color: AppColors.textPrimary),
            )
          else
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(left: 4, right: 8),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.location_on_outlined,
                  color: AppColors.primary, size: 22),
            ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _showNeighborhoods ? _city : 'اختر مدينتك',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _showNeighborhoods
                      ? 'اختر الحي الأقرب إليك'
                      : 'اختر مدينتك ثم حيّك بدقة',
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (!_showNeighborhoods)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _citiesList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: palestineCities.length,
      separatorBuilder: (_, i) => Divider(
        height: 1,
        indent: 70,
        endIndent: 16,
        color: AppColors.border,
      ),
      itemBuilder: (context, i) {
        final city = palestineCities[i];
        final selected = city == _city;
        final hasNeighborhoods = neighborhoodsOf(city).isNotEmpty;
        return InkWell(
          onTap: () {
            if (!hasNeighborhoods) {
              Navigator.of(context).pop(AreaSelection(city, null));
              return;
            }
            setState(() {
              _city = city;
              _neighborhood = null;
              _showNeighborhoods = true;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.bg2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasNeighborhoods
                        ? Icons.location_city
                        : Icons.place_outlined,
                    size: 20,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    city,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 20),
                if (!selected && hasNeighborhoods)
                  const Icon(Icons.chevron_left,
                      color: AppColors.textLight, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _neighborhoodsList() {
    final neighborhoods = neighborhoodsOf(_city);
    final places = placesOf(_city);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 6),
      children: [
        _selectionTile(
          icon: Icons.location_city,
          iconColor: AppColors.primary,
          title: 'المدينة فقط (${_city})',
          selected: _neighborhood == null,
          onTap: () => Navigator.of(context).pop(AreaSelection(_city, null)),
        ),
        _sectionHeader('الأحياء', Icons.home_work_outlined),
        for (final n in neighborhoods)
          _selectionTile(
            icon: Icons.place_outlined,
            iconColor: AppColors.textSecondary,
            title: n,
            selected: n == _neighborhood,
            onTap: () => Navigator.of(context).pop(AreaSelection(_city, n)),
          ),
        if (places.isNotEmpty) ...[
          _sectionHeader('الأماكن المتاحة', Icons.tour_outlined),
          for (final p in places)
            _selectionTile(
              icon: Icons.pin_drop_outlined,
              iconColor: AppColors.accent,
              title: p,
              selected: p == _neighborhood,
              onTap: () => Navigator.of(context).pop(AreaSelection(_city, p)),
            ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 20),
          ],
        ),
      ),
    );
  }
}
