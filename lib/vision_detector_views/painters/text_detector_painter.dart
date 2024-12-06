import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:id_check/vision_detector_views/utils.dart';

import 'coordinates_translator.dart';

class TextRecognizerPainter extends CustomPainter {
  TextRecognizerPainter(
      this.recognizedText,
      this.imageSize,
      this.rotation,
      this.cameraLensDirection,
      );

  final RecognizedText recognizedText;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  List<String> dates = [];

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.lightGreenAccent;

    String surname = '';
    String givenName = '';
    String idType = '';
    bool isExpired = false;

    for (final textBlock in recognizedText.blocks) {
      final left = translateX(
        textBlock.boundingBox.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = translateY(
        textBlock.boundingBox.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = translateX(
        textBlock.boundingBox.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final bottom = translateY(
        textBlock.boundingBox.bottom,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );

      idType = predictIDType(textBlock.text)[0];
      if(isADate(textBlock.text)) {
        dates.add(textBlock.text);
      }

      if(getFullName(textBlock.text)[0].isNotEmpty && getFullName(textBlock.text)[1].isNotEmpty) {
        surname = getFullName(textBlock.text)[0];
        givenName = getFullName(textBlock.text)[1];
      }

      // Draw rectangle around the text block
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint,
      );
    }

    // Draw the surname and given name at the top left corner
    final firstNameTextPainter = TextPainter(
      text: TextSpan(
        text: "First Name: $surname",
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    );
    firstNameTextPainter.layout();
    firstNameTextPainter.paint(canvas, const Offset(20, 20));


    final lastNameTextPainter = TextPainter(
      text: TextSpan(
        text: "Last Name: $givenName",
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    );
    lastNameTextPainter.layout();
    lastNameTextPainter.paint(canvas, const Offset(20, 40));

    final idTypeTextPainter = TextPainter(
      text: TextSpan(
        text: "ID Type: $idType",
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    );
    idTypeTextPainter.layout();
    idTypeTextPainter.paint(canvas, Offset(size.width - idTypeTextPainter.width - 20, 20));

    if(dates.isNotEmpty) {
      isExpired = _isDateExpired(dates.last);
    }

    final idExpirationTextPainter = TextPainter(
      text: TextSpan(
        text: "Expired: $isExpired",
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    );
    idExpirationTextPainter.layout();
    idExpirationTextPainter.paint(canvas, Offset(size.width - idExpirationTextPainter.width - 20, 40));
  }

  bool _isDateExpired(String expiryDate) {
    final now = DateTime.now();

    // Parse the date string in dd-mm-yyyy format
    final parts = expiryDate.split('-');
    if (parts.length != 3) {
      return false; // Invalid date format
    }
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return false; // Invalid date format
    }

    final inputDate = DateTime(year, month, day);
    return inputDate.isBefore(now);
  }

  @override
  bool shouldRepaint(TextRecognizerPainter oldDelegate) {
    return oldDelegate.recognizedText != recognizedText;
  }
}


