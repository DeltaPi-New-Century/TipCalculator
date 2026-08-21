import 'package:flutter/material.dart';
import 'package:tip_calculator/service/tip_data.dart';
import 'package:tip_calculator/theme/app_colors.dart';
import 'package:tip_calculator/theme/app_theme.dart';

/// The card rendered off-screen and captured as the shared image.
///
/// Always drawn on the light palette regardless of the user's theme: it ends
/// up on someone else's screen, inside a chat bubble, where a dark card with a
/// transparent-looking ground reads as broken.
class ReceiptCard extends StatelessWidget {
  final TipData tipData;

  const ReceiptCard({super.key, required this.tipData});

  static const AppColors _colors = AppColors.light;

  @override
  Widget build(BuildContext context) {
    final symbol = tipData.currencySymbol;
    final persons = tipData.persons;

    return Material(
      color: _colors.surface,
      child: Container(
        width: 380,
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
        decoration: BoxDecoration(
          color: _colors.surface,
          border: Border.all(color: _colors.line, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tipData.t('app_title').toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w700,
                color: _colors.ink3,
              ),
            ),
            const SizedBox(height: 16),
            _row(
              tipData.t('share_bill'),
              '$symbol ${tipData.amount.toStringAsFixed(2)}',
            ),
            _row(
              '${tipData.t('tip_title')}  ${tipData.tipPercent}%',
              '$symbol ${tipData.tip.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 10),
            Container(height: 2, color: _colors.line),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    tipData.t('total_title').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                      color: _colors.ink2,
                    ),
                  ),
                ),
                Text(
                  '$symbol ${tipData.total.toStringAsFixed(2)}',
                  style: AppTheme.figure(size: 30, color: _colors.ink),
                ),
              ],
            ),
            if (persons.isNotEmpty) ...[
              const SizedBox(height: 16),
              _dashes(),
              const SizedBox(height: 12),
              for (final person in persons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          person.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _colors.ink,
                          ),
                        ),
                      ),
                      Text(
                        '$symbol ${tipData.totalFor(person).toStringAsFixed(2)}',
                        style: AppTheme.figure(size: 14, color: _colors.ink),
                      ),
                    ],
                  ),
                ),
            ] else if (tipData.people > 1) ...[
              const SizedBox(height: 16),
              _dashes(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${tipData.people} '
                      '${tipData.t('people_title').toLowerCase()}',
                      style: TextStyle(fontSize: 14, color: _colors.ink2),
                    ),
                  ),
                  Text(
                    '$symbol '
                    '${tipData.totalPerPerson.toStringAsFixed(2)}',
                    style: AppTheme.figure(size: 16, color: _colors.ink),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(final String label, final String value) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13.5, color: _colors.ink2),
          ),
        ),
        Text(
          value,
          style: AppTheme.figure(
            size: 13.5,
            color: _colors.ink,
            weight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    ),
  );

  Widget _dashes() => Row(
    children: List.generate(
      26,
      (index) => Expanded(
        child: Container(
          height: 1.5,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          color: _colors.line2,
        ),
      ),
    ),
  );
}
