import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class FormStepper extends StatefulWidget {
  final int longitud;
  final int currentStep;
  final Color? activeColor;
  final Color? inactiveColor;

  const FormStepper({
    super.key,
    required this.longitud,
    required this.currentStep,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<FormStepper> createState() => _FormStepperState();
}

class _FormStepperState extends State<FormStepper> {
  Widget _buildStepper(int index) {
    final ThemeController theme = ThemeController.instance;
    final Color activeColor = widget.activeColor ?? theme.primary;
    final Color inactiveColor = widget.inactiveColor ?? theme.monochromatic500;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.currentStep == index
            ? activeColor
            : inactiveColor,
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: widget.currentStep == index
                ? theme.calculateTextColor(activeColor)
                : theme.fontColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.longitud <= 5) ...[
          ...List.generate(widget.longitud, (index) => _buildStepper(index)),
        ] else ...[
          _buildStepper(0),
          if (widget.currentStep > 1) ...[
            const Text('...', style: TextStyle(fontSize: 20)),
            _buildStepper(widget.currentStep - 1),
          ],
          if (widget.currentStep > 0) _buildStepper(widget.currentStep),
          if (widget.currentStep < widget.longitud - 1) ...[
            _buildStepper(widget.currentStep + 1),
            if (widget.currentStep < widget.longitud - 2) ...[
              const Text('...', style: TextStyle(fontSize: 20)),
              _buildStepper(widget.longitud - 1),
            ],
          ],
        ],
      ],
    );
  }
}
