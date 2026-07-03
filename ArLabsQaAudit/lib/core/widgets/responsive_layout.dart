import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const ResponsiveLayout({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('QA Audit PWA'),
              surfaceTintColor: Colors.transparent,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
      drawer: isDesktop ? null : _buildDrawer(context),
      body: isDesktop
          ? Row(
              children: [
                _buildSidebar(context),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: child),
              ],
            )
          : child,
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 250,
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Logo/App Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fact_check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'QA Audit PWA',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Sidebar menu items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: ListView(
                children: [
                  _SidebarItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isActive: currentPath == '/' || currentPath.startsWith('/dashboard'),
                    onTap: () => context.go('/'),
                  ),
                  const SizedBox(height: 4),
                  _SidebarItem(
                    icon: Icons.folder_open_outlined,
                    activeIcon: Icons.folder_rounded,
                    label: 'Projects',
                    isActive: currentPath.startsWith('/projects'),
                    onTap: () => context.go('/projects'),
                  ),
                  const SizedBox(height: 4),
                  _SidebarItem(
                    icon: Icons.bug_report_outlined,
                    activeIcon: Icons.bug_report_rounded,
                    label: 'Bugs',
                    isActive: currentPath.startsWith('/bugs'),
                    onTap: () => context.go('/bugs'),
                  ),
                  const SizedBox(height: 4),
                  _SidebarItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: 'Settings',
                    isActive: currentPath.startsWith('/settings'),
                    onTap: () => context.go('/settings'),
                  ),
                ],
              ),
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'v1.0.0 • Foundation',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: _getSelectedIndex(currentPath),
      onDestinationSelected: (index) {
        // Close drawer first
        Navigator.pop(context);
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/projects');
            break;
          case 2:
            context.go('/bugs');
            break;
          case 3:
            context.go('/settings');
            break;
        }
      },
      children: const [
        Padding(
          padding: EdgeInsets.fromLTRB(28, 20, 16, 10),
          child: Text(
            'QA Audit Menu',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: Text('Dashboard'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.folder_open_outlined),
          selectedIcon: Icon(Icons.folder_rounded),
          label: Text('Projects'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.bug_report_outlined),
          selectedIcon: Icon(Icons.bug_report_rounded),
          label: Text('Bugs'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: Text('Settings'),
        ),
      ],
    );
  }

  int _getSelectedIndex(String path) {
    if (path.startsWith('/projects')) return 1;
    if (path.startsWith('/bugs')) return 2;
    if (path.startsWith('/settings')) return 3;
    return 0; // Default to Dashboard
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color activeBgColor = theme.colorScheme.primary.withOpacity(isDark ? 0.12 : 0.08);
    final Color activeTextColor = theme.colorScheme.primary;
    final Color inactiveTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeTextColor : inactiveTextColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? activeTextColor : inactiveTextColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
