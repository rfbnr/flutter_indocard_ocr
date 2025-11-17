import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KtpControlsButtonWidget extends StatelessWidget {
  final bool isFlashOn;
  final bool canSwitchCamera;
  final VoidCallback onFlashToggle;
  final VoidCallback onCameraSwitch;

  const KtpControlsButtonWidget({
    super.key,
    required this.isFlashOn,
    required this.canSwitchCamera,
    required this.onFlashToggle,
    required this.onCameraSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Flash toggle button
        _buildControlButton(
          icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
          isActive: isFlashOn,
          onTap: () {
            HapticFeedback.lightImpact();
            onFlashToggle();
          },
          tooltip: isFlashOn ? 'Matikan Flash' : 'Nyalakan Flash',
        ),

        if (canSwitchCamera) ...[
          const SizedBox(height: 12),
          // Camera switch button
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            isActive: false,
            onTap: () {
              HapticFeedback.lightImpact();
              onCameraSwitch();
            },
            tooltip: 'Ganti Kamera',
          ),
        ],
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? Colors.blue.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.black87 : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
