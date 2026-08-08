import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/schemas/person.dart';
import 'package:tip_calculator/service/tip_data.dart';

/// "Split by items" screen: each person gets their own consumption, and the
/// tip is spread in proportion to it.
class MySplitScreen extends StatelessWidget {
  const MySplitScreen({super.key});

  static String _text(
    final Map<String, String> translations,
    final String key,
    final String fallback,
  ) => translations[key] ?? fallback;

  Future<void> _addItemDialog(
    final BuildContext context,
    final Person person,
    final Map<String, String> translations,
  ) async {
    final tipData = context.read<TipData>();
    final result = await showDialog<_ItemDraft>(
      context: context,
      builder: (dialogContext) => _AddItemDialog(translations: translations),
    );
    if (result == null) return;

    // An unnamed item is still a valid line on the bill; a zero price is not
    // worth storing.
    if (result.price > 0) {
      tipData.addItem(
        person.id,
        result.label.isEmpty
            ? _text(translations, 'item_label', 'Item')
            : result.label,
        result.price,
      );
    }
  }

  Future<void> _renameDialog(
    final BuildContext context,
    final Person person,
    final Map<String, String> translations,
  ) async {
    final tipData = context.read<TipData>();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _RenameDialog(translations: translations, initialName: person.name),
    );
    if (name != null && name.isNotEmpty) {
      tipData.renamePerson(person.id, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TipData>(
      builder: (context, tipData, child) {
        final translations = tipData.translations;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(_text(translations, 'split_title', 'Split by items')),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildSummary(context, tipData, translations),
                Expanded(
                  child: tipData.persons.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              _text(
                                translations,
                                'split_empty',
                                'Add the people sharing this bill.',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: tipData.persons.length,
                          itemBuilder: (context, index) => _buildPersonCard(
                            context,
                            tipData,
                            tipData.persons[index],
                            translations,
                          ),
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.read<TipData>().addPerson(),
            icon: const Icon(Icons.person_add_alt),
            label: Text(_text(translations, 'person_add', 'Add person')),
          ),
        );
      },
    );
  }

  Widget _buildSummary(
    final BuildContext context,
    final TipData tipData,
    final Map<String, String> translations,
  ) {
    final symbol = tipData.currencySymbol;
    return Container(
      width: double.infinity,
      color: const Color.fromRGBO(255, 237, 94, 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_text(translations, 'total_title', 'Total')}: '
            '$symbol ${tipData.total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '${_text(translations, 'tip_total', 'Tip')} '
            '(${tipData.tipPercent}%): '
            '$symbol ${tipData.tip.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  Widget _buildPersonCard(
    final BuildContext context,
    final TipData tipData,
    final Person person,
    final Map<String, String> translations,
  ) {
    final symbol = tipData.currencySymbol;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _renameDialog(context, person, translations),
                    child: Text(
                      person.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_remove_outlined),
                  tooltip: _text(translations, 'person_remove', 'Remove'),
                  onPressed: () => tipData.removePerson(person.id),
                ),
              ],
            ),
            for (final item in person.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(item.label)),
                    Text('$symbol ${item.price.toStringAsFixed(2)}'),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => tipData.removeItem(person.id, item.id),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(_text(translations, 'item_add', 'Add item')),
                onPressed: () => _addItemDialog(context, person, translations),
              ),
            ),
            const Divider(height: 8),
            Text(
              '${_text(translations, 'tip_total', 'Tip')}: '
              '$symbol ${tipData.tipFor(person).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${_text(translations, 'total_title', 'Total')}: '
              '$symbol ${tipData.totalFor(person).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// What [_AddItemDialog] returns to its caller.
class _ItemDraft {
  final String label;
  final double price;
  const _ItemDraft(this.label, this.price);
}

/// Owns its own text controllers.
///
/// Creating them in the caller and disposing after `showDialog` returns is a
/// trap: the dialog is still running its exit animation at that point, so the
/// fields rebuild against a disposed controller and the frame throws.
class _AddItemDialog extends StatefulWidget {
  final Map<String, String> translations;
  const _AddItemDialog({required this.translations});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _text(final String key, final String fallback) =>
      widget.translations[key] ?? fallback;

  void _submit() {
    final price =
        double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.00;
    Navigator.of(
      context,
    ).pop(_ItemDraft(_labelController.text.trim(), price));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_text('item_add', 'Add item')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: _text('item_label', 'Item'),
            ),
          ),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[0-9]+[,|.]{0,1}[0-9]*'),
              ),
            ],
            onSubmitted: (value) => _submit(),
            decoration: InputDecoration(
              labelText: _text('item_price', 'Price'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_text('cancel', 'Cancel')),
        ),
        TextButton(onPressed: _submit, child: Text(_text('add', 'Add'))),
      ],
    );
  }
}

class _RenameDialog extends StatefulWidget {
  final Map<String, String> translations;
  final String initialName;
  const _RenameDialog({required this.translations, required this.initialName});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _text(final String key, final String fallback) =>
      widget.translations[key] ?? fallback;

  void _submit() =>
      Navigator.of(context).pop(_nameController.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_text('person_rename', 'Rename')),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (value) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_text('cancel', 'Cancel')),
        ),
        TextButton(onPressed: _submit, child: Text(_text('save', 'Save'))),
      ],
    );
  }
}
