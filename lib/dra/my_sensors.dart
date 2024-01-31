import 'dart:async';
import 'dart:io';
import 'package:environment_sensors/environment_sensors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sensors/flutter_sensors.dart' as sens;
import 'package:geolocator/geolocator.dart' as geo ;
import 'package:indoornavigation/dra/dra.dart';
import 'package:indoornavigation/dra/heading.dart';
import 'package:indoornavigation/Util/localData.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:motion_sensors/motion_sensors.dart' as motion;

import '../dra/step_detection.dart';

class MySensors {
  List<double> _userAccelerometerValues = [0, 0, 0];
  List<double> _accelerometerValues = [0, 0, 0];
  List<double> _accelerometerList = [0, 0, 0];
  List<double> _gyroscopeValues = [0, 0, 0];
  List<double> _magnetometerValues = [0, 0, 0];
  List<double>? _newSensorValues;
  List<List<double>> accValues = [];
  List<List<double>> gyroValues = [];
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  double yaw = 0;
  int pitch = 0;
  int roll = 0;
  static double pressure = 0;

  int i = 0;
  static geo.Position userPosition = geo.Position(longitude: 0, latitude: 0, timestamp: DateTime.timestamp(), accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0);

  static int counter = 50;
  static int steps = 0;
  static int stepsgpt = 0;
  static int calibrationCounter = 0;

  ///Testing purpose
  ///
  static double l1 = 0;
  static double l2 = 0;
  static double l3 = 0;

  Vector3 _accelerometer = Vector3.zero();
  Vector3 _gyroscope = Vector3.zero();
  Vector3 _magnetometer = Vector3.zero();
  Vector3 _userAaccelerometer = Vector3.zero();
  Vector3 _orientation = Vector3.zero();
  Vector3 _absoluteOrientation = Vector3.zero();
  Vector3 _absoluteOrientation2 = Vector3.zero();
  File fileuseracc = File("");

  static geo.Position positionGps =  geo.Position(longitude: 0, latitude: 0, timestamp: DateTime.timestamp(), accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0);
  final geo.LocationSettings locationSettings = geo.LocationSettings(
    accuracy: geo.LocationAccuracy.high,
    distanceFilter: 0,
  );

  Future<void> SetupFile() async {
    fileuseracc = await localData
        .createFile("pressure_and_stockwerke_mit_verschidenen_höhen");
    fileuseracc.writeAsString("stockUndPos,wifilist\n", mode: FileMode.append);
  }

  Future<bool> StartSensorsAndPosition() async {
    bool allSenorsready = false;
    motion.motionSensors.magnetometer.listen((motion.MagnetometerEvent event) {
      _magnetometer.setValues(event.x, event.y, event.z);
      var matrix =
          motion.motionSensors.getRotationMatrix(_accelerometer, _magnetometer);
      _absoluteOrientation2
          .setFrom(motion.motionSensors.getOrientation(matrix));
      //print("absolte orientation from magnetometer:$matrix");
    });
    motion.motionSensors.isOrientationAvailable().then((available) {
      if (available) {
        motion.motionSensors.orientation
            .listen((motion.OrientationEvent event) {
          _orientation.setValues(event.yaw, event.pitch, event.roll);
        });
      }
    });
    _streamSubscriptions.add(
        gyroscopeEventStream(samplingPeriod: SensorInterval.fastestInterval)
            .listen(
      (GyroscopeEvent event) {
        _gyroscopeValues = <double>[event.x, event.y, event.z];
        //print(event);
      },
      onError: (error) {
        // Logic to handle error
        // Needed for Android in case sensor is not available
      },
      cancelOnError: true,
    ));
    motion.motionSensors.absoluteOrientation
        .listen((motion.AbsoluteOrientationEvent event) {
      _absoluteOrientation.setValues(event.yaw, event.pitch, event.roll);
      //print("absolte orientation yaw:${event.yaw/2/pi*360},pitch:${event.pitch/2/pi*360},roll:yaw:${event.roll/2/pi*360}");
      yaw = (event.yaw / 2 / pi * 360);
      pitch = (event.pitch / 2 / pi * 360).round();
      roll = (event.roll / 2 / pi * 360).round();
    });
    _streamSubscriptions.add(
        userAccelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
            .listen(
      (UserAccelerometerEvent event) {
        _userAccelerometerValues = <double>[event.x, event.y, event.z];
        // _accelerometerList.addAll(_userAccelerometerValues);
        //accValues.add(_userAccelerometerValues);

        StepDetector stepDetector = StepDetector();
        //print(stepDetector.detectStep(_userAccelerometerValues, _gyroscopeValues, DateTime.now()));
        if (stepDetector.detectStep(
            _userAccelerometerValues, _gyroscopeValues, DateTime.now())) {
          print("stepDetected!");
          stepsgpt++;
        }

        StepDetection.detectPeakAndValey(
            _userAccelerometerValues, DateTime.now().millisecondsSinceEpoch);
        if (StepDetection.steps > steps) {
          steps = StepDetection.steps;
          if (userPosition != null) {
            userPosition = DRA.nextPosition(yaw, 0.75, userPosition!);
          }
        }
      },
      onError: (error) {
        // Logic to handle error
        // Needed for Android in case sensor is not available
      },
      cancelOnError: true,
    ));
    _streamSubscriptions.add(
        accelerometerEventStream(samplingPeriod: SensorInterval.fastestInterval)
            .listen(
      (AccelerometerEvent event) {
        _accelerometerValues = <double>[event.x, event.y, event.z];
      },
      onError: (error) {
        // Logic to handle error
        // Needed for Android in case sensor is not available
      },
      cancelOnError: true,
    ));
    _streamSubscriptions.add(EnvironmentSensors().pressure.listen((event) {
      pressure = event;
    }));

    /*
        _streamSubscriptions.add(
            magnetometerEventStream(samplingPeriod: SensorInterval.fastestInterval).listen(
                (MagnetometerEvent event) {
                  _magnetometerValues = <double>[event.x, event.y, event.z];
                  },
            onError: (error) {
              // Logic to handle error
              // Needed for Android in case sensor is not available
            },
            cancelOnError: true,
          )
        );*/
    //timer = Timer.periodic(const Duration(milliseconds: 200), _updateDataSource);

    _streamSubscriptions.add(geo.Geolocator.getPositionStream(locationSettings: locationSettings).listen((event) {positionGps = event;}));

    await Timer(
      Duration(seconds: 1),
      () => print("sensors Ready!"),
    );
    return true;
  }
}

class _ChartData {
  _ChartData(this.t, this.accx, this.accy, this.accz);
  final int t;
  final double accx;
  final double accy;
  final double accz;
}
