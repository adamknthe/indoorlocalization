import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:geolocator/geolocator.dart';
import 'package:indoornavigation/Pages/sensor_page.dart';
import 'package:indoornavigation/Util/map_loader.dart' as m;
import 'package:indoornavigation/Wifi/accesspointmeasurement.dart';
import 'package:indoornavigation/Wifi/wifi_layer.dart';
import 'package:indoornavigation/Wifi/reference_point.dart';
import 'package:indoornavigation/Wifi/wifimeasurements.dart';
import 'package:indoornavigation/constants/runtime.dart';
import 'package:indoornavigation/dra/my_sensors.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'Pages/map_page.dart';
import 'package:indoornavigation/Util/localData.dart';
import 'Util/posi.dart';
import 'constants/Constants.dart';
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
  int timesupdted = 0;

  @override
  void initState() {
    Runtime.initialize();
    super.initState();

    WifiLayerGetter.getFirstLayer().then((value){
      wifiLayer = WifiLayerGetter.wifiLayer!;
      wifilayeravaileble = value;
      print("Wifilayer is imported: $value");
    });
    //test();

   //LevelCalculator.checkSensorsAvaileble();
   //WifiMeasurements.SetupWifi(context);
   //startlisten();
   //SetupPosition();
   //SetupSensors().then((value){
   //  print("Sensors is ready: $value");
   //});
   //PositionEstimation.startTimer();
   //SetupFile();


    //updatedatabase();

    //createWifiLayers(2, "frettchen", [0]);

  }

  ///TODO gets a first position fix and check permissions
  Future<void> SetupPosition() async {
    location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: false);
  } // 52.51678, latitude: 13.32347      52.51658, 13.32366

  ///not needed for realease
  Future<void> SetupFile() async {
    fileuseracc = await localData.createFile("referencepoints_and_wifis");
    fileuseracc.writeAsString("x,y,wifilist\n", mode: FileMode.append);
  }

  Future<void> createWifiLayers(int squareSizeInMeter, String name, List<int> floors) async {
    for(int x in floors){
      m.MapLoader? mapLoader = await m.MapLoader.getMaploader(name, x);
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
                Text('This is a demo alert dialog.'),
                Text('Would you like to approve of this message?'),
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

  @override
  Widget build(BuildContext context) {
    Sizes.initialize(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Container(
                  child: Text(
                    "time updated: $timesupdted",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
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
                    if(wifilayeravaileble){
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
                GestureDetector(
                  onTap: () {
                    print("get data");

                    getdata();
                  },
                  child: Container(
                    color: Colors.deepPurpleAccent,
                    height: 100,
                    child: Text("get data"),
                  ),
                ),

                GestureDetector(
                  onTap: () async {
                    print("update database");
                    //await getdata();
                    await updatedatabase();
                    //await getdata();
                    print("finished update");
                  },
                  child: Container(
                    color: Colors.deepPurpleAccent,
                    height: 100,
                    child: Text("update database"),
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
                GestureDetector(
                  onTap: () {
                    print("deletedata");

                    deletedata();
                  },
                  child: Container(
                    color: Colors.red,
                    height: 100,
                    child: Text("deleteddata"),
                  ),
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

  Future<void> updatedatabase() async {
    while(true){
      await updateReferencePoints();
      await getdata();
      //TODO comment in for constant running
      //sleep(Duration(minutes: 10));
      timesupdted++;
    }
  }

  Future<void> getdata() async{
    //WifiLayer? wifilayer = await WifiLayer.getWifiLayer("mar", 0);
    await SetupFile();
    print(await WifiLayerGetter.getFirstLayer());

    WifiLayer? wifiLayer = WifiLayerGetter.wifiLayer;

    if(wifiLayer != null){
      int x = 0;
      for(int i = 0; i < wifiLayer.referencePoints.length; i++){
        print(wifiLayer.referencePoints[i].accesspoints.length);
        String oneref = "${wifiLayer.referencePoints[i].longitude};${wifiLayer.referencePoints[i].latitude};${wifiLayer.referencePoints[i].accesspoints.length}\n";
        if(wifiLayer.referencePoints[i].accesspoints.length > 0){
          await fileuseracc.writeAsString(oneref,mode: FileMode.append);
        }
        //for(int j = 0; j < wifiLayer.referencePoints[i].accesspoints.length; j++ ){
        //  String oneref = "${wifiLayer.referencePoints[i].longitude};${wifiLayer.referencePoints[i].latitude};${wifiLayer.referencePoints[i].accesspoints.length}\n";
        //  await fileuseracc.writeAsString(oneref,mode: FileMode.append);
        //  x++;
        //}
      }
      //print("number of reference points: $x");
      //await fileuseracc.writeAsString("next update",mode: FileMode.append);
    }

  }

  Future<void> deletedata() async{
    //WifiLayer? wifilayer = await WifiLayer.getWifiLayer("mar", 0);
    //await SetupFile();
    print(await WifiLayerGetter.getFirstLayer());

    WifiLayer? wifiLayer = WifiLayerGetter.wifiLayer;

    if(wifiLayer != null){
      for(int i = 0; i < wifiLayer.referencePoints.length; i++){

        if(WifiLayer.isInsideOfBuildingFromList(WifiLayer.getListFromPolygonOutlinefloor(wifiLayer.GeojsonOfOutline), Posi(y: wifiLayer.referencePoints[i].latitude,x: wifiLayer.referencePoints[i].longitude)) == false){
          for(int j = 0; j < wifiLayer.referencePoints[i].accesspoints.length; j++ ){
              AccessPointMeasurement acc = wifiLayer.referencePoints[i].accesspoints[j];
              await acc.deleteAccessPointMeasurement();
            }
        }
        print(wifiLayer.referencePoints[i].accesspoints.length);
      }
    }

  }




  Future<List<NotSeen>> getnoseen() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? known = prefs.getStringList("known");
    if(known != null){
      List<NotSeen> noseen = List.generate(known.length, (index) => NotSeen.fromJson(jsonDecode(known[index])));
      print("retieved all: ${noseen.length}");
      return noseen;
    }
    List<NotSeen> noseenempty = [];
    print("retieved empty");
    return noseenempty;
  }

  Future<void> savenoSeen(List<NotSeen> noseen) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> known = List.generate(noseen.length, (index) => jsonEncode(noseen[index].toJson()));
    prefs.setStringList("known", known);
    print("saved all: ${known.length}");
  }

  Future<void> updateReferencePoints()async {

    List<NotSeen> notseen = await getnoseen();

    appwrite.DocumentList accessPointList = await Runtime.database.listDocuments(databaseId: databaseIdWifi, collectionId: collectionIDAccesPoints,queries: [Query.limit(100)]);
    if(accessPointList.documents.length > 0) {
      String lastIdAccespoints = accessPointList.documents[accessPointList.documents.length - 1].$id;
      appwrite.DocumentList newlist;
      do {
        newlist = await Runtime.database.listDocuments(
            databaseId: databaseIdWifi,
            collectionId: collectionIDAccesPoints,
            queries: [
              Query.limit(100),
              Query.cursorAfter(lastIdAccespoints),
            ]);
        accessPointList.documents.addAll(newlist.documents);
        lastIdAccespoints = accessPointList.documents[accessPointList.documents.length - 1].$id;
      }while (newlist.documents.isNotEmpty);

    }
    /*for(int i = 0; i < accessPointList.documents.length; i++){
        AccessPointMeasurement acc = AccessPointMeasurement.fromJson(accessPointList.documents[i].data, accessPointList.documents[i].$id);
        if(acc.level < -80){
          await acc.deleteAccessPointMeasurement();
        }
    }*/
    print("Accespoint list length " + accessPointList.documents.length.toString());
    appwrite.DocumentList list = await Runtime.database.listDocuments(databaseId: databaseIdWifi, collectionId: collectionIDReferencePoints,queries: [Query.limit(100)]);
    if(list.documents.length > 0){
      String lastId = list.documents[list.documents.length - 1].$id;
      appwrite.DocumentList newlist;
      do{
        newlist = await Runtime.database.listDocuments(databaseId: databaseIdWifi, collectionId: collectionIDReferencePoints,queries: [Query.limit(100),Query.cursorAfter(lastId)]);
        list.documents.addAll(newlist.documents);
        lastId = list.documents[list.documents.length - 1].$id;
      }while(newlist.documents.isNotEmpty);
    }
    print("referencepoints length ${list.documents.length}");

    for(int i = 0; i < list.documents.length; i++){
      List<AccessPointMeasurement> accpointlist = [];
      for(int j = 0; j < accessPointList.documents.length; j++){
        AccessPointMeasurement acc = AccessPointMeasurement.fromJson(accessPointList.documents[j].data, accessPointList.documents[j].$id);
        if(acc.referenceId == list.documents[i].$id){
          accpointlist.add(acc);
        }
      }

      if(accpointlist.isNotEmpty && accpointlist.any((item) {
        return item.isKnown == false;
      }) ){
        print(accpointlist.length);
        accpointlist.sort((a, b) {
          return a.bssid.compareTo(b.bssid);
        },);
        AccessPointMeasurement a1 = accpointlist[0];
        int occurence = 1;
        int avg = a1.level;
        for(int x = 1; x < accpointlist.length; x++){
          if(a1.bssid == accpointlist[x].bssid){
            occurence++;
            avg = avg + accpointlist[x].level;
            await accpointlist[x].deleteAccessPointMeasurement();
          }else{
            if(occurence == 1){
              NotSeen  notSeen = NotSeen(bssid: a1.bssid,refid: a1.referenceId, count: 1);
              if(notseen.contains(notSeen)){
                int at = notseen.indexWhere((element) {
                  if(element.bssid == notSeen.bssid && element.refid == notSeen.refid){
                    return true;
                  }
                    return false;
                });
                if(at > -1){
                  notseen[at].count = notseen[at].count+1;
                }
                if(notseen[at].count > 10){
                  await a1.deleteAccessPointMeasurement().then((value) => print("deleted because over 10 no seen"));
                  notseen.removeAt(at);
                  avg = accpointlist[x].level;
                  a1 = accpointlist[x];
                  occurence = 1;
                }
              }
            }else{
              a1.level = (avg/ occurence).round();
              a1.isKnown = true;
              NotSeen  notSeen = NotSeen(bssid: a1.bssid,refid: a1.referenceId, count: 1);
              if(notseen.contains(notSeen)){
                int at = notseen.indexWhere((element) {
                  if(element.bssid == notSeen.bssid && element.refid == notSeen.refid){
                    return true;
                  }
                  return false;
                });
                if(at > -1){
                  notseen.removeAt(at);
                }
              }
              await a1.updateAccessPointMeasurement();
              await a1.updateAccessPointMeasurement();
              avg = accpointlist[x].level;
              a1 = accpointlist[x];
              occurence = 1;
            }

          }
        }
        if(occurence == 1){
          NotSeen  notSeen = NotSeen(bssid: a1.bssid,refid: a1.referenceId, count: 1);
          if(notseen.contains(notSeen)){
            int at = notseen.indexWhere((element) {
              if(element.bssid == notSeen.bssid && element.refid == notSeen.refid){
                return true;
              }
              return false;
            });
            if(at > -1){
              notseen[at].count = notseen[at].count+1;
            }
            if(notseen[at].count > 10){
              await a1.deleteAccessPointMeasurement().then((value) => print("deleted because over 10 no seen"));
              notseen.removeAt(at);
            }
          }
        }else{
          a1.level = (avg/ occurence).round();
          a1.isKnown = true;
          NotSeen  notSeen = NotSeen(bssid: a1.bssid,refid: a1.referenceId, count: 1);
          if(notseen.contains(notSeen)){
            int at = notseen.indexWhere((element) {
              if(element.bssid == notSeen.bssid && element.refid == notSeen.refid){
                return true;
              }
              return false;
            });
            if(at > -1){
              notseen.removeAt(at);
            }
          }
          await a1.updateAccessPointMeasurement();
        }
      }

    }

    await savenoSeen(notseen);
  }

  void dothenotseenthing(String bssid, String refid,String accid){

  }
}

class NotSeen{
  final String bssid;
  final String refid;
  int count;

  NotSeen( {required this.bssid, required this.refid, required this.count});

  Map<String, dynamic> toJson(){
    return{
      "refid" : refid,
      "bssid" : bssid,
      "x" : count
    };
  }

  static NotSeen fromJson(Map<String, dynamic> json) {
    return NotSeen(
        bssid: json["bssid"], refid : json["refid"], count : json["x"]
    );
  }


}