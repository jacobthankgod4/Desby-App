import 'package:flutter/material.dart';

/// Navigation item model for unified shell routing
class NavItem {
  final String label;
  final IconData icon;
  final String? route;
  final VoidCallback? onTap;
  
  const NavItem({
    required this.label,
    required this.icon,
    this.route,
    this.onTap,
  });
}
