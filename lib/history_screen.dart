import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/schemas/history_entry.dart';
import 'package:tip_calculator/service/history_data.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/theme/app_colors.dart';
import 'package:tip_calculator/theme/app_theme.dart';

class MyHistoryScreen extends StatelessWidget {
  const MyHistoryScreen({super.key});

  static String _two(final int value) => value.toString().padLeft(2, '0');

  static String _time(final DateTime date) =>
      '${_two(date.hour)}:${_two(date.minute)}';

  /// Today and yesterday are named; anything older gets its date. Relative
  /// labels stop being helpful once they need counting.
  static String _dayLabel(final TipData tipData, final DateTime date) {
    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(day).inDays;
    if (difference == 0) return tipData.t('history_today');
    if (difference == 1) return tipData.t('history_yesterday');
    return '${_two(date.day)}/${_two(date.month)}/${date.year}';
  }

  Future<void> _confirmClear(final BuildContext context) async {
    final history = context.read<HistoryData>();
    final tipData = context.read<TipData>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tipData.t('history_clear_title')),
        content: Text(tipData.t('history_clear_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(tipData.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(tipData.t('history_clear')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await history.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipData = context.watch<TipData>();

    return Scaffold(
      appBar: AppBar(
        title: Text(tipData.t('history_title')),
        actions: [
          Consumer<HistoryData>(
            builder: (context, history, child) => IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: tipData.t('history_clear'),
              onPressed: history.isEmpty ? null : () => _confirmClear(context),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<HistoryData>(
          builder: (context, history, child) {
            if (!history.isLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            if (history.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    tipData.t('history_empty'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.ink2),
                  ),
                ),
              );
            }

            final entries = history.entries;
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final label = _dayLabel(tipData, entry.date);
                final isFirstOfDay =
                    index == 0 ||
                    _dayLabel(tipData, entries[index - 1].date) != label;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isFirstOfDay)
                      Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 8 : 18,
                          bottom: 6,
                        ),
                        child: Text(label, style: AppTheme.fieldLabel(colors)),
                      ),
                    _HistoryRow(
                      entry: entry,
                      index: index,
                      history: history,
                      tipData: tipData,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final HistoryEntry entry;
  final int index;
  final HistoryData history;
  final TipData tipData;

  const _HistoryRow({
    required this.entry,
    required this.index,
    required this.history,
    required this.tipData,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final byItems = entry.isSplitByItems;
    final accent = byItems ? colors.tip : colors.people;
    final accentBg = byItems ? colors.tipBg : colors.peopleBg;

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: colors.tip,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.only(right: 18),
        child: Icon(Icons.delete_outline, color: colors.surface),
      ),
      onDismissed: (direction) {
        final messenger = ScaffoldMessenger.of(context);
        history.remove(entry.id);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(tipData.t('history_deleted')),
            action: SnackBarAction(
              label: tipData.t('undo'),
              onPressed: () => history.restore(entry, index),
            ),
          ),
        );
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.read<TipData>().loadFrom(entry);
          Navigator.of(context).pop();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  byItems
                      ? Icons.receipt_long_outlined
                      : Icons.groups_outlined,
                  size: 16,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${entry.currencySymbol} '
                      '${entry.total.toStringAsFixed(2)}',
                      style: AppTheme.figure(size: 15, color: colors.ink),
                    ),
                    Text(
                      '${entry.amount.toStringAsFixed(2)}'
                      '  ·  ${entry.tipPercent}%'
                      '  ·  ${entry.people} '
                      '${tipData.t('people_title').toLowerCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: colors.ink2),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    MyHistoryScreen._time(entry.date),
                    style: AppTheme.figure(
                      size: 11,
                      color: colors.ink3,
                      weight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                  if (entry.people > 1)
                    Text(
                      '${entry.totalPerPerson.toStringAsFixed(2)} ea.',
                      style: AppTheme.figure(
                        size: 11,
                        color: colors.ink3,
                        weight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
