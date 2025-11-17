// import 'dart:io';

// import 'package:adaptive_dialog/adaptive_dialog.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:camera/camera.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:go_router/go_router.dart';
// import 'package:porto_crm_app/src/constants/constants.dart';

// import '../../../../components/safe_area_bottom_nav.dart';
// import '../../../../core/cores.dart';
// import '../blocs/ocr_camera_bloc/ocr_camera_bloc.dart';
// import '../blocs/ocr_bloc/ocr_bloc.dart';
// import '../widgets/ktp_camera_overlay.dart';
// import '../widgets/ktp_controls_button_widget.dart';

// class CameraOCRPage extends StatelessWidget {
//   const CameraOCRPage({super.key, required this.ocrType});

//   final OcrType ocrType;

//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider<OcrCameraBloc>(create: (context) => OcrCameraBloc()),
//         BlocProvider<OcrBloc>(
//           create: (context) =>
//               OcrBloc(processOcrKtp: injector(), processOcrNpwp: injector()),
//         ),
//       ],
//       child: CameraOCRPageView(ocrType: ocrType),
//     );
//   }
// }

// class CameraOCRPageView extends StatefulWidget {
//   const CameraOCRPageView({super.key, required this.ocrType});

//   final OcrType ocrType;

//   @override
//   State<CameraOCRPageView> createState() => _CameraOCRPageViewState();
// }

// class _CameraOCRPageViewState extends State<CameraOCRPageView>
//     with TickerProviderStateMixin, WidgetsBindingObserver {
//   late AnimationController _pulseController;
//   late AnimationController _slideController;
//   late Animation<double> _pulseAnimation;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     // Initialize animations
//     _pulseController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat();

//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     )..repeat(reverse: true);

//     _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );

//     _slideAnimation =
//         Tween<Offset>(
//           begin: const Offset(-0.5, 0),
//           end: const Offset(0.5, 0),
//         ).animate(
//           CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
//         );

//     context.read<OcrCameraBloc>().add(const InitializeCamera());
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _pulseController.dispose();
//     _slideController.dispose();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     final cameraBloc = context.read<OcrCameraBloc>();

//     if (state == AppLifecycleState.inactive ||
//         state == AppLifecycleState.paused) {
//       cameraBloc.add(const StopCameraPreview());
//     } else if (state == AppLifecycleState.resumed) {
//       cameraBloc.add(const InitializeCamera());
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: BlocListener<OcrCameraBloc, OcrCameraState>(
//         listener: (context, state) {
//           if (state is CameraError) {
//             Fluttertoast.showToast(
//               msg: 'Error Kamera: ${state.message}',
//               toastLength: Toast.LENGTH_LONG,
//               gravity: ToastGravity.CENTER,
//               backgroundColor: Colors.red,
//               textColor: Colors.white,
//             );
//           } else if (state is CameraCaptured) {
//             if (widget.ocrType == OcrType.ktp) {
//               context.read<OcrBloc>().add(
//                 ProcessKTP(imagePath: state.imagePath),
//               );
//             } else if (widget.ocrType == OcrType.npwp) {
//               context.read<OcrBloc>().add(
//                 ProcessNPWP(imagePath: state.imagePath),
//               );
//             }
//           }
//         },
//         child: BlocListener<OcrBloc, OcrState>(
//           listener: (context, state) {
//             if (state is OCRKTPSuccess) {
//               context.pop({
//                 'status': 'OCR_KTP_SUCCESS',
//                 'imagePath': state.imagePath,
//                 'resultData': state.result.data.toJson(),
//                 'imagePathCropped': state.result.imagePathCropped ?? '',
//                 'imagePathCroppedGrayscale':
//                     state.result.imagePathCroppedGrayScale ?? '',
//                 'timestamp': DateTime.now().millisecondsSinceEpoch,
//               });

//               //! Navigate forward to temporary result page (for testing)
//               // context.pushReplacement(
//               //   ocrKtpTemporaryResultRoute,
//               //   extra: {
//               //     'imagePath': state.imagePath,
//               //     'result': state.result,
//               //     'imagePathCropped': state.imagePathCropped,
//               //     'imagePathCroppedGrayscale':
//               //         state.result.imagePathCroppedGrayScale,
//               //   },
//               // );
//             } else if (state is OCRNPWPSuccess) {
//               context.pop({
//                 'status': 'OCR_NPWP_SUCCESS',
//                 'imagePath': state.imagePath,
//                 'resultData': state.result.data.toJson(),
//                 'imagePathCropped': state.result.imagePathCropped ?? '',
//                 'imagePathCroppedGrayscale':
//                     state.result.imagePathCroppedGrayScale ?? '',
//                 'timestamp': DateTime.now().millisecondsSinceEpoch,
//               });

//               //! Navigate forward to temporary result page (for testing)
//               // context.pushReplacement(
//               //   ocrNpwpTemporaryResultRoute,
//               //   extra: {
//               //     'imagePath': state.imagePath,
//               //     'result': state.result,
//               //     'imagePathCropped': state.imagePathCropped,
//               //     'imagePathCroppedGrayscale':
//               //         state.result.imagePathCroppedGrayScale,
//               //   },
//               // );
//             } else if (state is OCRError) {
//               showOkAlertDialog(
//                 context: context,
//                 title: 'Error OCR',
//                 message: state.message,
//                 okLabel: 'Tutup',
//               );

//               Fluttertoast.showToast(
//                 msg: 'Error: ${state.message}',
//                 toastLength: Toast.LENGTH_LONG,
//                 gravity: ToastGravity.TOP,
//                 backgroundColor: Colors.red,
//                 textColor: Colors.white,
//               );

//               context.read<OcrCameraBloc>().add(const StartCameraPreview());
//             }
//           },
//           child: BlocBuilder<OcrCameraBloc, OcrCameraState>(
//             builder: (context, cameraState) {
//               return BlocBuilder<OcrBloc, OcrState>(
//                 builder: (context, ocrState) {
//                   return Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       // Camera Preview
//                       _buildCameraPreview(cameraState),

//                       // Camera Overlay with KTP guidance
//                       if (cameraState is CameraReady ||
//                           cameraState is CameraPicturePreview)
//                         KtpCameraOverlayWidget(
//                           pulseAnimation: _pulseAnimation,
//                           slideAnimation: _slideAnimation,
//                           cameraState: cameraState,
//                         ),

//                       // Warning Message
//                       if (cameraState is CameraWarning)
//                         Positioned(
//                           top: MediaQuery.of(context).padding.top + 20,
//                           left: 20,
//                           right: 20,
//                           child: Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.orange.withValues(alpha: 0.9),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Row(
//                               children: [
//                                 const Icon(Icons.warning, color: Colors.white),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     cameraState.message,
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),

//                       // Control Buttons
//                       if (cameraState is CameraReady)
//                         Positioned(
//                           top: MediaQuery.of(context).padding.top + 20,
//                           right: 20,
//                           child: KtpControlsButtonWidget(
//                             isFlashOn: cameraState.isFlashOn,
//                             canSwitchCamera: false,
//                             onFlashToggle: () {
//                               context.read<OcrCameraBloc>().add(
//                                 const ToggleFlash(),
//                               );
//                             },
//                             onCameraSwitch: () {
//                               context.read<OcrCameraBloc>().add(
//                                 const SwitchCamera(),
//                               );
//                             },
//                           ),
//                         ),

//                       if (cameraState is CameraReady ||
//                           cameraState is CameraPicturePreview)
//                         Positioned(
//                           top: MediaQuery.of(context).padding.top + 2,
//                           child: Container(
//                             width: MediaQuery.sizeOf(context).width * 0.55,
//                             padding: const EdgeInsets.symmetric(
//                               vertical: 10,
//                               horizontal: 8,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withValues(alpha: 0.7),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text(
//                                   'Posisikan ${widget.ocrType == OcrType.ktp ? "KTP" : "NPWP"} dalam bingkai dengan posisi landscape',
//                                   textAlign: TextAlign.center,
//                                   style: TextStyle(
//                                     color: Colors.black,
//                                     fontSize: 11,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   'Pastikan seluruh teks terlihat dengan jelas.',
//                                   textAlign: TextAlign.center,
//                                   style: TextStyle(
//                                     color: Colors.black.withValues(alpha: 0.8),
//                                     fontSize: 10,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),

//                       // Loading Overlay for OCR Processing
//                       if (ocrState is OCRProcessing)
//                         _buildProcessingOverlay(ocrState),

//                       if (cameraState is CameraCapturing)
//                         _buildCapturingOverlay(cameraState),

//                       // Capture Button and Instructions
//                       Positioned(
//                         bottom: 0,
//                         left: 0,
//                         right: 0,
//                         child: _buildBottomControls(cameraState, ocrState),
//                       ),

//                       // Back Button
//                       if (cameraState is CameraReady ||
//                           cameraState is CameraPicturePreview ||
//                           cameraState is CameraError ||
//                           cameraState is CameraInitializing)
//                         Positioned(
//                           top: MediaQuery.of(context).padding.top + 20,
//                           left: 20,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: Colors.black.withValues(alpha: 0.5),
//                               borderRadius: BorderRadius.circular(25),
//                             ),
//                             child: IconButton(
//                               onPressed: () => Navigator.of(context).pop(),
//                               icon: const Icon(
//                                 Icons.arrow_back,
//                                 color: Colors.white,
//                                 size: 24,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCameraPreview(OcrCameraState state) {
//     if (state is CameraPicturePreview) {
//       return SizedBox.expand(
//         child: Image.file(File(state.imagePath), fit: BoxFit.cover),
//       );
//     } else if (state is CameraReady) {
//       return SizedBox.expand(
//         child: FittedBox(
//           fit: BoxFit.cover,
//           child: SizedBox(
//             width: state.controller.value.previewSize!.height,
//             height: state.controller.value.previewSize!.width,
//             child: CameraPreview(state.controller),
//           ),
//         ),
//       );
//     } else if (state is CameraInitializing) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(color: Colors.white),
//             SizedBox(height: 16),
//             Text(
//               'Menginisialisasi kamera...',
//               style: TextStyle(color: Colors.white),
//             ),
//           ],
//         ),
//       );
//     } else if (state is CameraError) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, color: Colors.red, size: 64),
//             const SizedBox(height: 16),
//             Text(
//               'Error Kamera',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               state.message,
//               textAlign: TextAlign.center,
//               style: const TextStyle(color: Colors.white70),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: () {
//                 context.read<OcrCameraBloc>().add(const InitializeCamera());
//               },
//               child: const Text('Coba Lagi'),
//             ),
//           ],
//         ),
//       );
//     }

//     return Container(color: Colors.black);
//   }

//   Widget _buildCapturingOverlay(CameraCapturing state) {
//     return Container(
//       color: Colors.black.withValues(alpha: 0.8),
//       child: Center(
//         child: Container(
//           margin: const EdgeInsets.all(32),
//           padding: const EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // const CircularProgressIndicator(),
//               // const SizedBox(height: 20),
//               Text(
//                 'Memproses...',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16),
//               LinearProgressIndicator(
//                 value: 0.15,
//                 backgroundColor: Colors.grey[300],
//                 valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 '15%',
//                 style: const TextStyle(fontSize: 14, color: Colors.grey),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildProcessingOverlay(OCRProcessing state) {
//     return Container(
//       color: Colors.black.withValues(alpha: 0.8),
//       child: Center(
//         child: Container(
//           margin: const EdgeInsets.all(32),
//           padding: const EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // const CircularProgressIndicator(),
//               // const SizedBox(height: 20),
//               Text(
//                 state.status ?? 'Memproses...',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               if (state.progress != null) ...[
//                 const SizedBox(height: 16),
//                 LinearProgressIndicator(
//                   value: state.progress,
//                   backgroundColor: Colors.grey[300],
//                   valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   '${(state.progress! * 100).round()}%',
//                   style: const TextStyle(fontSize: 14, color: Colors.grey),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBottomControls(OcrCameraState cameraState, OcrState ocrState) {
//     return SafeAreaBottomNav(
//       child: Container(
//         padding: EdgeInsets.only(bottom: 35.h, top: 12.h),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (cameraState is CameraPicturePreview)
//               Row(
//                 children: [
//                   GestureDetector(
//                     onTap: () {
//                       context.read<OcrCameraBloc>().add(RetakePicture());
//                     },
//                     child: Container(
//                       width: 60,
//                       height: 60,
//                       decoration: BoxDecoration(
//                         color: Colors.white.withValues(alpha: 0.3),
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Colors.white, width: 2),
//                       ),
//                       child: const Icon(
//                         Icons.refresh,
//                         color: Colors.white,
//                         size: 32,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 80),
//                   GestureDetector(
//                     onTap: () {
//                       context.read<OcrCameraBloc>().add(
//                         AcceptPicture(imagePath: cameraState.imagePath),
//                       );
//                     },
//                     child: Container(
//                       width: 60,
//                       height: 60,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Colors.white, width: 2),
//                       ),
//                       child: const Icon(
//                         Icons.check,
//                         color: Colors.black,
//                         size: 32,
//                       ),
//                     ),
//                   ),
//                 ],
//               )
//             else if (cameraState is CameraReady && ocrState is! OCRProcessing)
//               GestureDetector(
//                 onTap: () {
//                   HapticFeedback.mediumImpact();
//                   context.read<OcrCameraBloc>().add(const TakePicture());
//                 },
//                 child: AnimatedBuilder(
//                   animation: _pulseAnimation,
//                   builder: (context, child) {
//                     return Transform.scale(
//                       scale: _pulseAnimation.value,
//                       child: Container(
//                         width: 80,
//                         height: 80,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           shape: BoxShape.circle,
//                           border: Border.all(color: Colors.white, width: 4),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.white.withValues(alpha: 0.3),
//                               blurRadius: 20,
//                               spreadRadius: 5,
//                             ),
//                           ],
//                         ),
//                         child: const Icon(
//                           Icons.camera_alt,
//                           color: Colors.black,
//                           size: 32,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
