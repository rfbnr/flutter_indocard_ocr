import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_indocard_ocr/flutter_indocard_ocr.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'home_page.dart';
import 'result_page.dart';

class OcrPage extends StatefulWidget {
  final OcrType ocrType;

  const OcrPage({super.key, required this.ocrType});

  @override
  State<OcrPage> createState() => _OcrPageState();
}

class _OcrPageState extends State<OcrPage> {
  final _plugin = FlutterIndocardOCR();
  final _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final isKTP = widget.ocrType == OcrType.ktp;

    return Scaffold(
      appBar: AppBar(
        title: Text(isKTP ? 'Pindai KTP' : 'Pindai NPWP'),
        backgroundColor: isKTP ? Colors.blue : Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instruction Card
            _buildInstructionCard(isKTP),

            const SizedBox(height: 24),

            // Image Preview or Placeholder
            _buildImagePreview(),

            const SizedBox(height: 24),

            // Error Message
            if (_errorMessage != null) ...[
              _buildErrorMessage(),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            if (!_isProcessing) ...[
              _buildCameraButton(),
              const SizedBox(height: 12),
              _buildGalleryButton(),
            ],

            // Processing Indicator
            if (_isProcessing) _buildProcessingIndicator(),

            const SizedBox(height: 24),

            // Tips Section
            _buildTipsSection(isKTP),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard(bool isKTP) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isKTP ? Icons.credit_card : Icons.description,
              size: 48,
              color: isKTP ? Colors.blue : Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              isKTP
                  ? 'Ambil foto KTP Anda'
                  : 'Ambil foto NPWP Anda',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan seluruh teks terlihat jelas dan dokumen dalam posisi landscape',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: _selectedImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.contain,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada gambar dipilih',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraButton() {
    return ElevatedButton.icon(
      onPressed: _pickImageFromCamera,
      icon: const Icon(Icons.camera_alt, size: 24),
      label: const Text(
        'Ambil Foto',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.ocrType == OcrType.ktp ? Colors.blue : Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildGalleryButton() {
    return OutlinedButton.icon(
      onPressed: _pickImageFromGallery,
      icon: const Icon(Icons.photo_library, size: 24),
      label: const Text(
        'Pilih dari Galeri',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(
          color: widget.ocrType == OcrType.ktp ? Colors.blue : Colors.green,
          width: 2,
        ),
        foregroundColor: widget.ocrType == OcrType.ktp ? Colors.blue : Colors.green,
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Memproses gambar...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Harap tunggu, sedang mengekstrak data',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection(bool isKTP) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tips untuk hasil terbaik:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildTipItem('Pastikan pencahayaan cukup terang'),
        _buildTipItem('Hindari pantulan cahaya pada dokumen'),
        _buildTipItem('Dokumen dalam posisi landscape (horizontal)'),
        _buildTipItem('Pastikan semua teks terlihat jelas'),
        _buildTipItem('Gunakan latar belakang kontras'),
      ],
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 20,
            color: widget.ocrType == OcrType.ktp ? Colors.blue : Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      setState(() {
        _errorMessage = 'Akses kamera ditolak. Silakan izinkan akses kamera di pengaturan.';
      });
      return false;
    } else if (status.isPermanentlyDenied) {
      // Show dialog to open settings
      final shouldOpenSettings = await _showPermissionDialog(
        'Akses Kamera Dibutuhkan',
        'Aplikasi memerlukan akses kamera untuk memindai dokumen. '
        'Silakan izinkan akses kamera di pengaturan aplikasi.',
      );

      if (shouldOpenSettings) {
        await openAppSettings();
      }
      return false;
    }

    return false;
  }

  Future<bool> _showPermissionDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _pickImageFromCamera() async {
    try {
      // Request camera permission first
      final hasPermission = await _requestCameraPermission();

      if (!hasPermission) {
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _errorMessage = null;
        });
        await _processOCR(File(image.path));
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengambil foto: $e';
      });
    }
  }

  Future<bool> _requestStoragePermission() async {
    // For Android 13+ (API 33+), use photos permission
    // For older versions, use storage permission
    Permission permission;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        permission = Permission.photos;
      } else {
        permission = Permission.storage;
      }
    } else {
      permission = Permission.photos;
    }

    final status = await permission.request();

    if (status.isGranted || status.isLimited) {
      return true;
    } else if (status.isDenied) {
      setState(() {
        _errorMessage = 'Akses galeri ditolak. Silakan izinkan akses galeri di pengaturan.';
      });
      return false;
    } else if (status.isPermanentlyDenied) {
      final shouldOpenSettings = await _showPermissionDialog(
        'Akses Galeri Dibutuhkan',
        'Aplikasi memerlukan akses galeri untuk memilih foto dokumen. '
        'Silakan izinkan akses galeri di pengaturan aplikasi.',
      );

      if (shouldOpenSettings) {
        await openAppSettings();
      }
      return false;
    }

    return false;
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // Request storage/photos permission first
      final hasPermission = await _requestStoragePermission();

      if (!hasPermission) {
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _errorMessage = null;
        });
        await _processOCR(File(image.path));
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memilih gambar: $e';
      });
    }
  }

  Future<void> _processOCR(File imageFile) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final imageBytes = await imageFile.readAsBytes();
      String? result;

      if (widget.ocrType == OcrType.ktp) {
        result = await _plugin.scanKTP(imageBytes);
      } else {
        result = await _plugin.scanNPWP(imageBytes);
      }

      if (!mounted) return;

      if (result != null && result.isNotEmpty) {
        // Navigate to result page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultPage(
              ocrType: widget.ocrType,
              resultJson: result!,
              imagePath: imageFile.path,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Tidak ada data yang berhasil diekstrak. Silakan coba lagi dengan foto yang lebih jelas.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saat memproses OCR: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
