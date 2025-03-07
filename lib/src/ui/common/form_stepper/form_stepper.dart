import 'package:flutter/material.dart';

class FormStepper extends StatefulWidget {
  final List<dynamic> dispensadores;
  final int currentStep;
  final Color activeColor;
  final Color inactiveColor;

  const FormStepper({
    super.key,
    required this.dispensadores,
    required this.currentStep,
    this.activeColor = Colors.blue,
    this.inactiveColor = const Color(0xFFE0E0E0),
  });

  @override
  State<FormStepper> createState() => _FormStepperState();
}

class _FormStepperState extends State<FormStepper> {
  Widget _buildStepper(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.currentStep == index
            ? widget.activeColor
            : widget.inactiveColor,
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: widget.currentStep == index ? Colors.white : Colors.black,
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
        if (widget.dispensadores.length <= 5) ...[
          ...List.generate(
            widget.dispensadores.length,
            (index) => _buildStepper(index),
          ),
        ] else ...[
          _buildStepper(0),
          if (widget.currentStep > 1) ...[
            const Text('...', style: TextStyle(fontSize: 20)),
            _buildStepper(widget.currentStep - 1),
          ],
          if (widget.currentStep > 0) _buildStepper(widget.currentStep),
          if (widget.currentStep < widget.dispensadores.length - 1) ...[
            _buildStepper(widget.currentStep + 1),
            if (widget.currentStep < widget.dispensadores.length - 2) ...[
              const Text('...', style: TextStyle(fontSize: 20)),
              _buildStepper(widget.dispensadores.length - 1),
            ]
          ],
        ],
      ],
    );
  }
}
