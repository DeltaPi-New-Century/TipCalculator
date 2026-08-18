import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tip_calculator/schemas/person.dart';
import 'package:tip_calculator/service/auth_service.dart';
import 'package:tip_calculator/service/session_data.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/theme/app_colors.dart';
import 'package:tip_calculator/theme/app_theme.dart';
import 'package:tip_calculator/total_widget.dart';
import 'package:tip_calculator/widgets/ui.dart';

/// "Split by items" screen: each person gets their own consumption, and the
/// tip is spread in proportion to it.
///
/// The share bar is the point of the screen -- proportional tip is invisible
/// in a column of numbers, so each person's slice of the bill is drawn.
class MySplitScreen extends StatelessWidget {
  const MySplitScreen({super.key});

  /// Rotates through the domain palette so people stay visually distinct.
  static Color _avatarColor(final AppColors colors, final int index) {
    const swatchCount = 4;
    switch (index % swatchCount) {
      case 0:
        return colors.amount;
      case 1:
        return colors.people;
      case 2:
        return colors.tip;
      default:
        return colors.total;
    }
  }

  Future<void> _addItemDialog(
    final BuildContext context,
    final Person person,
  ) async {
    final tipData = context.read<TipData>();
    final session = context.read<SessionData>();
    final result = await showDialog<_ItemDraft>(
      context: context,
      builder: (dialogContext) => const _AddItemDialog(),
    );
    if (result == null) return;

    // An unnamed item is still a valid line on the bill; a zero price is not
    // worth storing.
    if (result.price > 0) {
      final label =
          result.label.isEmpty ? tipData.t('item_label') : result.label;
      // During a session the server owns the list; writing locally would be
      // overwritten by the next snapshot.
      if (session.isActive) {
        await session.addItem(label, result.price);
      } else {
        tipData.addItem(person.id, label, result.price);
      }
    }
  }

  Future<void> _renameDialog(
    final BuildContext context,
    final Person person, {
    required final bool isSelf,
  }) async {
    final tipData = context.read<TipData>();
    final session = context.read<SessionData>();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _RenameDialog(initialName: person.name),
    );
    if (name != null && name.isNotEmpty) {
      if (session.isActive) {
        await session.rename(name);
      } else {
        tipData.renamePerson(person.id, name);
      }
      // Renaming your own seat teaches the app what to call you next time.
      if (isSelf) await tipData.setOwnerName(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipData = context.watch<TipData>();

    return Scaffold(
      appBar: AppBar(
        title: Text(tipData.t('split_title')),
        actions: [
          // Membership comes from people joining with the code, not from the
          // host inventing rows.
          if (!context.watch<SessionData>().isActive)
            IconButton(
              icon: const Icon(Icons.person_add_alt),
              tooltip: tipData.t('person_add'),
              onPressed: () => context.read<TipData>().addPerson(),
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: tipData.persons.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    tipData.t('split_empty'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.ink2),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: tipData.persons.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _PersonCard(
                  person: tipData.persons[index],
                  accent: _avatarColor(colors, index),
                  onAddItem: () =>
                      _addItemDialog(context, tipData.persons[index]),
                  onRename: () => _renameDialog(
                    context,
                    tipData.persons[index],
                    isSelf: tipData.isSessionActive
                        ? tipData.persons[index].id == AuthService.uid
                        : index == 0,
                  ),
                ),
              ),
      ),
      bottomNavigationBar: const MyTotalWidget(showModeToggle: false),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Person person;
  final Color accent;
  final VoidCallback onAddItem;
  final VoidCallback onRename;

  const _PersonCard({
    required this.person,
    required this.accent,
    required this.onAddItem,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipData = context.watch<TipData>();
    final session = context.watch<SessionData>();
    // In a session a person's row is theirs alone: the rules reject writes to
    // anyone else's items, so the UI must not offer them either.
    final mine = !session.isActive || person.id == AuthService.uid;
    final locked = session.isActive && !mine;
    final symbol = tipData.currencySymbol;
    final bill = tipData.amount;
    final share = bill > 0 ? (person.subtotal / bill).clamp(0.0, 1.0) : 0.0;
    final initial = person.name.trim().isEmpty
        ? '?'
        : person.name.trim().characters.first.toUpperCase();

    return AppCard(
      rail: accent,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                child: Text(
                  initial,
                  style: AppTheme.figure(
                    size: 12,
                    color: colors.surface,
                    weight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: mine ? onRename : null,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    person.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                    ),
                  ),
                ),
              ),
              Text(
                '$symbol ${tipData.totalFor(person).toStringAsFixed(2)}',
                style: AppTheme.figure(size: 15, color: colors.ink),
              ),
              if (!session.isActive)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  icon: const Icon(Icons.close),
                  color: colors.ink3,
                  tooltip: tipData.t('person_remove'),
                  onPressed: () =>
                      context.read<TipData>().removePerson(person.id),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 4,
              backgroundColor: colors.sunk,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 8),
          for (final item in person.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(fontSize: 12.5, color: colors.ink2),
                    ),
                  ),
                  Text(
                    item.price.toStringAsFixed(2),
                    style: AppTheme.figure(
                      size: 12.5,
                      color: colors.ink,
                      weight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (mine)
                    InkWell(
                      onTap: () => session.isActive
                          ? session.removeItem(item.id)
                          : context.read<TipData>().removeItem(
                              person.id,
                              item.id,
                            ),
                      borderRadius: BorderRadius.circular(4),
                      child: Icon(Icons.close, size: 13, color: colors.ink3),
                    )
                  else
                    const SizedBox(width: 13),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  tipData.t('tip_share'),
                  style: TextStyle(fontSize: 12.5, color: colors.ink2),
                ),
              ),
              Text(
                tipData.tipFor(person).toStringAsFixed(2),
                style: AppTheme.figure(
                  size: 12.5,
                  color: colors.ink2,
                  weight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 17),
            ],
          ),
          if (!locked)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                tipData.t('item_add'),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
                onPressed: onAddItem,
              ),
            ),
        ],
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
  const _AddItemDialog();

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

  void _submit() {
    final price =
        double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.00;
    Navigator.of(context).pop(_ItemDraft(_labelController.text.trim(), price));
  }

  @override
  Widget build(BuildContext context) {
    final tipData = context.read<TipData>();
    return AlertDialog(
      title: Text(tipData.t('item_add')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: tipData.t('item_label')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[0-9]+[,|.]{0,1}[0-9]*'),
              ),
            ],
            onSubmitted: (value) => _submit(),
            decoration: InputDecoration(labelText: tipData.t('item_price')),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tipData.t('cancel')),
        ),
        TextButton(onPressed: _submit, child: Text(tipData.t('add'))),
      ],
    );
  }
}

class _RenameDialog extends StatefulWidget {
  final String initialName;
  const _RenameDialog({required this.initialName});

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

  void _submit() => Navigator.of(context).pop(_nameController.text.trim());

  @override
  Widget build(BuildContext context) {
    final tipData = context.read<TipData>();
    return AlertDialog(
      title: Text(tipData.t('person_rename')),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (value) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tipData.t('cancel')),
        ),
        TextButton(onPressed: _submit, child: Text(tipData.t('save'))),
      ],
    );
  }
}
