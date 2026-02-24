import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_page.dart';

class ResultPage extends StatelessWidget {
  final OcrType ocrType;
  final String resultJson;
  final String imagePath;

  const ResultPage({
    super.key,
    required this.ocrType,
    required this.resultJson,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final isKTP = ocrType == OcrType.ktp;
    Map<String, dynamic> data = {};

    try {
      data = jsonDecode(resultJson);
    } catch (e) {
      data = {'error': 'Failed to parse result'};
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isKTP ? 'Hasil Scan KTP' : 'Hasil Scan NPWP'),
        backgroundColor: isKTP ? Colors.blue : Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home),
            tooltip: 'Kembali ke Beranda',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Card
            _buildSuccessCard(),

            const SizedBox(height: 24),

            // Image Preview
            _buildImagePreview(),

            const SizedBox(height: 24),

            // Data Section
            _buildDataSection(isKTP, data),

            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green[400]!,
              Colors.green[600]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Pemindaian Berhasil!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Data berhasil diekstrak dari dokumen',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: File(imagePath).existsSync()
            ? Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              )
            : const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }

  Widget _buildDataSection(bool isKTP, Map<String, dynamic> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isKTP ? Icons.credit_card : Icons.description,
                  color: isKTP ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 12),
                Text(
                  isKTP ? 'Data KTP' : 'Data NPWP',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            if (isKTP) ..._buildKTPFields(data) else ..._buildNPWPFields(data),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildKTPFields(Map<String, dynamic> data) {
    return [
      _buildDataField('NIK', data['nik'] ?? '-'),
      _buildDataField('Nama', data['nama'] ?? '-'),
      _buildDataField('Tempat Lahir', data['tempatLahir'] ?? '-'),
      _buildDataField('Tanggal Lahir', data['tanggalLahir'] ?? '-'),
      _buildDataField('Jenis Kelamin', data['jenisKelamin'] ?? '-'),
      _buildDataField('Alamat', data['alamat'] ?? '-'),
      _buildDataField('RT/RW', data['rtrw'] ?? '-'),
      _buildDataField('Kelurahan/Desa', data['kelurahan'] ?? '-'),
      _buildDataField('Kecamatan', data['kecamatan'] ?? '-'),
      _buildDataField('Kab/Kota', data['kota'] ?? '-'),
      _buildDataField('Provinsi', data['provinsi'] ?? '-'),
      _buildDataField('Agama', data['agama'] ?? '-'),
      _buildDataField('Status Perkawinan', data['statusPerkawinan'] ?? '-'),
      _buildDataField('Pekerjaan', data['pekerjaan'] ?? '-'),
      _buildDataField('Kewarganegaraan', data['kewarganegaraan'] ?? '-'),
      _buildDataField('Berlaku Hingga', data['berlakuHingga'] ?? '-'),
    ];
  }

  List<Widget> _buildNPWPFields(Map<String, dynamic> data) {
    return [
      _buildDataField('NPWP', data['npwp'] ?? '-'),
      _buildDataField('NIK', data['nik'] ?? '-'),
      _buildDataField('Nama', data['nama'] ?? '-'),
      _buildDataField('Alamat', data['alamat'] ?? '-'),
      _buildDataField('KPP', data['kpp'] ?? '-'),
    ];
  }

  Widget _buildDataField(String label, String value) {
    final isEmpty = value.trim().isEmpty || value == '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEmpty ? Colors.red[50] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isEmpty ? Colors.red[200]! : Colors.grey[200]!,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEmpty ? 'Tidak terbaca' : value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isEmpty ? Colors.red[700] : Colors.black87,
                    ),
                  ),
                ),
                if (!isEmpty)
                  IconButton(
                    onPressed: () => _copyToClipboard(value),
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Salin',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.camera_alt),
            label: const Text(
              'Pindai Ulang',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ocrType == OcrType.ktp ? Colors.blue : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home),
            label: const Text(
              'Kembali ke Beranda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: ocrType == OcrType.ktp ? Colors.blue : Colors.green,
                width: 2,
              ),
              foregroundColor: ocrType == OcrType.ktp ? Colors.blue : Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    // Note: In a real app, you'd show a SnackBar here
  }
}
