
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart';
import 'package:sensors_plus/sensors_plus.dart';

class DRA{

}


class Mytest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyDeadReckoningApp(),
    );
  }
}

class MyDeadReckoningApp extends StatefulWidget {
  @override
  _MyDeadReckoningAppState createState() => _MyDeadReckoningAppState();
}


class _MyDeadReckoningAppState extends State<MyDeadReckoningApp> {
  double position = 0.0;
  double orientation = 0.0;
  double stepLength = 0.7;
  double calibrationOffset = 0.0;
  int stepCount = 0;

  Matrix2 rotationMatrix = Matrix2.identity();

  int lastTime = 0;
  double deltaTime = 0.0;
  double lastAcceleration = 0.0;
  double accelerationThreshold = 3.0; // Adjust this value based on your needs

  @override
  void initState() {
    super.initState();

    userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      // Apply sensor fusion for orientation estimation
      updateOrientation(event);

      // Detect steps based on accelerometer data
      detectStep(event);
    });

    gyroscopeEvents.listen((GyroscopeEvent event) {
      // Integrate gyroscope data for orientation improvement
      updateOrientationWithGyroscope(event);
    });

    Timer.periodic(Duration(milliseconds: 100), (timer) {
      updatePosition();
    });
  }

  void updateOrientation(UserAccelerometerEvent event) {
    final alpha = 0.98;
    final gravity = event.x * event.x + event.y * event.y + event.z * event.z;
    final angle = atan2(event.x, sqrt(gravity));
    orientation = alpha * (orientation + angle) + (1 - alpha) * event.x;
    updateRotationMatrix();
  }

  void updateOrientationWithGyroscope(GyroscopeEvent event) {
    final dt = DateTime.now().millisecondsSinceEpoch - lastTime;
    orientation += event.z * dt;
    updateRotationMatrix();
    lastTime = DateTime.now().millisecondsSinceEpoch;
  }

  void updateRotationMatrix() {
    rotationMatrix.setRotation(orientation);
  }

  void detectStep(UserAccelerometerEvent event) {
    final currentAcceleration = event.y;
    if (lastAcceleration < accelerationThreshold && currentAcceleration >= accelerationThreshold) {
      // A positive peak indicates a potential step
      stepCount++;
      updatePosition();
    }
    lastAcceleration = currentAcceleration;
  }

  void updatePosition() {
    final now = DateTime.now().millisecondsSinceEpoch;
    deltaTime = (now - lastTime) / 1000.0;
    lastTime = now;

    double calibratedPosition = position + calibrationOffset;
    final predictedStepLength = deltaTime * stepLength;

    final processNoise = 0.001;
    final measurementNoise = 0.1;

    final predictedPosition = calibratedPosition + predictedStepLength;

    final predictionError = positionError + processNoise;
    final kalmanGain = predictionError / (predictionError + measurementNoise);
    calibratedPosition += kalmanGain * (predictedPosition - calibratedPosition);
    positionError = (1 - kalmanGain) * predictionError;

    position = calibratedPosition;

    setState(() {});
  }

  double positionError = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedestrian Dead Reckoning App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Step Count: $stepCount'),
            Text('Estimated Position: ${position} meters'),
            Text('Estimated Orientation: ${(orientation * 180 / pi).toStringAsFixed(2)} degrees'),
            Text('Step Length: ${stepLength.toStringAsFixed(2)} meters'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Prompt the user to input their stride length and calibration offset.
          // Update the stepLength and calibrationOffset based on user input.
        },
        child: Icon(Icons.edit),
      ),
    );
  }
}
