import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/detected_entity.dart';

/// Screen that displays detection results with bounding boxes overlay
/// 
/// Shows the captured image with colored bounding boxes around detected entities.
/// Users can tap on boxes to see details and choose to retake or confirm.
class DetectionResultScreen extends StatefulWidget {
  /// The captured image file
  final File imageFile;

  /// List of entities detected in the image
  final List<DetectedEntity> detectedEntities;

  /// Callback when user wants to retake the photo
  final VoidCallback onRetake;

  /// Callback when user confirms the detection results
  final VoidCallback onConfirm;

  const DetectionResultScreen({
    Key? key,
    required this.imageFile,
    required this.detectedEntities,
    required this.onRetake,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<DetectionResultScreen> createState() => _DetectionResultScreenState();
}

class _DetectionResultScreenState extends State<DetectionResultScreen> {
  ui.Image? _image;
  Size? _imageSize;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  /// Load the image to get its actual dimensions for scaling calculations
  Future<void> _loadImage() async {
    final imageBytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    
    setState(() {
      _image = frame.image;
      _imageSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      _isLoadingImage = false;
    });
  }

  /// Show the legend dialog explaining color meanings
  void _showLegendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'Detection Legend',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem('Subjects', EntityType.SUBJECT),
            _buildLegendItem('Time', EntityType.TIME),
            _buildLegendItem('Instructor', EntityType.INSTRUCTOR),
            _buildLegendItem('Days', EntityType.DAY),
            _buildLegendItem('Room', EntityType.ROOM),
            _buildLegendItem('Units', EntityType.UNITS),
            _buildLegendItem('Headers', EntityType.HEADER),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a single legend item with colored icon and label
  Widget _buildLegendItem(String label, EntityType type) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: type.getColor(),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  /// Handle tap on the image to check if a bounding box was tapped
  void _handleTap(TapDownDetails details, Size displaySize) {
    if (_imageSize == null) return;

    // Calculate scale factors between display size and actual image size
    final scaleX = _imageSize!.width / displaySize.width;
    final scaleY = _imageSize!.height / displaySize.height;

    // Convert tap position to image coordinates
    final tapX = details.localPosition.dx * scaleX;
    final tapY = details.localPosition.dy * scaleY;
    final tapPoint = Offset(tapX, tapY);

    // Find which bounding box was tapped (if any)
    for (final entity in widget.detectedEntities) {
      if (entity.boundingBox.contains(tapPoint)) {
        _showEntityDetails(entity);
        return;
      }
    }
  }

  /// Show dialog with details of the tapped entity
  void _showEntityDetails(DetectedEntity entity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: entity.getColor(),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getEntityTypeName(entity.type),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detected Text:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entity.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Confidence: ${(entity.confidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Get human-readable name for entity type
  String _getEntityTypeName(EntityType type) {
    switch (type) {
      case EntityType.SUBJECT:
        return 'Subject';
      case EntityType.TIME:
        return 'Time';
      case EntityType.INSTRUCTOR:
        return 'Instructor';
      case EntityType.DAY:
        return 'Day';
      case EntityType.ROOM:
        return 'Room';
      case EntityType.UNITS:
        return 'Units';
      case EntityType.HEADER:
        return 'Header';
      case EntityType.UNKNOWN:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'Detection Result',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showLegendDialog,
            tooltip: 'Show legend',
          ),
        ],
      ),
      body: Column(
        children: [
          // Image with bounding boxes overlay
          Expanded(
            child: _isLoadingImage
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTapDown: (details) {
                          _handleTap(details, Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ));
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Base image
                            Image.file(
                              widget.imageFile,
                              fit: BoxFit.contain,
                            ),
                            // Bounding boxes overlay
                            if (_imageSize != null)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: BoundingBoxPainter(
                                    entities: widget.detectedEntities,
                                    imageSize: _imageSize!,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Bottom button bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1F3A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Retake button
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onRetake,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Retake',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Confirm button
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Looks Good',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to draw bounding boxes over the image
class BoundingBoxPainter extends CustomPainter {
  final List<DetectedEntity> entities;
  final Size imageSize;

  BoundingBoxPainter({
    required this.entities,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate scale factors between display size and actual image size
    // Using BoxFit.contain logic
    final double imageAspect = imageSize.width / imageSize.height;
    final double displayAspect = size.width / size.height;

    double scaleX, scaleY, offsetX = 0, offsetY = 0;

    if (imageAspect > displayAspect) {
      // Image is wider - fit to width
      scaleX = size.width / imageSize.width;
      scaleY = scaleX;
      offsetY = (size.height - (imageSize.height * scaleY)) / 2;
    } else {
      // Image is taller - fit to height
      scaleY = size.height / imageSize.height;
      scaleX = scaleY;
      offsetX = (size.width - (imageSize.width * scaleX)) / 2;
    }

    // Draw each bounding box
    for (final entity in entities) {
      final paint = Paint()
        ..color = entity.getColor()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      // Scale the bounding box from image coordinates to display coordinates
      final scaledRect = Rect.fromLTWH(
        entity.boundingBox.left * scaleX + offsetX,
        entity.boundingBox.top * scaleY + offsetY,
        entity.boundingBox.width * scaleX,
        entity.boundingBox.height * scaleY,
      );

      canvas.drawRect(scaledRect, paint);

      // Draw semi-transparent fill
      final fillPaint = Paint()
        ..color = entity.getColor().withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawRect(scaledRect, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.entities != entities || 
           oldDelegate.imageSize != imageSize;
  }
}
