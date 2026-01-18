import 'package:flutter/material.dart';
import 'package:red_neuro_app/src/config/theme_controller.dart';

class AvatarType {
  final String text;
  final Color? background;

  const AvatarType({required this.text, this.background});
}

class AvatarData extends StatelessWidget {
  final List<AvatarType> avatars;
  final double size;
  final int? remainingCount;
  final double spacing;

  const AvatarData({
    super.key,
    required this.avatars,
    this.size = 32.0,
    this.remainingCount,
    this.spacing = -10.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return SizedBox(
      height: size,
      width:
          (avatars.length + (remainingCount != null ? 1 : 0)) *
              (size + spacing) +
          size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...List.generate(
            avatars.length,
            (index) => Positioned(
              left: index * (size + spacing),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: size / 2,
                  backgroundColor:
                      avatars[index].background ?? theme.primary20,
                  child: Text(
                    avatars[index].text,
                    // _getInitials(avatars[index].text),
                    style: TextStyle(
                      color: theme.white,
                      fontSize: size / 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (remainingCount != null)
            Positioned(
              left: avatars.length * (size + spacing),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.white, width: 2),
                  color: theme.monochromatic200,
                ),
                child: CircleAvatar(
                  radius: size / 2,
                  backgroundColor: theme.monochromatic200,
                  child: Text(
                    '+$remainingCount',
                    style: TextStyle(
                      color: theme.fontColor,
                      fontSize: size / 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /*  String _getInitials(String text) {
    return text.isNotEmpty ? text.substring(0, 3).toUpperCase() : '';
  } */
}
