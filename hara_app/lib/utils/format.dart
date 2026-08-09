import 'package:flutter/material.dart';

const List<String> _months = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

String chatTime(DateTime d) {
  final now = DateTime.now();
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
  if (d.year == now.year) {
    return '${d.day} ${_months[d.month - 1]}';
  }
  return '${d.day}/${d.month}/${d.year}';
}

String formatDuration(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

IconData chatIcon(String iconKey) {
  switch (iconKey) {
    case 'store':
      return Icons.storefront;
    case 'motor':
      return Icons.moped;
    case 'tool':
      return Icons.build;
    case 'truck':
      return Icons.local_shipping;
    default:
      return Icons.person;
  }
}
