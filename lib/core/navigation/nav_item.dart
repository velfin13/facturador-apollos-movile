import 'package:flutter/material.dart';
import '../../features/auth/domain/entities/usuario.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget page;
  final List<UserRole> allowedRoles;

  const NavItem({
    required this.label,
    required this.icon,
    required this.page,
    required this.allowedRoles,
    IconData? activeIcon,
  }) : activeIcon = activeIcon ?? icon;

  bool isAllowedFor(UserRole role) {
    return allowedRoles.contains(role);
  }
}
