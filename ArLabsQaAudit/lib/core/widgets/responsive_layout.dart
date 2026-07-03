import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const ResponsiveLayout({
    super.key,
    required this.child,
    required this.currentPath,
  });

  static const _navItems = [
    _NavDef(label: 'Beranda',       path: '/',         icon: Icons.home_outlined,         activeIcon: Icons.home_rounded),
    _NavDef(label: 'Proyek',        path: '/projects', icon: Icons.folder_open_outlined,  activeIcon: Icons.folder_rounded),
    _NavDef(label: 'Laporan Bug',   path: '/bugs',     icon: Icons.bug_report_outlined,   activeIcon: Icons.bug_report_rounded),
    _NavDef(label: 'Pengaturan',    path: '/settings', icon: Icons.settings_outlined,     activeIcon: Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 700) {
      return _DesktopShell(child: child, currentPath: currentPath, navItems: _navItems);
    } else {
      return _MobileShell(child: child, currentPath: currentPath, navItems: _navItems);
    }
  }
}

// ──────────────────────────────────────────────
// DESKTOP SHELL — Top Navigation Bar
// ──────────────────────────────────────────────
class _DesktopShell extends StatelessWidget {
  final Widget child;
  final String currentPath;
  final List<_NavDef> navItems;

  const _DesktopShell({
    required this.child,
    required this.currentPath,
    required this.navItems,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _TopNavBar(currentPath: currentPath, navItems: navItems),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TopNavBar extends StatelessWidget {
  final String currentPath;
  final List<_NavDef> navItems;

  const _TopNavBar({required this.currentPath, required this.navItems});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0C14) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF141826) : const Color(0xFFE3E8F0),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Row(
          children: [
            // ── Logo / Brand ──
            _BrandLogo(isDark: isDark, theme: theme),
            const SizedBox(width: 40),

            // ── Nav Items ──
            ...navItems.map((item) {
              final isActive = item.path == '/'
                  ? currentPath == '/' || currentPath.isEmpty
                  : currentPath.startsWith(item.path);
              return _TopNavItem(
                def: item,
                isActive: isActive,
                isDark: isDark,
                theme: theme,
              );
            }),

            const Spacer(),

            // ── Version Badge ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF111826)
                    : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1C2538)
                      : const Color(0xFFCDD8F0),
                ),
              ),
              child: Text(
                'v1.3.0 · Phase 3',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: isDark
                      ? const Color(0xFF4A6080)
                      : const Color(0xFF8099C0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _BrandLogo({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(Icons.fact_check_rounded, color: Colors.white, size: 15),
        ),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'ArLabs ',
                style: TextStyle(
                  fontFamily: theme.textTheme.titleMedium?.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF0D1117),
                ),
              ),
              TextSpan(
                text: 'QA',
                style: TextStyle(
                  fontFamily: theme.textTheme.titleMedium?.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopNavItem extends StatefulWidget {
  final _NavDef def;
  final bool isActive;
  final bool isDark;
  final ThemeData theme;

  const _TopNavItem({
    required this.def,
    required this.isActive,
    required this.isDark,
    required this.theme,
  });

  @override
  State<_TopNavItem> createState() => _TopNavItemState();
}

class _TopNavItemState extends State<_TopNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppTheme.primaryColor;
    final hoverColor  = widget.isDark ? const Color(0xFF1A2030) : const Color(0xFFF0F4FF);
    final textColor = widget.isActive
        ? activeColor
        : _hovered
            ? (widget.isDark ? Colors.white : const Color(0xFF0D1117))
            : (widget.isDark ? const Color(0xFF6B7A99) : const Color(0xFF6B7280));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(widget.def.path),
        child: Container(
          height: 54,
          margin: const EdgeInsets.only(right: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _hovered && !widget.isActive ? hoverColor : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: widget.isActive ? activeColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isActive ? widget.def.activeIcon : widget.def.icon,
                size: 16,
                color: textColor,
              ),
              const SizedBox(width: 7),
              Text(
                widget.def.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// MOBILE SHELL — AppBar + Drawer
// ──────────────────────────────────────────────
class _MobileShell extends StatelessWidget {
  final Widget child;
  final String currentPath;
  final List<_NavDef> navItems;

  const _MobileShell({
    required this.child,
    required this.currentPath,
    required this.navItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A0C14) : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'ArLabs ',
                style: TextStyle(
                  fontFamily: theme.textTheme.titleMedium?.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0D1117),
                ),
              ),
              const TextSpan(
                text: 'QA',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: isDark ? Colors.white : const Color(0xFF0D1117),
            ),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? const Color(0xFF141826) : const Color(0xFFE3E8F0),
          ),
        ),
      ),
      drawer: _buildDrawer(context, isDark, theme),
      body: child,
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark, ThemeData theme) {
    return NavigationDrawer(
      selectedIndex: _selectedIndex(currentPath),
      onDestinationSelected: (index) {
        Navigator.pop(context);
        switch (index) {
          case 0: context.go('/'); break;
          case 1: context.go('/projects'); break;
          case 2: context.go('/bugs'); break;
          case 3: context.go('/settings'); break;
        }
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'ArLabs ',
                  style: TextStyle(
                    fontFamily: theme.textTheme.titleMedium?.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0D1117),
                  ),
                ),
                const TextSpan(
                  text: 'QA',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),
        ...navItems.map((item) => NavigationDrawerDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.activeIcon),
          label: Text(item.label),
        )),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'v1.3.0 · Phase 3',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF3A4255) : const Color(0xFFAAB3C5),
            ),
          ),
        ),
      ],
    );
  }

  int _selectedIndex(String path) {
    if (path.startsWith('/projects')) return 1;
    if (path.startsWith('/bugs'))     return 2;
    if (path.startsWith('/settings')) return 3;
    return 0;
  }
}

// ──────────────────────────────────────────────
// Navigation definition struct
// ──────────────────────────────────────────────
class _NavDef {
  final String label;
  final String path;
  final IconData icon;
  final IconData activeIcon;

  const _NavDef({
    required this.label,
    required this.path,
    required this.icon,
    required this.activeIcon,
  });
}
