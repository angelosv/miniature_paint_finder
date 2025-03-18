import 'dart:io';
import 'package:flutter/material.dart';

class BasicImageViewer extends StatelessWidget {
  final File imageFile;

  const BasicImageViewer({Key? key, required this.imageFile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Zoom: Pellizcar con dos dedos',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(imageFile),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
