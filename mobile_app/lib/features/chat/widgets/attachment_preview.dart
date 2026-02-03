import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../../../core/theme/app_theme.dart';

class AttachmentPreview extends StatelessWidget {
  final MessageAttachment attachment;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool showRemoveButton;

  const AttachmentPreview({
    super.key,
    required this.attachment,
    this.onTap,
    this.onRemove,
    this.showRemoveButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: _buildAttachmentContent(),
            ),
          ),
          if (showRemoveButton && onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentContent() {
    switch (attachment.type) {
      case 'image':
        return _buildImagePreview();
      case 'document':
        return _buildDocumentPreview();
      case 'audio':
        return _buildAudioPreview();
      case 'video':
        return _buildVideoPreview();
      default:
        return _buildGenericPreview();
    }
  }

  Widget _buildImagePreview() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            image: attachment.url != null
                ? DecorationImage(
                    image: NetworkImage(attachment.url!),
                    fit: BoxFit.cover,
                  )
                : null,
            color: Colors.grey[200],
          ),
          child: attachment.url == null
              ? const Icon(Icons.image, color: Colors.grey)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          attachment.name,
          style: const TextStyle(fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDocumentPreview() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: AppTheme.primaryColor.withOpacity(0.1),
          ),
          child: Icon(
            _getDocumentIcon(),
            color: AppTheme.primaryColor,
            size: 30,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          attachment.name,
          style: const TextStyle(fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAudioPreview() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.orange.withOpacity(0.1),
          ),
          child: const Icon(
            Icons.audiotrack,
            color: Colors.orange,
            size: 30,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          attachment.name,
          style: const TextStyle(fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.red.withOpacity(0.1),
          ),
          child: const Icon(
            Icons.videocam,
            color: Colors.red,
            size: 30,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          attachment.name,
          style: const TextStyle(fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildGenericPreview() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey.withOpacity(0.1),
          ),
          child: const Icon(
            Icons.attach_file,
            color: Colors.grey,
            size: 30,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          attachment.name,
          style: const TextStyle(fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  IconData _getDocumentIcon() {
    final extension = attachment.name.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
}