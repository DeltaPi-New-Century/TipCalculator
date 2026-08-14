import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/service/settings_data.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/theme/app_colors.dart';

/// Appearance picker: System, Light or Dark.
///
/// System is the default and stays an explicit option rather than an implied
/// one -- a user who has chosen Light should keep it when the OS flips at
/// sunset.
Future<void> showThemeSheet(final BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => const _ThemeSheet(),
  );
}

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipData = context.watch<TipData>();
    final settings = context.watch<SettingsData>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.line2,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tipData.t('theme_title'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 14),
            _ThemeOption(
              mode: ThemeMode.system,
              icon: Icons.brightness_auto_outlined,
              label: tipData.t('theme_system'),
              selected: settings.themeMode == ThemeMode.system,
            ),
            const SizedBox(height: 8),
            _ThemeOption(
              mode: ThemeMode.light,
              icon: Icons.light_mode_outlined,
              label: tipData.t('theme_light'),
              selected: settings.themeMode == ThemeMode.light,
            ),
            const SizedBox(height: 8),
            _ThemeOption(
              mode: ThemeMode.dark,
              icon: Icons.dark_mode_outlined,
              label: tipData.t('theme_dark'),
              selected: settings.themeMode == ThemeMode.dark,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final ThemeMode mode;
  final IconData icon;
  final String label;
  final bool selected;

  const _ThemeOption({
    required this.mode,
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.amountBg : colors.sunk,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.read<SettingsData>().setThemeMode(mode),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? colors.amount : colors.ink2,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? colors.amount : colors.ink,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, size: 20, color: colors.amount),
            ],
          ),
        ),
      ),
    );
  }
}
