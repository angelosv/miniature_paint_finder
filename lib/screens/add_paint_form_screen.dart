import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:miniature_paint_finder/theme/app_theme.dart';

class AddPaintFormScreen extends StatefulWidget {
  final String? barcode;

  const AddPaintFormScreen({Key? key, this.barcode}) : super(key: key);

  @override
  State<AddPaintFormScreen> createState() => _AddPaintFormScreenState();
}

class _AddPaintFormScreenState extends State<AddPaintFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _codeController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _getImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implementar la lógica de envío
      print('Name: ${_nameController.text}');
      print('Brand: ${_brandController.text}');
      print('Code: ${_codeController.text}');
      print('Barcode: ${widget.barcode}');
      if (_imageFile != null) {
        print('Imagen: ${_imageFile!.path}');
      }
      
      // Mostrar mensaje de éxito y volver
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Paint'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campo de nombre
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Paint Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the paint name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de marca
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the brand';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de código (opcional)
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Code or Paint Set (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Barcode detectado
              if (widget.barcode != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Detected Barcode: ${widget.barcode}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              const SizedBox(height: 16),

              // Botón para tomar foto
              ElevatedButton.icon(
                onPressed: _getImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take a photo of the label'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Vista previa de la imagen
              if (_imageFile != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 24),

              // Botón de envío
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 