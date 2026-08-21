import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tip_calculator/service/share_summary.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/theme/app_colors.dart';
import 'package:tip_calculator/widgets/receipt_card.dart';

/// Offers the two share formats.
Future<void> showShareSheet(final BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => const _ShareSheet(),
  );
}

/// Formats the current bill as plain text.
String buildShareText(final TipData tipData) => ShareSummary.build(
  title: tipData.t('app_title'),
  billLabel: tipData.t('share_bill'),
  tipLabel: tipData.t('tip_title'),
  totalLabel: tipData.t('total_title'),
  peopleLabel: tipData.t('people_title').toLowerCase(),
  perPersonLabel: tipData.t('total_per_person'),
  currencySymbol: tipData.currencySymbol,
  amount: tipData.amount,
  tip: tipData.tip,
  tipPercent: tipData.tipPercent,
  total: tipData.total,
  people: tipData.people,
  totalPerPerson: tipData.totalPerPerson,
  persons: tipData.isSplitByItems ? tipData.persons : const [],
);

class _ShareSheet extends StatefulWidget {
  const _ShareSheet();

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  /// Anchors the off-screen receipt so it can be rasterised.
  final GlobalKey _boundaryKey = GlobalKey();
  bool _busy = false;

  Future<void> _shareText() async {
    final tipData = context.read<TipData>();
    final navigator = Navigator.of(context);
    final text = buildShareText(tipData);
    navigator.pop();
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _shareImage() async {
    if (_busy) return;
    setState(() => _busy = true);

    final tipData = context.read<TipData>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // One frame is needed for the off-screen card to lay out before the
      // boundary has anything to paint.
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('receipt not mounted');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('encode failed');

      final bytes = data.buffer.asUint8List();
      navigator.pop();
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(bytes),
              mimeType: 'image/png',
              name: 'tip.png',
            ),
          ],
          // Text alongside the image: chat apps that cannot preview the file
          // still show something useful.
          text: buildShareText(tipData),
        ),
      );
    } catch (error) {
      debugPrint('Share as image failed: $error');
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text(tipData.t('share_failed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tipData = context.watch<TipData>();

    return Stack(
      children: [
        SafeArea(
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
                  tipData.t('share'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 14),
                _ShareOption(
                  icon: Icons.notes_outlined,
                  label: tipData.t('share_as_text'),
                  hint: tipData.t('share_as_text_hint'),
                  onTap: _busy ? null : _shareText,
                ),
                const SizedBox(height: 8),
                _ShareOption(
                  icon: Icons.image_outlined,
                  label: tipData.t('share_as_image'),
                  hint: tipData.t('share_as_image_hint'),
                  busy: _busy,
                  onTap: _busy ? null : _shareImage,
                ),
              ],
            ),
          ),
        ),
        // Rendered for capture, kept out of sight and out of the semantics
        // tree. Offstage would skip painting entirely, so it is offset
        // instead.
        Positioned(
          left: -2000,
          top: 0,
          child: ExcludeSemantics(
            child: RepaintBoundary(
              key: _boundaryKey,
              child: ReceiptCard(tipData: tipData),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback? onTap;
  final bool busy;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.sunk,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colors.amount),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                    ),
                    Text(
                      hint,
                      style: TextStyle(fontSize: 12, color: colors.ink2),
                    ),
                  ],
                ),
              ),
              if (busy)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.amount,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
