import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
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
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math.dart' as vmath;
import 'dart:io';
import 'Pages/map_page.dart';
import 'package:indoornavigation/Util/localData.dart';

import 'Util/Mercator.dart';
import 'Util/posi.dart';
import 'constants/sizes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
  bool wifilayeravaileble = false;
  bool sensorsReady = false;

  void _showToast(BuildContext context, String text) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(

        content: Text(text),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _showErrorToast(BuildContext context, String text) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(

        content: Text(text),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void initState() {
    Runtime.initialize();
    super.initState();
    //SetupFile();
    WifiLayerGetter.getFirstLayer().then((value) async {

      wifiLayer = WifiLayerGetter.wifiLayer!;
      wifilayeravaileble = value;
      _showToast(context, "Wifilayer imported: $value");
      print("Wifilayer is imported: $value");
      LevelCalculator.checkSensorsAvaileble();
      WifiMeasurements.setupWifi(context);
      //startlisten();
      await SetupPosition(wifiLayer);
      SetupSensors().then((value){

        print("Sensors is ready: $value");
        sensorsReady = true;

        PositionEstimation.startTimer();
        _showToast(context, "sensors started: $value");
      }).onError((error, stackTrace) {
         _showErrorToast(context, "Error with sensors occured\n${error.toString()}");
      });
    }).onError((error, stackTrace) {
      _showErrorToast(context, "Error with download occured\n${error.toString()}");
    });;
    //test();


   //SetupFile();

  }

  Position p = MySensors.positionGps;
  ///TODO gets a first position fix from wifi or gps
  Future<void> SetupPosition(WifiLayer layer) async {
    //52.516578139797026, 13.323632683857415
    //MySensors.userPosition = Position(longitude:  13.602261228434578, latitude: 52.50817621313987,  timestamp: DateTime.now(), accuracy: 2, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0 , speedAccuracy: 0);
    //PositionEstimation.estimatedPosi = Posi(x:13.602261228434578, y: 52.50817621313987);


    bool gotfromwififirst = false;
    bool checkwifi = false;

    Position position =  await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: false);
    p = position;

    late StreamSubscription<dynamic> subscription;
    subscription = WifiMeasurements.wifiresultstream.listen((event) {
      print("started wifi search!");
      gotfromwififirst = PositionEstimation.searchWifiFixStart(layer, event, position);
      print(PositionEstimation.estimatedPosi);
      checkwifi = true;
      subscription.cancel();
    });

    while(checkwifi == false){
      await Future.delayed(Duration(seconds: 1));
    }
    if(gotfromwififirst){
      return;
    }else{
      print("has to use gps");
      MySensors.userPosition = position;
      PositionEstimation.estimatedPosi = Posi( x: MySensors.userPosition.longitude, y: MySensors.userPosition.latitude);
    }

  }

  ///not needed for realease
  Future<void> SetupFile() async {
    fileuseracc = await LocalData.createFile("test_start_posi");
    fileuseracc.writeAsString("x_gps,y_gps,x_wifi,x_wifi,realPos is 52.51691242353624, 13.324037996280671\n", mode: FileMode.append);
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
    return mySensors.StartSensorsAndPosition(context);
  }

  final myControllerx = TextEditingController();
  final myControllery = TextEditingController();

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('WifiLayer not imported'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Wifilayer not ready'),
                Text('Or sensors not ready\please wait'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  List<Marker> markers = [];
  String text = "";

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
                  onTap: (){//13.323632683857415, y: 52.516578139797026
                    MySensors.userPosition = Position(longitude: 13.323632683857415, latitude: 52.516578139797026,  timestamp: DateTime.now(), accuracy: 2, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0 , speedAccuracy: 0);
                    PositionEstimation.estimatedPosi = Posi(x:13.323632683857415, y: 52.516578139797026);
                  },
                  child: Container(
                    color: Colors.yellowAccent,
                    height: 100,
                    child: Text("SetstartPosition"),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if(wifilayeravaileble && sensorsReady){
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                            return MapPage(wifiLayer: wifiLayer);}));
                      }else{
                            _showMyDialog();
                      }
                  },
                  child: Container(
                    color: Colors.cyanAccent,
                    height: 100,
                    child: Text("Map Page"),
                  ),
                ),
                Container(child: TextField(
                  controller: myControllery,
                    onChanged: (String newText) {
                      text = newText;
                    }
                ),),
                GestureDetector(
                  onTap: () async {
                    for(int i = 0; i < 10; i++){
                      await SetupPosition(wifiLayer);
                      await fileuseracc.writeAsString("${p.longitude},${p.latitude},${PositionEstimation.estimatedPosi.x},${PositionEstimation.estimatedPosi.y},$text\n", mode: FileMode.append);
                      _showToast(context, "done $i");
                      setState(() {
                        markers.add(Marker(point: LatLng(PositionEstimation.estimatedPosi.y, PositionEstimation.estimatedPosi.x), child: Icon(Icons.add)));
                      });
                    }

                  },
                  child: Container(
                    color: Colors.deepPurpleAccent,
                    height: 100,
                    width: 300,
                    child: Text("Test"),//18m 3m
                  ),
                ),
                Container(
                  height: 300,
                  width: 300,
                  child: FlutterMap(options:MapOptions(
                    initialCenter: const LatLng(52.51662390833064, 13.323514830215117),
                    initialZoom: 19.0,
                    minZoom: 10,
                    maxZoom: 24,
                    onPositionChanged: (position, hasGesture) {
                      // Fill your stream when your position changes
                      final zoom = position.zoom;
                      if (zoom != null) {
                      }
                    },

                  ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        /*urlTemplate: 'asset/mar_eg/{z}/{x}/{y}.png',
                    tileProvider: AssetTileProvider(),*/
                        minZoom: 9.0,
                        maxZoom: 25.0,
                      ),
                      MarkerLayer(markers: markers)

                    ],
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
