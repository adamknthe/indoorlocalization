import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:indoornavigation/Pages/sensor_page.dart';
import 'package:indoornavigation/Util/map_loader.dart';
import 'package:indoornavigation/Wifi/wifi_layer.dart';
import 'package:indoornavigation/Util/levelCalculator.dart';
import 'package:indoornavigation/Wifi/reference_point.dart';
import 'package:indoornavigation/Wifi/wifi.dart';
import 'package:indoornavigation/Wifi/wifimeasurements.dart';
import 'package:indoornavigation/constants/runtime.dart';
import 'package:indoornavigation/dra/my_sensors.dart';
import 'package:indoornavigation/dra/positionalgorithm/positionEstimation.dart';
import 'package:vector_math/vector_math.dart' as vmath;
import 'dart:io';
import 'Pages/map_page.dart';
import 'package:indoornavigation/Util/localData.dart';

import 'constants/sizes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platForm = const MethodChannel("com.adam.wifi/scan");
  String message = "check if Your are at know location";
  bool getPosition = false;
  late Position location;
  File fileuseracc = File("");
  //static bool wifiLayerDowaloaded = false;
  WifiLayerGetter wifiLayerGetter = WifiLayerGetter();
  late WifiLayer wifiLayer;

  @override
  void initState() {
    Runtime.initialize();
    super.initState();


    WifiLayerGetter.getFirstLayer().then((value){
      wifiLayer = WifiLayerGetter.wifiLayer!;
      print("Wifilayer is imported: $value");

    });
    //test();

   LevelCalculator.checkSensorsAvaileble();
   WifiMeasurements.SetupWifi(context);
   //startlisten();
   SetupPosition();
   //SetupSensors().then((value){
   //  print("Sensors is ready: $value");
   //});
   //PositionEstimation.startTimer();
   //SetupFile();

  }

  ///TODO gets a first position fix and check permissions
  Future<void> SetupPosition() async {
    location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: false);
  } // 52.51678, latitude: 13.32347      52.51658, 13.32366

  ///not needed for realease
  Future<void> SetupFile() async {
    fileuseracc = await localData.createFile("wifi_with_positions");
    fileuseracc.writeAsString("x,y,wifilist\n", mode: FileMode.append);
  }


  Future<void> createWifiLayers(int squareSizeInMeter, String name, List<int> floors) async {
    for(int x in floors){
      MapLoader? mapLoader = await MapLoader.getMaploader(name, x);
      if(mapLoader != null){
        String geoJson = mapLoader.GeoJson;
        WifiLayer wifiLayer = WifiLayer(referencePoints: [], Buildingname: name, floorLevel: x , GeojsonOfOutline: geoJson);
        await wifiLayer.createReferencePoints();
        print(wifiLayer.referencePoints.length);
        await wifiLayer.createWifiLayer();
      }
    }

  }
  ///Maybe not important
  Future<void> test() async {

    ReferencePoint? referencePoint =await ReferencePoint.getReferencePoint("65be3aebb80743fc7013");
    print("hello");
    if(referencePoint != null){
      print("not null");
      print(referencePoint.accesspointsNew.length);
      referencePoint.calculateAccespoints();
    }
    /*
    String batteryLevel;
    try {
      final int result = await platForm.invokeMethod('Scan');
      batteryLevel = 'Battery level at $result % .';
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }

    print(batteryLevel);
    */
    setState(() {});
  }

  ///Maybe not important
  Future<void> scan() async {
    String batteryLevel;
    try {
      //final int result = await platForm.invokeMethod('Wifi');
      //batteryLevel = 'Battery level at $result % .';
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }
    setState(() {});
  }

  ///Start Sensors and StepDetection
  Future<bool> SetupSensors() async{
    MySensors mySensors = MySensors();
    return mySensors.StartSensorsAndPosition();
  }

  final myControllerx = TextEditingController();
  final myControllery = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Sizes.initialize(context);
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SensorPage()),
                    );
                  },
                  child: Container(
                    color: Colors.green,
                    height: 100,
                    child: Text("Sensor testing page"),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                          return MapPage(wifiLayer: wifiLayer);
                      },
                    ));
                  },
                  child: Container(
                    color: Colors.cyanAccent,
                    height: 100,
                    child: Text("Map Page"),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    PositionEstimation.exceute();
                  },
                  child: Container(
                    color: Colors.deepPurpleAccent,
                    height: 100,
                    child: Text("Test"),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    print("start setting wifiLayer");
                    await createWifiLayers(2, "mar", [6]);
                  },
                  child: Container(
                    color: Colors.deepPurpleAccent,
                    height: 100,
                    child: Text("setWifiLayer"),
                  ),
                ),
                Container(
                  child: Text("${MySensors.steps}",style: TextStyle(fontSize: 20)),
                ),
                Column(
                  children: List.generate(WifiMeasurements.wifi.accessPoints.length, (index) {
                    return Text(
                        "bssid: ${WifiMeasurements.wifi.accessPoints[index].bssid} dBm: ${WifiMeasurements.wifi.accessPoints[index].level} name: ${WifiMeasurements.wifi.accessPoints[index].ssid}, ${WifiMeasurements.wifi.accessPoints[index].is80211mcResponder}");
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void startlisten() {
    WifiMeasurements.wifi.subscription?.onData((data) {
      print(data);
    });
  }
}
