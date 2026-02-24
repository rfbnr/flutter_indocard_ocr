import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_indocard_ocr/flutter_indocard_ocr.dart';

import 'ocr_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _platformVersion = 'Unknown';
  final _plugin = FlutterIndocardOCR();

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  Future<void> _initPlatformState() async {
    String platformVersion;
    try {
      platformVersion =
          await _plugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flutter IndoCard OCR',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            _buildHeaderCard(),

            const SizedBox(height: 32),

            // Features Section
            const Text(
              'Pilih Dokumen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // KTP Card
            _buildOCRCard(
              context: context,
              title: 'Pindai KTP',
              subtitle: 'Scan Kartu Tanda Penduduk Indonesia',
              icon: Icons.credit_card,
              color: Colors.blue,
              onTap: () => _navigateToOCR(context, OcrType.ktp),
            ),

            const SizedBox(height: 16),

            // NPWP Card
            _buildOCRCard(
              context: context,
              title: 'Pindai NPWP',
              subtitle: 'Scan Nomor Pokok Wajib Pajak',
              icon: Icons.description,
              color: Colors.green,
              onTap: () => _navigateToOCR(context, OcrType.npwp),
            ),

            const SizedBox(height: 32),

            // Platform Info
            _buildPlatformInfo(),

            const SizedBox(height: 24),

            // About Section
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.document_scanner, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'IndoCard OCR Demo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'OCR untuk KTP & NPWP Indonesia\nmenggunakan ML Kit & Apple Vision',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOCRCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Platform Information',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _platformVersion,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Fitur OCR',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.check_circle_outline,
          text: 'Ekstraksi otomatis data dari KTP',
        ),
        _buildFeatureItem(
          icon: Icons.check_circle_outline,
          text: 'Ekstraksi otomatis data dari NPWP',
        ),
        _buildFeatureItem(
          icon: Icons.check_circle_outline,
          text: 'Menggunakan Google ML Kit (Android)',
        ),
        _buildFeatureItem(
          icon: Icons.check_circle_outline,
          text: 'Menggunakan Apple Vision (iOS)',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToOCR(BuildContext context, OcrType type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OcrPage(ocrType: type)),
    );
  }
}

enum OcrType { ktp, npwp }
