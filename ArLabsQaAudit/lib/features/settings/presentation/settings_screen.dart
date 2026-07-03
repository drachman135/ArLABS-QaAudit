import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../main.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    final bgCard = isDark ? const Color(0xFF0D0F16) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1C2033) : const Color(0xFFE3E8F0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page Header ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0C14) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF141826) : const Color(0xFFE3E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengaturan',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          color: isDark ? Colors.white : const Color(0xFF0D1117),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelola preferensi tampilan dan informasi aplikasi.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? const Color(0xFF6B7A99) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Content ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tampilan ────────────────────────────────────────────────
                  _SectionLabel(label: 'TAMPILAN', isDark: isDark),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.dark_mode_outlined,
                          iconColor: AppTheme.primaryColor,
                          title: 'Mode Gelap',
                          subtitle: 'Aktifkan tampilan gelap untuk mata yang nyaman di malam hari',
                          isDark: isDark,
                          trailing: Switch(
                            value: themeMode == ThemeMode.dark ||
                                (themeMode == ThemeMode.system &&
                                    MediaQuery.of(context).platformBrightness == Brightness.dark),
                            onChanged: (val) {
                              ref.read(themeModeProvider.notifier).state =
                                  val ? ThemeMode.dark : ThemeMode.light;
                            },
                            activeThumbColor: AppTheme.primaryColor,
                          ),
                          isLast: false,
                        ),
                        _SettingsRow(
                          icon: Icons.palette_outlined,
                          iconColor: const Color(0xFF7C3AED),
                          title: 'Tema Warna',
                          subtitle: 'Mengikuti sistem secara otomatis',
                          isDark: isDark,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF111826) : const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1C2538) : const Color(0xFFCDD8F0),
                              ),
                            ),
                            child: Text(
                              'Biru Terang',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Informasi Aplikasi ──────────────────────────────────────
                  _SectionLabel(label: 'INFORMASI APLIKASI', isDark: isDark),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.info_outline_rounded,
                          iconColor: AppTheme.statusWarning,
                          title: 'Versi Aplikasi',
                          subtitle: '1.3.0 — Phase 3: Bug Management',
                          isDark: isDark,
                          trailing: null,
                          isLast: false,
                        ),
                        _SettingsRow(
                          icon: Icons.code_rounded,
                          iconColor: AppTheme.statusPassed,
                          title: 'Teknologi',
                          subtitle: 'Flutter Web · Supabase · Riverpod · GoRouter',
                          isDark: isDark,
                          trailing: null,
                          isLast: false,
                        ),
                        _SettingsRow(
                          icon: Icons.business_rounded,
                          iconColor: AppTheme.primaryColor,
                          title: 'Dibuat Oleh',
                          subtitle: 'ArLabs QA Team',
                          isDark: isDark,
                          trailing: null,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Database ────────────────────────────────────────────────
                  _SectionLabel(label: 'DATABASE', isDark: isDark),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.storage_rounded,
                          iconColor: const Color(0xFF10B981),
                          title: 'Supabase',
                          subtitle: 'Terhubung · pfkafuqkszkozvyrwxxt.supabase.co',
                          isDark: isDark,
                          trailing: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: isDark ? const Color(0xFF3A4255) : const Color(0xFFAAB3C5),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final Widget? trailing;
  final bool isLast;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.trailing,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? const Color(0xFF141826) : const Color(0xFFEEF2F8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(bottom: BorderSide(color: borderColor))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0D1117),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF6B7A99) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
