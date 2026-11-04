import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/detected_entity.dart';

/// Custom painter that draws bounding boxes around detected entities
class BoundingBoxPainter extends CustomPainter {
  /// List of detected entities to draw
  final List<DetectedEntity> entities;

  /// Scale factor for image coordinates
  final double imageScale;

  /// Creates a bounding box painter
  ///
  /// [entities] - List of detected entities with bounding boxes
  /// [imageScale] - Scale factor to convert image coordinates to canvas coordinates
  BoundingBoxPainter({
    required this.entities,
    required this.imageScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final entity in entities) {
      // Scale the bounding box coordinates
      final scaledBox = Rect.fromLTRB(
        entity.boundingBox.left * imageScale,
        entity.boundingBox.top * imageScale,
        entity.boundingBox.right * imageScale,
        entity.boundingBox.bottom * imageScale,
      );

      // Get the color for this entity type
      final color = entity.type.getColor();

      // Draw semi-transparent fill
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRect(scaledBox, fillPaint);

      // Draw border with full opacity
      final borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(scaledBox, borderPaint);

      // Draw label above the bounding box
      final labelPosition = Offset(scaledBox.left, scaledBox.top - 20);
      _drawLabel(
        canvas,
        entity.type.name,
        labelPosition,
        color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    // Repaint if entities change
    return oldDelegate.entities != entities ||
        oldDelegate.imageScale != imageScale;
  }

  /// Draws a label with text on the canvas
  ///
  /// [canvas] - The canvas to draw on
  /// [text] - The text to display in the label
  /// [position] - The position where the label should be drawn
  /// [color] - The background color of the label
  void _drawLabel(Canvas canvas, String text, Offset position, Color color) {
    // Create text painter
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    // Layout the text
    textPainter.layout();

    // Create label background rectangle with padding
    const padding = 4.0;
    final labelRect = Rect.fromLTWH(
      position.dx,
      position.dy,
      textPainter.width + padding * 2,
      textPainter.height + padding * 2,
    );

    // Draw label background
    final backgroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(labelRect, backgroundPaint);

    // Draw the text on top of the background
    textPainter.paint(
      canvas,
      Offset(position.dx + padding, position.dy + padding),
    );
  }
}
