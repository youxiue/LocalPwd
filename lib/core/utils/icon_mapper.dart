import 'package:flutter/material.dart';

/// 分类图标名称 → IconData 的统一映射
IconData iconFromString(String name) {
  const map = {
    'folder': Icons.folder_outlined,
    'work': Icons.work_outline,
    'person': Icons.person_outline,
    'email': Icons.email_outlined,
    'lock': Icons.lock_outline,
    'wifi': Icons.wifi,
    'payment': Icons.payment,
    'credit_card': Icons.credit_card,
    'shopping_cart': Icons.shopping_cart_outlined,
    'flight': Icons.flight_takeoff,
    'sports_esports': Icons.sports_esports_outlined,
    'public': Icons.public,
    'cloud': Icons.cloud_outlined,
    'phone_android': Icons.phone_android,
    'vpn_key': Icons.vpn_key_outlined,
    'key': Icons.key,
    'account_balance': Icons.account_balance_outlined,
    'star': Icons.star_outline,
  };
  return map[name] ?? Icons.folder_outlined;
}

/// `#RRGGBB` / `#AARRGGBB` 十六进制字符串 → Color
Color hexToColor(String hex) {
  return Color(int.parse(hex.replaceFirst('#', '0xFF')));
}
