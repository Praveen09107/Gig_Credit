import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../../core/enums/app_enums.dart';
import '../cards/app_card.dart';
import 'upload_card_shimmer.dart';
import 'extracted_data_chip.dart';
import '../../../services/ocr_service.dart';


class DocumentUploadCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String docType;
  final OcrService ocrService;
  final ValueChanged<Map<String, dynamic>> onExtracted;
  final bool isRequired;
  final bool useCamera;

  const DocumentUploadCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.docType,
    required this.ocrService,
    required this.onExtracted,
    this.isRequired = true,
    this.useCamera = false,
  });

  @override
  State<DocumentUploadCard> createState() => _DocumentUploadCardState();
}

class _DocumentUploadCardState extends State<DocumentUploadCard> {
  UploadCardState _state = UploadCardState.empty;
  Map<String, dynamic>? _extractedData;

  Future<void> _pickAndProcessImage() async {
    String? pickedPath;

    if (widget.useCamera) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      pickedPath = pickedFile?.path;
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'webp'],
      );
      pickedPath = result?.files.single.path;
    }

    if (pickedPath != null) {
      // File validation — check format
      final ext = pickedPath.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'pdf', 'webp'].contains(ext)) {
        setState(() => _state = UploadCardState.uploadError);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _state = UploadCardState.empty);
        });
        return;
      }

      setState(() {
        _state = UploadCardState.processing;
      });

      // Added realistic delay per user request
      await Future.delayed(const Duration(seconds: 3));

      try {
        final data = await widget.ocrService.extractDataFromImage(pickedPath, widget.docType);
        final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
        
        if (confidence >= 0.70) {
          // High confidence: show extracted data
          setState(() {
            _extractedData = data;
            _state = UploadCardState.extracted;
          });
        } else {
          // Low confidence: fallback to manual entry
          setState(() {
            _extractedData = data;
            _state = UploadCardState.fallback;
          });
        }
        
        widget.onExtracted(data);
      } catch (e) {
        // Strict OCR error: Display the error and prevent extraction
        String errorMessage = 'Failed to extract data. Please try again.';
        if (e is Exception) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        }

        setState(() {
          _state = UploadCardState.uploadError;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );

        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _state = UploadCardState.empty);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: _state == UploadCardState.processing ? null : _pickAndProcessImage,
      hasGradientBorder: _state == UploadCardState.extracted,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // State: UPLOAD_ERROR — invalid file format/size
    if (_state == UploadCardState.uploadError) {
      return SizedBox(
        height: 60,
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline, color: AppColors.error),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Upload failed. Please try a valid image file.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    if (_state == UploadCardState.processing) {
      return const SizedBox(
        height: 60,
        child: UploadCardShimmer(),
      );
    }

    final bool isSuccess = _state == UploadCardState.extracted;
    final bool isFallback = _state == UploadCardState.fallback;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSuccess ? AppColors.verifiedLight.withValues(alpha: 0.2) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: isFallback ? Border.all(color: AppColors.errorLight) : null,
          ),
          child: Icon(
            isSuccess 
              ? Icons.check_circle_rounded 
              : (widget.useCamera ? Icons.camera_alt_rounded : Icons.upload_file_rounded),
            color: isSuccess ? AppColors.verified : AppColors.accent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.labelLarge,
                    ),
                  ),
                  if (widget.isRequired && !isSuccess)
                    Text(
                      '*',
                      style: AppTypography.labelLarge.copyWith(color: AppColors.error),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                isSuccess ? 'Document Verified' : (isFallback ? 'Manual text entry required' : widget.subtitle),
                style: AppTypography.bodySmall.copyWith(
                  color: isFallback ? AppColors.error : AppColors.textSecondary,
                ),
              ),
              if (isSuccess && _extractedData != null)
                ExtractedDataChip(data: _extractedData!),
            ],
          ),
        ),
      ],
    );
  }
}
