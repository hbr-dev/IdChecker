// TODO Implement this library.
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'coordinates_translator.dart';

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(
      this.faces,
      this.imageSize,
      this.rotation,
      this.cameraLensDirection
      );

  final List<Face> faces;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final int blinkHistorySize = 5;

  List<bool> referentialBlinkPattern = List.generate(5, (index) => index % 2 == 0);
  var extractedFeatures = [];
  var aliveProbabilities = [];
  List<bool> blinkHistory = [];

  double faceMatchingScore = 0.0;



  Map<String, dynamic> extractFeatures(Face face) {
    final landmarks = face.landmarks;
    if (landmarks == null) return {};

    // Extract landmark positions
    num leftEyeX = landmarks[FaceLandmarkType.leftEye]?.position.x ?? 0;
    num leftEyeY = landmarks[FaceLandmarkType.leftEye]?.position.y ?? 0;
    num rightEyeX = landmarks[FaceLandmarkType.rightEye]?.position.x ?? 0;
    num rightEyeY = landmarks[FaceLandmarkType.rightEye]?.position.y ?? 0;
    num noseX = landmarks[FaceLandmarkType.noseBase]?.position.x ?? 0;
    num noseY = landmarks[FaceLandmarkType.noseBase]?.position.y ?? 0;
    num mouthLeftX = landmarks[FaceLandmarkType.leftMouth]?.position.x ?? 0;
    num mouthLeftY = landmarks[FaceLandmarkType.leftMouth]?.position.y ?? 0;
    num mouthRightX = landmarks[FaceLandmarkType.rightMouth]?.position.x ?? 0;
    num mouthRightY = landmarks[FaceLandmarkType.rightMouth]?.position.y ?? 0;

    // Calculate distances
    double eyeDistance = sqrt(pow(rightEyeX - leftEyeX, 2) + pow(rightEyeY - leftEyeY, 2));
    double noseToLeftEyeDistance = sqrt(pow(noseX - leftEyeX, 2) + pow(noseY - leftEyeY, 2));
    double noseToRightEyeDistance = sqrt(pow(noseX - rightEyeX, 2) + pow(noseY - rightEyeY, 2));
    double mouthWidth = sqrt(pow(mouthRightX - mouthLeftX, 2) + pow(mouthRightY - mouthLeftY, 2));

    // Calculate ratios
    double eyeNoseRatio = noseToLeftEyeDistance / eyeDistance;
    double mouthEyeRatio = mouthWidth / eyeDistance;

    return {
      'eyeDistance': eyeDistance,
      'noseToLeftEyeDistance': noseToLeftEyeDistance,
      'noseToRightEyeDistance': noseToRightEyeDistance,
      'mouthWidth': mouthWidth,
      'eyeNoseRatio': eyeNoseRatio,
      'mouthEyeRatio': mouthEyeRatio,
    };
  }



  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.red;
    final Paint paint2 = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0
      ..color = Colors.green;

    for (final Face face in faces) {
      final left = translateX(
        face.boundingBox.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = translateY(
        face.boundingBox.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = translateX(
        face.boundingBox.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final bottom = translateY(
        face.boundingBox.bottom,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );

      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint1,
      );

      void paintContour(FaceContourType type) {
        final contour = face.contours[type];
        if (contour?.points != null) {
          for (final Point point in contour!.points) {
            canvas.drawCircle(
                Offset(
                  translateX(
                    point.x.toDouble(),
                    size,
                    imageSize,
                    rotation,
                    cameraLensDirection,
                  ),
                  translateY(
                    point.y.toDouble(),
                    size,
                    imageSize,
                    rotation,
                    cameraLensDirection,
                  ),
                ),
                1,
                paint1);
          }
        }
      }

      void paintLandmark(FaceLandmarkType type) {
        final landmark = face.landmarks[type];
        if (landmark?.position != null) {
          canvas.drawCircle(
              Offset(
                translateX(
                  landmark!.position.x.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
                translateY(
                  landmark.position.y.toDouble(),
                  size,
                  imageSize,
                  rotation,
                  cameraLensDirection,
                ),
              ),
              2,
              paint2);
        }
      }

      for (final type in FaceContourType.values) {
        paintContour(type);
      }

      for (final type in FaceLandmarkType.values) {
        paintLandmark(type);
      }
      extractedFeatures.add(extractFeatures(face));
      aliveProbabilities.add(calculateAliveProbability(face));
    }

    if(extractedFeatures.length >= 2) {
      faceMatchingScore = calculateSimilarity(extractedFeatures[0], extractedFeatures[1]);
    }

    // Display similarity score
    final scoreMatchingTextPainter = TextPainter(
      text: TextSpan(
        text: 'Matching Score: ${faceMatchingScore.toStringAsFixed(2)}%',
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    scoreMatchingTextPainter.layout();
    scoreMatchingTextPainter.paint(canvas, const Offset(20, 20));

    // Calculate the highest alive probability
    var realPersonProb = aliveProbabilities.isNotEmpty ? aliveProbabilities.reduce((a, b) => a > b ? a : b):0;

    final aliveProbabilityTextPainter = TextPainter(
      text: TextSpan(
        text: 'Real Person: ${realPersonProb.toStringAsFixed(2)}%',
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    aliveProbabilityTextPainter.layout();
    aliveProbabilityTextPainter.paint(canvas, const Offset(20, 40));
  }



  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.faces != faces;
  }



  double calculateSimilarity(Map<String, dynamic> features1, Map<String, dynamic> features2) {
    double totalDifference = 0.0;
    double totalWeight = 0.0;

    // Define weights for each feature (adjust these based on importance)
    Map<String, double> weights = {
      'eyeDistance': 2.0, // More weight on eye distance
      'noseToLeftEyeDistance': 1.5,
      'noseToRightEyeDistance': 1.5,
      'mouthWidth': 1.0,
      'eyeNoseRatio': 2.0,
      'mouthEyeRatio': 1.0,
    };

    for (String feature in weights.keys) {
      if (features1.containsKey(feature) && features2.containsKey(feature)) {
        double difference = (features1[feature]! - features2[feature]!).abs();
        totalDifference += difference * weights[feature]!;
        totalWeight += weights[feature]!;
      }
    }

    double maxPossibleDifference = 0.0;
    for (double weight in weights.values) {
      maxPossibleDifference += weight * 100; // Assuming each feature can differ by a maximum of 100
    }

    double score = 100 - (totalDifference / maxPossibleDifference * 100); // Invert the score
    return score.clamp(0, 100); // Ensure score is between 0 and 100
  }



  double calculateAliveProbability(Face face) {
    final landmarks = face.landmarks;
    if (landmarks == null) return 0.0;

    num leftMouthY = landmarks[FaceLandmarkType.leftMouth]?.position.y ?? 0;
    num rightMouthY = landmarks[FaceLandmarkType.rightMouth]?.position.y ?? 0;
    num leftEyeY = landmarks[FaceLandmarkType.leftEye]?.position.y ?? 0;
    num rightEyeY = landmarks[FaceLandmarkType.rightEye]?.position.y ?? 0;
    num leftEyeX = landmarks[FaceLandmarkType.leftEye]?.position.x ?? 0;
    num rightEyeX = landmarks[FaceLandmarkType.rightEye]?.position.x ?? 0;

    // Calculate distances
    num mouthHeight = (rightMouthY - leftMouthY).abs();
    num eyeHeight = (rightEyeY - leftEyeY).abs();
    num eyeDistance = (rightEyeX - leftEyeX).abs();

    // Determine alive probability based on facial expression
    double expressionProbability;
    if (mouthHeight > eyeHeight * 0.5) {
      expressionProbability = 100.0; // Smiling or showing a strong expression
    } else if (mouthHeight > eyeHeight * 0.25) {
      expressionProbability = 75.0; // Neutral or slight smile
    } else {
      expressionProbability = 25.0; // Frowning or neutral expression
    }

    // Determine if eyes are blinking
    bool isBlinking = eyeHeight < 18; // Threshold for detecting a blink (adjust as necessary)
    blinkHistory.add(isBlinking);
    if (blinkHistory.length > blinkHistorySize) {
      blinkHistory.removeAt(0); // Maintain the size of the history
    }

    // Compare current blinking status with the referential pattern
    double blinkProbability = compareBlinkPatterns(blinkHistory, referentialBlinkPattern);

    // Combine expression and blink probabilities
    double combinedProbability = (expressionProbability + blinkProbability * 2) / 3;

    return combinedProbability.clamp(0, 100); // Ensure the probability is between 0 and 100
  }

  double compareBlinkPatterns(List<bool> currentPattern, List<bool> referencePattern) {
    if (currentPattern.length < referencePattern.length) {
      return 0.0; // Not enough data to compare
    }
    // Compare the last N frames of blinking status
    int matches = 0;
    for (int i = 0; i < referencePattern.length; i++) {
      if (currentPattern[i] == referencePattern[i]) {
        matches++;
      }
    }
    // Calculate blink probability based on matches
    return (matches / referencePattern.length) * 100; // Return percentage of matches
  }


}