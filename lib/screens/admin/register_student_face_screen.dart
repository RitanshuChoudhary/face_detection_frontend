import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/admin_provider.dart';
import '../../services/image_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';

class RegisterStudentFaceScreen extends StatefulWidget {
  final dynamic student;

  const RegisterStudentFaceScreen({super.key, required this.student});

  @override
  State<RegisterStudentFaceScreen> createState() => _RegisterStudentFaceScreenState();
}

class _RegisterStudentFaceScreenState extends State<RegisterStudentFaceScreen> {
  final ImageService _imageService = ImageService();
  
  // Holds the captured image files
  File? _centerFace;
  File? _leftProfile;
  File? _rightProfile;

  Future<void> _captureImage(int slot) async {
    // Show capture options dialog
    final File? picked = await showDialog<File>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Capture Face Image', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Select a media source to pick the facial photo.'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.photo_library_outlined, color: AppConstants.primary),
              label: const Text('Gallery'),
              onPressed: () async {
                final file = await _imageService.selectFromGallery();
                if (mounted) Navigator.pop(context, file);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text('Camera'),
              onPressed: () async {
                final file = await _imageService.captureFromCamera();
                if (mounted) Navigator.pop(context, file);
              },
            ),
          ],
        );
      }
    );

    if (picked == null) return;

    setState(() {
      if (slot == 1) {
        _centerFace = picked;
      } else if (slot == 2) {
        _leftProfile = picked;
      } else if (slot == 3) {
        _rightProfile = picked;
      }
    });
  }

  Future<void> _uploadAndTrainFaces() async {
    if (_centerFace == null || _leftProfile == null || _rightProfile == null) return;

    final adminProv = Provider.of<AdminProvider>(context, listen: false);
    final files = [_centerFace!, _leftProfile!, _rightProfile!];

    final ok = await adminProv.registerStudentFaces(widget.student.id, files);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Face registration & model training successful!'),
            ],
          ),
          backgroundColor: AppConstants.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(adminProv.errorMessage ?? 'Upload failed')),
            ],
          ),
          backgroundColor: AppConstants.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminProv = Provider.of<AdminProvider>(context);

    final bool isReady = _centerFace != null && _leftProfile != null && _rightProfile != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Face Registration')),
      body: LoadingOverlay(
        isLoading: adminProv.isLoading,
        message: 'Uploading 3-Part Image stream to Cloud and Training AI Model (InsightFace)...\nThis may take 10-15 seconds.',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions Card
              Container(
                padding: const EdgeInsets.all(AppConstants.padding),
                decoration: BoxDecoration(
                  color: AppConstants.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  border: Border.all(color: AppConstants.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.tips_and_updates_outlined, color: AppConstants.primary),
                        SizedBox(width: 10),
                        Text('Optimal Training Criteria', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• Ensure high brightness / direct lighting.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const Text('• Capture clear, straight portraits (no sunglasses/masks).', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const Text('• Complete all 3 facial aspect angles requested below.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Text('Capturing Faces: ${widget.student.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // 3 Capture Slots Display Rows
              _buildCaptureSlot(1, 'Center Facial View', _centerFace),
              const SizedBox(height: 16),
              _buildCaptureSlot(2, 'Left Profile View', _leftProfile),
              const SizedBox(height: 16),
              _buildCaptureSlot(3, 'Right Profile View', _rightProfile),
              
              const SizedBox(height: 48),

              CustomButton(
                text: 'Register Face Template',
                onPressed: _uploadAndTrainFaces,
                isLoading: adminProv.isLoading,
                color: isReady ? AppConstants.primary : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureSlot(int slot, String label, File? image) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.cardColorDark : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: image != null ? AppConstants.success.withOpacity(0.4) : AppConstants.textMuted.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Thumb/Icon Box
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: image != null ? Colors.transparent : AppConstants.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              image: image != null ? DecorationImage(image: FileImage(image), fit: BoxFit.cover) : null,
            ),
            child: image == null
                ? const Icon(Icons.portrait_outlined, color: AppConstants.primary, size: 32)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  image != null ? 'Captured Successfully' : 'Pending Capture',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: image != null ? AppConstants.success : AppConstants.textMuted,
                  ),
                ),
              ],
            ),
          ),
          
          // Action button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: image != null ? AppConstants.success : AppConstants.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _captureImage(slot),
            child: Icon(image != null ? Icons.check : Icons.camera_alt, size: 20),
          ),
        ],
      ),
    );
  }
}
