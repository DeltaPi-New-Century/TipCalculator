import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/schemas/history_entry.dart';
import 'package:tip_calculator/service/history_data.dart';
import 'package:tip_calculator/service/tip_data.dart';

class MyHistoryScreen extends StatelessWidget {
  const MyHistoryScreen({super.key});

  /// Translations come from the remote database, which does not ship the
  /// history keys yet, so every lookup needs a local fallback.
  static String _text(
    final Map<String, String> translations,
    final String key,
    final String fallback,
  ) => translations[key] ?? fallback;

  static String _formatDate(final DateTime date) {
    String two(final int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  Future<void> _confirmClear(
    final BuildContext context,
    final Map<String, String> translations,
  ) async {
    final history = context.read<HistoryData>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_text(translations, 'history_clear_title', 'Clear history')),
        content: Text(
          _text(
            translations,
            'history_clear_body',
            'This deletes every saved calculation. It cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_text(translations, 'cancel', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_text(translations, 'history_clear', 'Clear')),
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
    final translations = context.read<TipData>().translations;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_text(translations, 'history_title', 'History')),
        actions: [
          Consumer<HistoryData>(
            builder: (context, history, child) => IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: _text(translations, 'history_clear', 'Clear'),
              onPressed: history.isEmpty
                  ? null
                  : () => _confirmClear(context, translations),
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
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    _text(
                      translations,
                      'history_empty',
                      'No saved calculations yet.',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.separated(
              itemCount: history.entries.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = history.entries[index];
                return _buildTile(context, history, entry, index, translations);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTile(
    final BuildContext context,
    final HistoryData history,
    final HistoryEntry entry,
    final int index,
    final Map<String, String> translations,
  ) {
    final subtitle = StringBuffer()
      ..write('${entry.currencySymbol} ${entry.amount.toStringAsFixed(2)}')
      ..write('  •  ${entry.tipPercent}%')
      ..write('  •  ${entry.people} ')
      ..write(_text(translations, 'people_title', 'People').toLowerCase());

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.red.shade400,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (direction) {
        final messenger = ScaffoldMessenger.of(context);
        history.remove(entry.id);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(_text(translations, 'history_deleted', 'Deleted')),
            action: SnackBarAction(
              label: _text(translations, 'undo', 'Undo'),
              onPressed: () => history.restore(entry, index),
            ),
          ),
        );
      },
      child: ListTile(
        leading: Icon(
          entry.isSplitByItems
              ? Icons.receipt_long_outlined
              : Icons.groups_outlined,
          size: 20,
        ),
        title: Text(
          '${entry.currencySymbol} ${entry.total.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle.toString()),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDate(entry.date),
              style: const TextStyle(fontSize: 12),
            ),
            if (entry.people > 1)
              Text(
                '${entry.currencySymbol} '
                '${entry.totalPerPerson.toStringAsFixed(2)} '
                '${_text(translations, 'total_per_person', 'Per Person')}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        onTap: () {
          context.read<TipData>().loadFrom(entry);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
