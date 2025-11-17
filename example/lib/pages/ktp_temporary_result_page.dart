// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// import '../../../../constants/constants.dart';
// import '../../data/models/ocr_ktp_model.dart';
// import 'camera_ocr_page.dart';

// class KtpTemporaryResultPage extends StatelessWidget {
//   final OcrKtpResultModel result;
//   final String imagePath;
//   final String imagePathCropped;
//   final String imagePathCroppedGrayscale;

//   const KtpTemporaryResultPage({
//     super.key,
//     required this.result,
//     required this.imagePath,
//     required this.imagePathCropped,
//     required this.imagePathCroppedGrayscale,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: const Text('Hasil Pemindaian'),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black87,
//         elevation: 0,
//         systemOverlayStyle: SystemUiOverlayStyle.dark,
//         actions: [
//           IconButton(
//             onPressed: () => _shareResult(),
//             icon: const Icon(Icons.share),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header with confidence score
//             _buildHeaderCard(),

//             const SizedBox(height: 16),

//             // Captured image preview
//             _buildImagePreview(),

//             const SizedBox(height: 16),

//             // Cropped image preview
//             _buildImageCroppedPreview(),

//             const SizedBox(height: 16),

//             _buildImageGrayscaleCroppedPreview(),

//             const SizedBox(height: 16),
//             // KTP Data
//             _buildDataSection(),

//             const SizedBox(height: 16),

//             // Processing info
//             _buildProcessingInfo(),

//             const SizedBox(height: 24),

//             // Action buttons
//             _buildActionButtons(context),

//             const SizedBox(height: 32),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeaderCard() {
//     final isGoodResult = result.confidence >= 0.8;
//     final confidencePercentage = (result.confidence * 100).round();

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Icon(
//             isGoodResult ? Icons.check_circle : Icons.warning,
//             color: isGoodResult ? Colors.green : Colors.orange,
//             size: 48,
//           ),
//           const SizedBox(height: 12),
//           Text(
//             isGoodResult ? 'Pemindaian Berhasil' : 'Hasil Perlu Verifikasi',
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Akurasi: $confidencePercentage%',
//             style: TextStyle(
//               fontSize: 16,
//               color: isGoodResult ? Colors.green : Colors.orange,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           // if (result.warnings.isNotEmpty) ...[
//           //   const SizedBox(height: 12),
//           //   Container(
//           //     padding: const EdgeInsets.all(12),
//           //     decoration: BoxDecoration(
//           //       color: Colors.orange.withValues(alpha: 0.1),
//           //       borderRadius: BorderRadius.circular(8),
//           //       border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
//           //     ),
//           //     child: Column(
//           //       children: result.warnings
//           //           .map(
//           //             (warning) => Row(
//           //               children: [
//           //                 Icon(Icons.info, color: Colors.orange, size: 16),
//           //                 const SizedBox(width: 8),
//           //                 Expanded(
//           //                   child: Text(
//           //                     warning,
//           //                     style: const TextStyle(fontSize: 14),
//           //                   ),
//           //                 ),
//           //               ],
//           //             ),
//           //           )
//           //           .toList(),
//           //     ),
//           //   ),
//           // ],
//         ],
//       ),
//     );
//   }

//   Widget _buildImagePreview() {
//     return Container(
//       height: 200,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(16),
//         child: File(imagePath).existsSync()
//             ? Image.file(File(imagePath), fit: BoxFit.contain)
//             : Container(
//                 color: Colors.grey[200],
//                 child: const Center(
//                   child: Icon(
//                     Icons.image_not_supported,
//                     color: Colors.grey,
//                     size: 48,
//                   ),
//                 ),
//               ),
//       ),
//     );
//   }

//   Widget _buildImageCroppedPreview() {
//     return Container(
//       height: 200,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(16),
//         child: File(imagePathCropped).existsSync()
//             ? Image.file(File(imagePathCropped), fit: BoxFit.contain)
//             : Container(
//                 color: Colors.grey[200],
//                 child: const Center(
//                   child: Icon(
//                     Icons.image_not_supported,
//                     color: Colors.grey,
//                     size: 48,
//                   ),
//                 ),
//               ),
//       ),
//     );
//   }

//   Widget _buildImageGrayscaleCroppedPreview() {
//     return Container(
//       height: 200,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(16),
//         child: File(imagePathCroppedGrayscale).existsSync()
//             ? Image.file(File(imagePathCroppedGrayscale), fit: BoxFit.contain)
//             : Container(
//                 color: Colors.grey[200],
//                 child: const Center(
//                   child: Icon(
//                     Icons.image_not_supported,
//                     color: Colors.grey,
//                     size: 48,
//                   ),
//                 ),
//               ),
//       ),
//     );
//   }

//   Widget _buildDataSection() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Data KTP',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 16),

//           _buildDataField('NIK', result.data.nik ?? '-'),
//           _buildDataField('Nama', result.data.nama ?? '-'),
//           _buildDataField(
//             'Tempat/Tanggal Lahir',
//             '${result.data.tempatLahir}, ${result.data.tanggalLahir}',
//           ),
//           _buildDataField('Jenis Kelamin', result.data.jenisKelamin ?? '-'),
//           // _buildDataField('Golongan Darah', result.data.golonganDarah),
//           _buildDataField('Alamat', result.data.alamat ?? '-'),
//           // _buildDataField(
//           //   'RT/RW',
//           //   '${result.data.rt ?? '-'}/${result.data.rw ?? '-'}',
//           // ),
//           _buildDataField('RT/RW', result.data.rtrw ?? '-'),
//           _buildDataField('Kel/Desa', result.data.kelurahan ?? '-'),
//           _buildDataField('Kecamatan', result.data.kecamatan ?? '-'),
//           _buildDataField('Kabupaten/Kota', result.data.kota ?? '-'),
//           _buildDataField('Agama', result.data.agama ?? '-'),
//           _buildDataField(
//             'Status Perkawinan',
//             result.data.statusPerkawinan ?? '-',
//           ),
//           _buildDataField('Pekerjaan', result.data.pekerjaan ?? '-'),
//           _buildDataField(
//             'Kewarganegaraan',
//             result.data.kewarganegaraan ?? '-',
//           ),
//           _buildDataField('Berlaku Hingga', result.data.berlakuHingga ?? '-'),
//         ],
//       ),
//     );
//   }

//   Widget _buildDataField(String label, String value) {
//     final isEmpty = value.trim().isEmpty;

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           const Text(': ', style: TextStyle(color: Colors.grey)),
//           Expanded(
//             child: GestureDetector(
//               onTap: isEmpty ? null : () => _copyToClipboard(value),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: isEmpty || (label == 'NIK' && value.length < 16)
//                       ? Colors.red.withValues(alpha: 0.1)
//                       : Colors.transparent,
//                   borderRadius: BorderRadius.circular(4),
//                   border: isEmpty || (label == 'NIK' && value.length < 16)
//                       ? Border.all(color: Colors.red.withValues(alpha: 0.3))
//                       : null,
//                 ),
//                 child: Text(
//                   isEmpty ? 'Tidak terbaca' : value,
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: isEmpty ? Colors.red : Colors.black87,
//                     fontWeight: isEmpty ? FontWeight.w500 : FontWeight.normal,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProcessingInfo() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.blue.withValues(alpha: 0.05),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.info, color: Colors.blue, size: 20),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Waktu Pemrosesan: ${result.processingTime.inMilliseconds}ms',
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.blue,
//                   ),
//                 ),
//                 // if (result.errors.isNotEmpty) ...[
//                 //   const SizedBox(height: 4),
//                 //   Text(
//                 //     'Errors: ${result.errors.join(', ')}',
//                 //     style: const TextStyle(fontSize: 12, color: Colors.red),
//                 //   ),
//                 // ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButtons(BuildContext context) {
//     return Column(
//       children: [
//         // Scan again button
//         SizedBox(
//           width: double.infinity,
//           height: 50,
//           child: ElevatedButton(
//             onPressed: () => _scanAgain(context),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF1565C0),
//               foregroundColor: Colors.white,
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: const Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.camera_alt, size: 20),
//                 SizedBox(width: 8),
//                 Text(
//                   'Pindai Ulang',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                 ),
//               ],
//             ),
//           ),
//         ),

//         const SizedBox(height: 12),

//         // Edit data button
//         SizedBox(
//           width: double.infinity,
//           height: 50,
//           child: OutlinedButton(
//             onPressed: () => _editData(context),
//             style: OutlinedButton.styleFrom(
//               foregroundColor: const Color(0xFF1565C0),
//               side: const BorderSide(color: Color(0xFF1565C0)),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: const Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.edit, size: 20),
//                 SizedBox(width: 8),
//                 Text(
//                   'Edit Data',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                 ),
//               ],
//             ),
//           ),
//         ),

//         const SizedBox(height: 12),

//         // Back to home button
//         SizedBox(
//           width: double.infinity,
//           height: 50,
//           child: TextButton(
//             onPressed: () => _backToHome(context),
//             style: TextButton.styleFrom(
//               foregroundColor: Colors.grey[600],
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: const Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.home, size: 20),
//                 SizedBox(width: 8),
//                 Text(
//                   'Kembali ke Beranda',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   void _copyToClipboard(String text) {
//     Clipboard.setData(ClipboardData(text: text));
//     // You would typically show a snackbar here
//   }

//   void _shareResult() {
//     // Implement sharing functionality
//     // final dataText = _formatDataForSharing();
//     // Clipboard.setData(ClipboardData(text: dataText));
//   }

//   void _scanAgain(BuildContext context) {
//     Navigator.of(context).pop(); // Back to camera
//   }

//   void _editData(BuildContext context) {
//     // Navigate to edit screen (not implemented in this example)
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Edit Data'),
//         content: const Text('Fitur edit data akan segera tersedia.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _backToHome(BuildContext context) {
//     Navigator.of(context).pushAndRemoveUntil(
//       MaterialPageRoute(builder: (_) => CameraOCRPage(ocrType: OcrType.ktp)),
//       (route) => false,
//     );
//   }
// }
