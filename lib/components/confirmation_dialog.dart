import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String cancelText;
  final String confirmText;
  final Color confirmColor;
  final Widget? content;

  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    this.cancelText = 'CANCEL',
    this.confirmText = 'CONFIRM',
    this.confirmColor = Colors.red,
    this.content,
  }) : super(key: key);

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String cancelText = 'CANCEL',
    String confirmText = 'CONFIRM',
    Color confirmColor = Colors.red,
    Widget? content,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => ConfirmationDialog(
            title: title,
            message: message,
            cancelText: cancelText,
            confirmText: confirmText,
            confirmColor: confirmColor,
            content: content,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDarkMode ? AppTheme.darkSurface : Colors.white,
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          if (content != null) ...[const SizedBox(height: 16), content!],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelText,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmText,
            style: TextStyle(color: confirmColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
