import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:miniature_paint_finder/models/paint_submit.dart';
import 'dart:io';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/services/image_upload_service.dart';
import 'package:miniature_paint_finder/services/paint_api_service.dart';
import 'package:miniature_paint_finder/repositories/paint_repository.dart';
import 'package:flutter/services.dart';


class AddPaintFormScreen extends StatefulWidget {
  final String? barcode;

  const AddPaintFormScreen({Key? key, this.barcode}) : super(key: key);

  @override
  State<AddPaintFormScreen> createState() => _AddPaintFormScreenState();
}

class _AddPaintFormScreenState extends State<AddPaintFormScreen> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _codeController = TextEditingController();
  final _setController = TextEditingController();
  final _colorController = TextEditingController();
  final _hexController = TextEditingController();
  final _rController = TextEditingController();
  final _gController = TextEditingController();
  final _bController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _brands = [];

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadBrands();
  }

  Future<void> loadBrands() async {
    try {
      final PaintApiService paintApiService = PaintApiService();
      final brands = await paintApiService.getBrands();
      setState(() {
        _brands = brands;
      });
    } catch (e) {
      print('Error al cargar las marcas: $e');
    }
  }

  Future<void> _getImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _submitForm() async {
    try {
      final ImageUploadService _imageUploadService = ImageUploadService();
      if (_imageFile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please take a photo of the label')),
        );
        return;
      }
      if (_formKey.currentState!.validate()) {
        setState(() {
          _isLoading = true;
        });
        print('Uploading image');
        final String imageUrl = await _imageUploadService.uploadImage(
          _imageFile!,
        );
        print('Image uploaded: $imageUrl');
        final PaintSubmit paintSubmit = PaintSubmit(
          imageUrl: imageUrl,
          brandId: _brandController.text,
          barcode: widget.barcode ?? '',
          name: _nameController.text,
          status: 'pending',
        );    
        print('start setting values');
        if ( _hexController.text != null && _hexController.text.isNotEmpty) {
          paintSubmit.hex = _hexController.text;
        }
        if ( _setController.text != null && _setController.text.isNotEmpty) {
          paintSubmit.set = _setController.text;
        }

        if ( _codeController.text != null && _codeController.text.isNotEmpty) {
          paintSubmit.code = _codeController.text;
        }
        if ( _colorController.text != null && _colorController.text.isNotEmpty) {
          paintSubmit.color = _colorController.text;
        }
        if (_rController.text != null && _rController.text.isNotEmpty) {
          paintSubmit.r = int.parse(_rController.text);
        }
        if (_gController.text != null && _gController.text.isNotEmpty) {
          paintSubmit.g = int.parse(_gController.text);
        }
        if (_bController.text != null && _bController.text.isNotEmpty) {
          paintSubmit.b = int.parse(_bController.text);
        }
        print('values set');
        final PaintApiService paintApiService = PaintApiService();
        final bool result = await paintApiService.submitPaint(paintSubmit);
        print('Result of submitPaint: $result');
        setState(() {
          _isLoading = false;
        });
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request sent successfully')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error sending request, try again later')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error submitting paint: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error submitting paint, try again later')),
      );
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
              DropdownButtonFormField<String>(
                items: _brands.map((brand) => DropdownMenuItem(
                  value: brand['id'] as String,
                  child: Text(brand['name']),
                )).toList(),
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {  
                  _brandController.text = value!;
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a brand';
                  }
                  return null;
                },
              ),    
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
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

              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Code (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _setController,
                decoration: const InputDecoration(
                  labelText: 'Set (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _hexController,
                decoration: const InputDecoration(
                  labelText: 'Hex (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'R (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _gController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'G (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _bController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'B (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
                        
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
              
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Submit'),
              )
               
            ],
          ),
        ),
      ),
    );
  }
}
