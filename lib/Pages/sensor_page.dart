import 'dart:async';
import 'dart:io';
import 'package:compassx/compassx.dart';
import 'package:environment_sensors/environment_sensors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_sensors/flutter_sensors.dart' as sens;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:indoornavigation/dra/dra.dart';
import 'package:indoornavigation/dra/heading.dart';
import 'package:indoornavigation/Util/localData.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:motion_sensors/motion_sensors.dart' as motion;

import '../dra/step_detection.dart';
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
  List<double> _gyroscopeValues = [0,0,0];
  List<double> _magnetometerValues = [0,0,0];
  List<double>? _newSensorValues;
  List<List<double>> accValues = [];
  List<List<double>> gyroValues = [];
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  _SensorPageState(){
    timer =
        Timer.periodic(const Duration(milliseconds: 200), _updateDataSource);
  }
  bool setFile = false;

  void _updateDataSource(Timer timer) {

      chartData!.add(_ChartData(i, _userAccelerometerValues[0], _userAccelerometerValues[0], _userAccelerometerValues[0]));

      if (chartData!.length > 50) {
        chartData!.removeAt(0);
        _chartSeriesController?.updateDataSource(
          addedDataIndexes: <int>[chartData!.length - 1],
          removedDataIndexes: <int>[0],
        );
      } else {
        _chartSeriesController?.updateDataSource(
          addedDataIndexes: <int>[chartData!.length - 1],
        );
      }
      chartData1!.add(_ChartData(i, _userAccelerometerValues[0], _userAccelerometerValues[0], _userAccelerometerValues[0]));
      if (chartData1!.length > 50) {
        chartData1!.removeAt(0);
        _chartSeriesController1?.updateDataSource(
          addedDataIndexes: <int>[chartData1!.length - 1],
          removedDataIndexes: <int>[0],
        );
      } else {
        _chartSeriesController1?.updateDataSource(
          addedDataIndexes: <int>[chartData1!.length - 1],
        );
      }
      chartData2!.add(_ChartData(i, _userAccelerometerValues[0], _userAccelerometerValues[0], _userAccelerometerValues[0]));
      if (chartData2!.length > 50) {
        chartData2!.removeAt(0);
        _chartSeriesController2?.updateDataSource(
          addedDataIndexes: <int>[chartData2!.length - 1],
          removedDataIndexes: <int>[0],
        );
      } else {
        _chartSeriesController2?.updateDataSource(
          addedDataIndexes: <int>[chartData2!.length - 1],
        );
      }

      count = count + 1;
      if(setFile == true){
        fileuseracc.writeAsString("$count,${userPosition?.latitude},${userPosition?.longitude},${positionGps?.latitude},${positionGps?.longitude},$heading_from_compass\n", mode: FileMode.append);
      }

  }

  late Timer timer;
  double yaw = 0;
  int pitch = 0;
  int roll = 0;
  static double pressure = 0;
  static double heading_from_compass = 0.0;

  int i = 0;
  geo.Position? userPosition = null;
  geo.Position? positionGps = null;


  static int counter = 50;
  static int steps = 0;
  static int stepsall = 0;
  static int calibrationCounter= 0;

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
  late int count = 21;
  final myControllerx = TextEditingController();

  List<_ChartData> chartData = <_ChartData>[
    _ChartData(0, 1, 1,0),
    _ChartData(1, 1, 1,0),
    _ChartData(2, 1, 1,0),
    _ChartData(3, 1, 1,0),
    _ChartData(4, 1, 1,0),
    _ChartData(5, 1, 1,0),
    _ChartData(6, 1, 1,0),
    _ChartData(7, 1, 1,0),
    _ChartData(8, 1, 1,0),
    _ChartData(9, 1, 1,0),
    _ChartData(10, 1, 1, 0),
    _ChartData(11, 1, 1, 0),
    _ChartData(12, 1, 1, 0),
    _ChartData(13, 1, 1, 0),
    _ChartData(14, 1, 1, 0),
    _ChartData(15, 1, 1, 0),
    _ChartData(16, 1, 1, 0),
    _ChartData(17, 1, 1, 0),
    _ChartData(18, 1, 1, 0),
    _ChartData(19, 1, 1, 0),
    _ChartData(20, 1, 1, 0)
  ];
  List<_ChartData> chartData1 = <_ChartData>[
    _ChartData(0, 1, 1,0),
    _ChartData(1, 1, 1,0),
    _ChartData(2, 1, 1,0),
    _ChartData(3, 1, 1,0),
    _ChartData(4, 1, 1,0),
    _ChartData(5, 1, 1,0),
    _ChartData(6, 1, 1,0),
    _ChartData(7, 1, 1,0),
    _ChartData(8, 1, 1,0),
    _ChartData(9, 1, 1,0),
    _ChartData(10, 1, 1, 0),
    _ChartData(11, 1, 1, 0),
    _ChartData(12, 1, 1, 0),
    _ChartData(13, 1, 1, 0),
    _ChartData(14, 1, 1, 0),
    _ChartData(15, 1, 1, 0),
    _ChartData(16, 1, 1, 0),
    _ChartData(17, 1, 1, 0),
    _ChartData(18, 1, 1, 0),
    _ChartData(19, 1, 1, 0),
    _ChartData(20, 1, 1, 0)
  ];
  List<_ChartData> chartData2 = <_ChartData>[
    _ChartData(0, 1, 1,0),
    _ChartData(1, 1, 1,0),
    _ChartData(2, 1, 1,0),
    _ChartData(3, 1, 1,0),
    _ChartData(4, 1, 1,0),
    _ChartData(5, 1, 1,0),
    _ChartData(6, 1, 1,0),
    _ChartData(7, 1, 1,0),
    _ChartData(8, 1, 1,0),
    _ChartData(9, 1, 1,0),
    _ChartData(10, 1, 1, 0),
    _ChartData(11, 1, 1, 0),
    _ChartData(12, 1, 1, 0),
    _ChartData(13, 1, 1, 0),
    _ChartData(14, 1, 1, 0),
    _ChartData(15, 1, 1, 0),
    _ChartData(16, 1, 1, 0),
    _ChartData(17, 1, 1, 0),
    _ChartData(18, 1, 1, 0),
    _ChartData(19, 1, 1, 0),
    _ChartData(20, 1, 1, 0)
  ];

  ChartSeriesController<_ChartData, int>? _chartSeriesController;
  ChartSeriesController<_ChartData, int>? _chartSeriesController1;
  ChartSeriesController<_ChartData, int>? _chartSeriesController2;



  Future<void> SetupFile() async {
    fileuseracc = await LocalData.createFile("position vergleich gps and dead reckoning");
    fileuseracc.writeAsString("counter,latDra,longDra,latGps,longGps,yaw\n", mode: FileMode.append);
    setFile = true;
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
        child: StepdetectionAndSensors(),
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
    setState(() {

    });
  }

  SfCartesianChart _buildLiveLineChart() {
    return SfCartesianChart(
        plotAreaBorderWidth: 0,
        primaryXAxis: const NumericAxis(majorGridLines: MajorGridLines(width: 0)),
        primaryYAxis: const NumericAxis(
            axisLine: AxisLine(width: 0),
            majorTickLines: MajorTickLines(size: 0)),
            axes: <ChartAxis>[
              NumericAxis(
                isVisible: true,
                name: "y",
              )
            ],
        series: <LineSeries<_ChartData, int>>[

          LineSeries<_ChartData, int>(
              onRendererCreated:
              (ChartSeriesController<_ChartData, int> controller) {
              _chartSeriesController1 = controller;
              },
              dataSource: chartData1,
              color: const Color.fromRGBO(10, 100, 232, 1),
              xValueMapper: (_ChartData v, _) => v.t,
              yValueMapper: (_ChartData v, _) {l1 = l1 * 0.5 + v.accz * 0.5; return l1;},
              animationDuration: 0,
            yAxisName: 'y',
            ),
          /*LineSeries<_ChartData, int>(
            onRendererCreated:
                (ChartSeriesController<_ChartData, int> controller) {
              _chartSeriesController = controller;
            },
            dataSource: chartData,
            color: const Color.fromRGBO(222, 108, 132, 1),
            xValueMapper: (_ChartData v, _) => v.t,
            yValueMapper: (_ChartData v, _) {return v.accz;} ,
            animationDuration: 0,
            yAxisName: 'y',
          ),
          LineSeries<_ChartData, int>(
              onRendererCreated:
              (ChartSeriesController<_ChartData, int> controller) {
              _chartSeriesController2 = controller;
              },
              dataSource: chartData1,
              color: const Color.fromRGBO(60, 200, 60, 1),
              xValueMapper: (_ChartData v, _) => v.t,
              yValueMapper: (_ChartData v, _) => v.accy,
              animationDuration: 0,
              yAxisName: 'y',
            ),*/
        ]);
  }

  Widget sensorStarter(){
    return GestureDetector(
      onTap: () async {
        print("Sensorsready: ${StartSensorsAndPosition()}");
        SetupFile();
      },
      child: Container(
        color: Colors.green,
        height: 100,
        child: Text("start sensor"),
        margin: EdgeInsets.all(20.0),
      ),
    );
  }

  final geo.LocationSettings locationSettings = geo.LocationSettings(
    accuracy: geo.LocationAccuracy.best,
    distanceFilter: 0,
  );


  Future<bool> StartSensorsAndPosition() async {
    bool allSenorsready = false;
    motion.motionSensors.magnetometer.listen((motion.MagnetometerEvent event) {

      _magnetometer.setValues(event.x, event.y, event.z);
      var matrix = motion.motionSensors.getRotationMatrix(_accelerometer, _magnetometer);
      _absoluteOrientation2.setFrom(motion.motionSensors.getOrientation(matrix));
      //print("absolte orientation from magnetometer:$matrix");
    });
    motion.motionSensors.isOrientationAvailable().then((available) {
      if (available) {
        motion.motionSensors.orientation.listen((motion.OrientationEvent event) {
            _orientation.setValues(event.yaw, event.pitch, event.roll);

        });
      }
    });
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
    motion.motionSensors.absoluteOrientation.listen((motion.AbsoluteOrientationEvent event) {
        _absoluteOrientation.setValues(event.yaw, event.pitch, event.roll);
        //print("absolte orientation yaw:${event.yaw/2/pi*360},pitch:${event.pitch/2/pi*360},roll:yaw:${event.roll/2/pi*360}");
        yaw = ((event.yaw/-2/pi*360))% 360 ;
        pitch = (event.pitch/2/pi*360).round();
        roll = (event.roll/2/pi*360).round();
        print("from motion sensors$yaw");
    });
    _streamSubscriptions.add(
        userAccelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
              (UserAccelerometerEvent event) {
            _userAccelerometerValues = <double>[event.x, event.y, event.z];
            // _accelerometerList.addAll(_userAccelerometerValues);
            //accValues.add(_userAccelerometerValues);


            if (chartData.length > 50) {
              chartData.removeAt(0);
              _chartSeriesController?.updateDataSource(
                addedDataIndexes: <int>[chartData.length - 1],
                removedDataIndexes: <int>[0],
              );
            } else {
              _chartSeriesController?.updateDataSource(
                addedDataIndexes: <int>[chartData.length - 1],
              );
            }
            chartData.add(_ChartData(i, event.x, event.y, event.z));

            if (chartData1.length > 50) {
              chartData1.removeAt(0);
              _chartSeriesController1?.updateDataSource(
                addedDataIndexes: <int>[chartData1.length - 1],
                removedDataIndexes: <int>[0],
              );
            } else {
              _chartSeriesController1?.updateDataSource(
                addedDataIndexes: <int>[chartData1.length - 1],
              );
            }
            chartData1.add(_ChartData(i, event.x, event.y, event.z));

            if (chartData2.length > 50) {
              chartData2.removeAt(0);
              _chartSeriesController2?.updateDataSource(
                addedDataIndexes: <int>[chartData2.length - 1],
                removedDataIndexes: <int>[0],
              );
            } else {
              _chartSeriesController2?.updateDataSource(
                addedDataIndexes: <int>[chartData2.length - 1],
              );
            }
            chartData2.add(_ChartData(i, event.x, event.y, event.z));
            i++;

            StepDetector stepDetector = StepDetector();
            //print(stepDetector.detectStep(_userAccelerometerValues, _gyroscopeValues, DateTime.now()));
            if(stepDetector.detectStep(_userAccelerometerValues, _gyroscopeValues, DateTime.now())){
              print("stepDetected!");
              stepsall++;
            }

            StepDetection.detectPeakAndValey(_userAccelerometerValues, DateTime.now().millisecondsSinceEpoch);
            setState(() {
              if(StepDetection.steps > steps){
                steps = StepDetection.steps;
                if(userPosition != null){
                  print(yaw);
                  userPosition = DRA.nextPosition(heading_from_compass, 1.08, userPosition!);
                }
              }

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
        magnetometerEventStream(samplingPeriod: SensorInterval.fastestInterval).listen(
              (MagnetometerEvent event) {
                _magnetometerValues = <double>[event.x, event.y, event.z];

                //int head = Calculations().updateHeading(_gyroscopeValues[0], _gyroscopeValues[1], _gyroscopeValues[2], _accelerometerValues[0], _accelerometerValues[1], _accelerometerValues[2], _magnetometerValues[0], _magnetometerValues[1], _magnetometerValues[2], DateTime.now().millisecondsSinceEpoch);
                //print("from top techboy: $head");
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
    _streamSubscriptions.add(
      FlutterCompass.events!.listen((event) {
        //print(event.heading);
        //print(event.accuracy);

        heading_from_compass = (event.heading!) % 360;
        print("fluttercompas$heading_from_compass");
        /*if(positionGps!.heading < heading_from_compass-15 || positionGps!.heading < heading_from_compass-15 ){
          print("heading wya to off\n heading is :$heading_from_compass \n should: ${positionGps!.heading} ");
          print(positionGps!.headingAccuracy);
        }*/
      })
    );
    _streamSubscriptions.add(
        geo.Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((event) {
          positionGps = event;

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
    await Timer(Duration(seconds: 1),() => print("sensors Ready!"),);
    return true;
  }

  Widget StepdetectionAndSensors(){
    return  Container(
      child: SingleChildScrollView(
        child: Column(
          children: [
            sensorStarter(),
            Container(
              child: _buildLiveLineChart(),
            ),
            GestureDetector(
              onTap: () async{
                userPosition = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high, forceAndroidLocationManager: true);
                setState((){

                });
              },
              child: Container(
                color: Colors.green,
                height: 100,
                child: Text("setStartPosition: lat:${userPosition?.latitude}, long:${userPosition?.longitude}\n walked distance${ DRA.walkedDistance}"),
              ),
            ),
            GestureDetector(
              onTap: (){
                dispose();
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
              child: Text("yaw: $heading_from_compass, pitch: $pitch, roll: $roll"),
            ),
            GestureDetector(
              onTap: (){

                setState(() {
                  steps =0;
                  stepsall =0;
                  StepDetection.overallacctoY = 0;
                  StepDetection.steps = 0;
                });
              },
              child: Container(
                color: Colors.red,
                height: 100,
                child: Text("steps :$steps\n steps gpt: $stepsall\n overall accY: ${StepDetection.overallacctoY}"),
              ),
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
    );
  }
}

class _ChartData {
  _ChartData(this.t, this.accx, this.accy, this.accz);
  final int t;
  final double accx;
  final double accy;
  final double accz;
}
