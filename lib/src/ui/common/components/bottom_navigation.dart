import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final Widget button1;
  final Widget button2;

  const BottomNavigation({
    super.key,
    required this.button1,
    required this.button2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: button1,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: button2,
            ),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}
