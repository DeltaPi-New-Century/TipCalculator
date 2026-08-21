import 'package:flutter/material.dart';
import 'package:tip_calculator/theme/app_colors.dart';
import 'package:tip_calculator/theme/app_theme.dart';

/// A surface card carrying its domain colour as a 3px left rail.
///
/// The rail replaces the old half-opacity fill: the colour still says which
/// input this is, without tinting the text behind it.
class AppCard extends StatelessWidget {
  final Color rail;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppCard({
    super.key,
    required this.rail,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(15, 13, 15, 13),
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            PositionedDirectional(
              start: 0,
              top: 13,
              bottom: 13,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: rail,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(3),
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Uppercase micro-label sitting above a value.
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTheme.fieldLabel(context.colors));
}

/// Minus / value / plus. Used for head count and tip percentage.
///
/// A stepper beats a keyboard for small integers: a party of four is two taps,
/// and there is no empty-field state to guard against.
class AppStepper extends StatelessWidget {
  final String value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final String decrementLabel;
  final String incrementLabel;

  const AppStepper({
    super.key,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    required this.decrementLabel,
    required this.incrementLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove,
          onPressed: onDecrement,
          semanticLabel: decrementLabel,
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 52),
          alignment: Alignment.center,
          child: Text(
            value,
            style: AppTheme.figure(size: 19, color: colors.ink),
          ),
        ),
        _StepButton(
          icon: Icons.add,
          onPressed: onIncrement,
          semanticLabel: incrementLabel,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  const _StepButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: enabled ? colors.line2 : colors.line),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? colors.ink : colors.ink3,
          ),
        ),
      ),
    );
  }
}
