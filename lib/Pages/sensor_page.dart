import 'dart:async';
import 'dart:io';
import 'package:environment_sensors/environment_sensors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sensors/flutter_sensors.dart' as sens;
import 'package:indoornavigation/dra/heading.dart';
import 'package:indoornavigation/Util/localData.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:motion_sensors/motion_sensors.dart' as motion;

import '../dra/step_detection.dart';

class SensorPage extends StatefulWidget {
  const SensorPage ({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  List<double> _userAccelerometerValues = [0,0,0];
  List<double> _accelerometerValues =  [0,0,0];
  List<double> _accelerometerList = [0,0,0];
  List<double>? _gyroscopeValues = [0,0,0];
  List<double>? _magnetometerValues = [0,0,0];
  List<double>? _newSensorValues;
  List<List<double>> accValues = [];
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  late Timer timer;
  int yaw = 0;
  int pitch = 0;
  int roll = 0;
  double pressure = 0;

  static int counter = 50;
  static int steps = 0;
  static int stepsall = 0;
  static int calibrationCounter= 0;
  Vector3 _accelerometer = Vector3.zero();
  Vector3 _gyroscope = Vector3.zero();
  Vector3 _magnetometer = Vector3.zero();
  Vector3 _userAaccelerometer = Vector3.zero();
  Vector3 _orientation = Vector3.zero();
  Vector3 _absoluteOrientation = Vector3.zero();
  Vector3 _absoluteOrientation2 = Vector3.zero();
  File fileuseracc = File("");

  final myControllerx = TextEditingController();


  Future<void> SetupFile() async {
    fileuseracc = await localData.createFile("pressure_and_stockwerke_mit_verschidenen_höhen");
    fileuseracc.writeAsString("stockUndPos,wifilist\n", mode: FileMode.append);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Sensors"),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          child: Column(
            children: [
              GestureDetector(
                onTap: () async { //Safe to file some steps
                  //File fileuseracc = await localData.createFile("useracc");
                  //fileuseracc.writeAsString("uaccx,uaccy,uaccz,umagnitude,accx,accy,accz,accmagnitude,time\n", mode: FileMode.append);
                  motion.motionSensors.magnetometer.listen((motion.MagnetometerEvent event) {
                    setState(() {
                      _magnetometer.setValues(event.x, event.y, event.z);
                      var matrix = motion.motionSensors.getRotationMatrix(_accelerometer, _magnetometer);
                      _absoluteOrientation2.setFrom(motion.motionSensors.getOrientation(matrix));
                      //print("absolte orientation from magnetometer:$matrix");
                    });
                  });
                  motion.motionSensors.isOrientationAvailable().then((available) {
                    if (available) {
                      motion.motionSensors.orientation.listen((motion.OrientationEvent event) {
                        setState(() {
                          _orientation.setValues(event.yaw, event.pitch, event.roll);

                        });
                      });
                    }
                  });
                  motion.motionSensors.absoluteOrientation.listen((motion.AbsoluteOrientationEvent event) {
                    setState(() {
                      _absoluteOrientation.setValues(event.yaw, event.pitch, event.roll);
                      //print("absolte orientation yaw:${event.yaw/2/pi*360},pitch:${event.pitch/2/pi*360},roll:yaw:${event.roll/2/pi*360}");
                      yaw = (event.yaw/2/pi*360).round();
                      pitch = (event.pitch/2/pi*360).round();
                      roll = (event.roll/2/pi*360).round();
                    });
                  });
                  _streamSubscriptions.add(
                    userAccelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
                          (UserAccelerometerEvent event) {
                            _userAccelerometerValues = <double>[event.x, event.y, event.z];
                           // _accelerometerList.addAll(_userAccelerometerValues);
                            //accValues.add(_userAccelerometerValues);
                            StepDetection.detectPeakAndValey(_userAccelerometerValues, DateTime.now().millisecondsSinceEpoch);
                            setState(() {
                              steps = StepDetection.steps;
                            });
                           },
                      onError: (error) {
                        // Logic to handle error
                        // Needed for Android in case sensor is not available
                      },
                      cancelOnError: true,
                    )
                  );
                  _streamSubscriptions.add(
                    accelerometerEventStream(samplingPeriod: SensorInterval.fastestInterval).listen(
                          (AccelerometerEvent event) {
                            _accelerometerValues = <double>[event.x, event.y, event.z];

                      },
                      onError: (error) {
                        // Logic to handle error
                        // Needed for Android in case sensor is not available
                      },
                      cancelOnError: true,
                    )

                  );
                  _streamSubscriptions.add(
                    EnvironmentSensors().pressure.listen((event) {
                      pressure = event;
                    })
                  );
                  /*
                  _streamSubscriptions.add(
                    gyroscopeEventStream(samplingPeriod: SensorInterval.fastestInterval).listen(
                          (GyroscopeEvent event) {
                            _gyroscopeValues = <double>[event.x, event.y, event.z];
                            //print(event);
                            },
                      onError: (error) {
                        // Logic to handle error
                        // Needed for Android in case sensor is not available
                      },
                      cancelOnError: true,
                    )
                  );
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

                  await Timer(Duration(seconds: 1),() => print("sensors Ready!"),);
                },
                child: Container(
                  color: Colors.green,
                  height: 100,
                  child: Text("start sensor"),
                  margin: EdgeInsets.all(20.0),
                ),
              ),
              GestureDetector(
                onTap: (){
                  dispose();
                 setState(() {
                    steps = 0;
                 });
                },
                child: Container(
                  color: Colors.green,
                  height: 100,
                  child: Text("Dispose!"),
                ),
              ),
              Container(
                color: Colors.green,
                height: 100,
                child: Text("yaw: $yaw, pitch: $pitch, roll: $roll"),
              ),
              Container(
                color: Colors.red,
                height: 100,
                child: Text("steps :$steps"),
              ),
              Container(
                child: Column(
                  children: [
                    TextField(
                      controller: myControllerx,
                    ),
                    GestureDetector(
                      onTap: (){
                        //fileuseracc.writeAsString("${myControllerx.text},$pressure\n", mode: FileMode.append);
                        setState(() {
                        });
                      },
                      child: Container (
                        height: 100,
                        color: Colors.purpleAccent ,
                        child: Text("save pressure!"),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    if(timer != null){
      timer.cancel();
    }



  }
}
