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
        if (_hexController.text != null && _hexController.text.isNotEmpty) {
          paintSubmit.hex = _hexController.text;
        }
        if (_setController.text != null && _setController.text.isNotEmpty) {
          paintSubmit.set = _setController.text;
        }

        if (_codeController.text != null && _codeController.text.isNotEmpty) {
          paintSubmit.code = _codeController.text;
        }
        if (_colorController.text != null && _colorController.text.isNotEmpty) {
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
            const SnackBar(
              content: Text('Error sending request, try again later'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error submitting paint: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error submitting paint, try again later'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Paint'), elevation: 0),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Información del código de barras detectado
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                color: AppTheme.primaryBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Detected Barcode',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.barcode ?? 'No barcode detected',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Campos obligatorios
                    Text(
                      'Required Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dropdown de marca
                    DropdownButtonFormField<String>(
                      items:
                          _brands
                              .map(
                                (brand) => DropdownMenuItem(
                                  value: brand['id'] as String,
                                  child: Text(brand['name']),
                                ),
                              )
                              .toList(),
                      decoration: InputDecoration(
                        labelText: 'Brand',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.brush_outlined),
                        filled: true,
                        fillColor:
                            isDarkMode ? AppTheme.darkSurface : Colors.white,
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

                    // Campo de nombre
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.label_outline),
                        filled: true,
                        fillColor:
                            isDarkMode ? AppTheme.darkSurface : Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the paint name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Información adicional
                    Text(
                      'Additional Information (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Campos opcionales
                    TextFormField(
                      controller: _colorController,
                      decoration: InputDecoration(
                        labelText: 'Color',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.color_lens_outlined),
                        filled: true,
                        fillColor:
                            isDarkMode ? AppTheme.darkSurface : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.code),
                        filled: true,
                        fillColor:
                            isDarkMode ? AppTheme.darkSurface : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _setController,
                      decoration: InputDecoration(
                        labelText: 'Set',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.collections_outlined),
                        filled: true,
                        fillColor:
                            isDarkMode ? AppTheme.darkSurface : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Información de color
                    Text(
                      'Color Values (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _hexController,
                      decoration: InputDecoration(
                        labelText: 'Hex Code (e.g. #FF5733)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.palette_outlined),
                        prefixText: '#',
                        filled: true,
                        fillColor:
                            isDarkMode ? AppTheme.darkSurface : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _rController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'R',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor:
                                  isDarkMode
                                      ? AppTheme.darkSurface
                                      : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _gController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'G',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor:
                                  isDarkMode
                                      ? AppTheme.darkSurface
                                      : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _bController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'B',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor:
                                  isDarkMode
                                      ? AppTheme.darkSurface
                                      : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Fotografía
                    Text(
                      'Photo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mostrar la imagen si se ha tomado una foto
                    if (_imageFile != null)
                      Container(
                        height: 200,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),

                    ElevatedButton.icon(
                      onPressed: _getImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take a photo of the label'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Botón de envío
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: AppTheme.marineOrange,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
