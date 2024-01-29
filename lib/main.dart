import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:indoornavigation/Pages/sensor_page.dart';
import 'package:indoornavigation/Wifi/wifi_layer.dart';
import 'package:indoornavigation/Util/levelCalculator.dart';
import 'package:indoornavigation/Wifi/reference_point.dart';
import 'package:indoornavigation/Wifi/wifi.dart';
import 'package:indoornavigation/constants/runtime.dart';
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

  List<ReferencePoint> referencePoints = [];
  Wifi wifi = Wifi();
  String message = "check if Your are at know location";
  bool getPosition = false;
  late Position location;
  int count = 0;
  File fileuseracc = File("");
  bool wasScannedAfterset = false;
  late WifiLayer wifiLayer;

  @override
  void initState() {
    Runtime.initialize();

    super.initState();
    //getFirstLayer().then((value){
    //  print(value);
    //});
    LevelCalculator.checkSensorsAvaileble();
    SetupWifi();
    SetupPosition();
    //SetupFile();
  }

  Future<bool> getFirstLayer() async{
    //String test = await DefaultAssetBundle.of(context).loadString("asset/maps/geo.json");
    //WifiLayer.getJsontoFunktionAndCall(test);
    //WifiLayer.createReferencePoints(wifiLayer);
    try{
      wifiLayer = (await WifiLayer.getWifiLayer("mar", 0))!;
      return true;
    }catch(e){
      return false;
    }

  }

  Future<void> SetupPosition() async {


    location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: false);
  } // 52.51678, latitude: 13.32347      52.51658, 13.32366

  Future<void> SetupFile() async {
    fileuseracc = await localData.createFile("wifi_with_positions");
    fileuseracc.writeAsString("x,y,wifilist\n", mode: FileMode.append);
  }

  void SetupWifi() {
    wifi.canGetScannedResults(context);
    wifi.startScan();
    wifi.startListeningToScanResults(context).then((value) {
      wifi.subscription?.onData((value) {
        wasScannedAfterset = true;
        //for(int i = 0; i < value.length; i++){
        //  print("bssid${value.elementAt(i).bssid} dBm: ${value.elementAt(i).level}");
        //}
        wifi.accessPoints = value;
        count++;
        setState(() {});
        wifi.startScan();
      });
    });

    test();
  }

  Future<void> test() async {
    String batteryLevel;
    try {
      final int result = await platForm.invokeMethod('Scan');
      batteryLevel = 'Battery level at $result % .';
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }

    print(batteryLevel);

    setState(() {});
  }

  Future<void> scan() async {
    String batteryLevel;
    try {
      //final int result = await platForm.invokeMethod('Wifi');
      //batteryLevel = 'Battery level at $result % .';
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }
    wifi.startScan();
    setState(() {});
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
                          return MapPage();
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
                    print("check for wifi");
                    print(
                        "referencePoints " + referencePoints.length.toString());
                    if (referencePoints.isNotEmpty) {
                      print("ref acces " +
                          referencePoints.first.accesspoints.length.toString());
                    }
                    print("wifi " + wifi.accessPoints.length.toString());
                    for (int x = 0; x < referencePoints.length; x++) {
                      for (int j = 0;
                          j < referencePoints[x].accesspoints.length;
                          j++) {
                        for (int i = 0; i < wifi.accessPoints.length; i++) {
                          if (wifi.accessPoints[i].bssid ==
                                  referencePoints[x].accesspoints[j].bssid &&
                              wifi.accessPoints[i].level >=
                                  referencePoints[x].accesspoints[j].level) {
                            message =
                                "lat: ${referencePoints[i].latitude} long: ${referencePoints[i].longitude}";

                            setState(() {});
                            print("done checking");
                            return;
                          }
                        }
                      }
                    }
                    message = "update";
                    setState(() {});
                  },
                  child: Container(
                    color: Colors.red,
                    height: 100,
                    child: Text(message),
                  ),
                ),
                Text(count.toString()),
                Column(
                  children: List.generate(wifi.accessPoints.length, (index) {
                    return Text(
                        "bssid: ${wifi.accessPoints[index].bssid} dBm: ${wifi.accessPoints[index].level} name: ${wifi.accessPoints[index].ssid}, ${wifi.accessPoints[index].is80211mcResponder}");
                  }),
                ),
                GestureDetector(
                  onTap: () async {
                    scan();
                    setState(() {});
                  },
                  child: Container(
                    color: Colors.green,
                    height: 100,
                    child: Text("Scan"),
                  ),
                ),
                Container(
                  child: Column(
                    children: [
                      TextField(
                        controller: myControllerx,
                      ),
                      TextField(
                        controller: myControllery,
                      ),
                      GestureDetector(
                        onTap: () {
                          fileuseracc.writeAsString(
                              "${myControllerx.text},${myControllery.text},${wifi}\n",
                              mode: FileMode.append);
                          setState(() {
                            wasScannedAfterset = false;
                          });
                        },
                        child: Container(
                          height: 100,
                          color: wasScannedAfterset == true
                              ? Colors.purpleAccent
                              : Colors.red,
                          child: Text(
                              "$wasScannedAfterset save Wifi with x,y,wifilist"),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void startlisten() {
    wifi.subscription?.onData((data) {
      print(data);
    });
  }
}
