import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';
import 'package:red_neuro_app/src/ui/common/buttons/simple_button.dart';
import 'package:red_neuro_app/src/ui/common/form_stepper/form_stepper.dart';

class StepFormDialogLayout extends StatelessWidget {
  final String title;
  final int totalSteps;
  final int currentStep;
  final Widget stepContent;
  final bool isSubmitting;
  final String? stepErrorText;
  final String? submitErrorText;
  final String nextLabel;
  final IconData? nextIcon;
  final VoidCallback? onBack;
  final Future<void> Function() onNext;
  final VoidCallback? onClose;
  final String backLabel;

  const StepFormDialogLayout({
    super.key,
    required this.title,
    required this.totalSteps,
    required this.currentStep,
    required this.stepContent,
    required this.isSubmitting,
    required this.nextLabel,
    required this.onNext,
    this.stepErrorText,
    this.submitErrorText,
    this.nextIcon,
    this.onBack,
    this.onClose,
    this.backLabel = 'Atrás',
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;

    Widget errorBox(String message) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.error.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.error.withValues(alpha: .4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: theme.error, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(color: theme.error))),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
          ],
        ),
        FormStepper(longitud: totalSteps, currentStep: currentStep),
        const SizedBox(height: 16),
        if (stepErrorText != null && stepErrorText!.isNotEmpty)
          errorBox(stepErrorText!),
        stepContent,
        const SizedBox(height: 16),
        if (submitErrorText != null && submitErrorText!.isNotEmpty)
          errorBox(submitErrorText!),
        if (isSubmitting)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Guardando...'),
              ],
            ),
          ),
        Row(
          children: [
            if (onBack != null)
              Expanded(
                child: SimpleButton(
                  title: backLabel,
                  outlined: true,
                  background: theme.primary,
                  onTap: onBack,
                ),
              ),
            if (onBack != null) const SizedBox(width: 12),
            Expanded(
              child: SimpleButton(
                title: nextLabel,
                preffixicon: nextIcon,
                disabled: isSubmitting,
                onTap: () => onNext(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
