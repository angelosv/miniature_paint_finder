/// A reusable confirmation dialog component that provides a consistent
/// dialog experience throughout the application with customizable content.
///
/// This dialog is designed to handle user confirmations for critical actions
/// such as deletion or important updates. It supports both basic text-only
/// confirmations and more complex confirmations with custom content.
import 'package:flutter/material.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';

/// A customizable confirmation dialog with consistent styling across the app.
///
/// Features:
/// - Consistent rounded corners and styling
/// - Customizable title, message, button texts, and button colors
/// - Optional custom content widget to display additional information
/// - Theme-aware (adapts to light/dark mode)
/// - Static [show] method for easier usage
class ConfirmationDialog extends StatelessWidget {
  /// The title displayed at the top of the dialog
  final String title;

  /// The message displayed in the dialog body
  final String message;

  /// The text for the cancel button (defaults to 'CANCEL')
  final String cancelText;

  /// The text for the confirmation button (defaults to 'CONFIRM')
  final String confirmText;

  /// The color of the confirmation button text (defaults to red)
  final Color confirmColor;

  /// Optional custom widget to display below the message
  final Widget? content;

  /// Creates a confirmation dialog with the specified parameters.
  ///
  /// [title] and [message] are required. Other parameters are optional and have default values.
  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    this.cancelText = 'CANCEL',
    this.confirmText = 'CONFIRM',
    this.confirmColor = Colors.red,
    this.content,
  }) : super(key: key);

  /// Shows the confirmation dialog and returns a Future<bool?> that completes
  /// when the user responds.
  ///
  /// Returns:
  /// - true if the user confirms
  /// - false if the user cancels
  /// - null if the dialog is dismissed
  ///
  /// Example usage:
  /// ```dart
  /// final confirmed = await ConfirmationDialog.show(
  ///   context: context,
  ///   title: 'Delete Item',
  ///   message: 'Are you sure you want to delete this item?',
  ///   confirmText: 'DELETE',
  /// );
  ///
  /// if (confirmed == true) {
  ///   // Proceed with deletion
  /// }
  /// ```
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
    final backgroundColor = isDarkMode ? AppTheme.darkSurface : Colors.white;
    final titleColor = isDarkMode ? Colors.white : Colors.black87;
    final messageColor = isDarkMode ? Colors.white70 : Colors.black87;
    final cancelColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: backgroundColor,
      title: Text(
        title,
        style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: TextStyle(color: messageColor)),
          if (content != null) const SizedBox(height: 16),
          if (content != null) content!,
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText, style: TextStyle(color: cancelColor)),
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
