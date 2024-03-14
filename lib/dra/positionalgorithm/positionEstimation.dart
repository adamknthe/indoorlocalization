import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:indoornavigation/Pages/map_page.dart';
import 'package:indoornavigation/Util/Mercator.dart';
import 'package:indoornavigation/Util/posi.dart';
import 'package:indoornavigation/Wifi/accesspointmeasurement.dart';
import 'package:indoornavigation/Wifi/reference_point.dart';
import 'package:indoornavigation/Wifi/wifi_layer.dart';
import 'package:indoornavigation/Wifi/wifimeasurements.dart';
import 'package:indoornavigation/dra/dra.dart';
import 'package:indoornavigation/dra/my_sensors.dart';
import 'package:indoornavigation/dra/step_detection.dart';
import 'package:latlong2/latlong.dart';
import 'package:rbush/rbush.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../../Util/localData.dart';
import '../peak.dart';

class PositionEstimation {
  static Posi estimatedPosi = Posi(x: 0, y: 0);

  static List<Position> _listPosition = [];
  static List<WiFiAccessPoint> measurement = [];
  //TODO implemente only on measurement per square on last square
  static Position gpsposition = Position(
      longitude: 0,
      latitude: 0,
      timestamp: DateTime.timestamp(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0);
  static List<Peak> peaks = [];
  static int positionsWithoutFix = 0;
  static double walkedDistance = 0.0;
  static int steps = 0;
  static Position draposition = Position(
      longitude: 0,
      latitude: 0,
      timestamp: DateTime.timestamp(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0);
  static WifiLayer? wifiLayer;
  static late Timer updateTick;
  static int floor = 0;
  static bool drapositionused = false;
  static int uploadedrefsAccespoints = 0;
  static String isstillSame = "";
  static File fileuseracc = File("");

  //static StreamController<Posi> controller = StreamController<Posi>.broadcast();
  //static late Stream<Posi> estimatedPositionStream;

  static StreamController<LocationMarkerPosition?> mapPosController = StreamController<LocationMarkerPosition?>.broadcast();
  static late Stream<LocationMarkerPosition?>? mapPosStream;

  static Future<void> startTimer() async {
    await SetupFile();
    //estimatedPositionStream = controller.stream;
    mapPosStream = mapPosController.stream;
    //print("is broadcast :${estimatedPositionStream.isBroadcast}");
    MySensors.userPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high,forceAndroidLocationManager: false);
    MySensors.positionGps = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high,forceAndroidLocationManager: false);
    getEverything();

    MySensors.draposition.listen((event) {
      //print("dra update! movement");
      if(!WifiLayer.isInsideOfBuildingFromList(WifiLayer.getListFromPolygonOutline(wifiLayer!.GeojsonOfOutline), Posi(x: event.longitude , y: event.latitude))){
        //TODO problem with jump
        late StreamSubscription sub;
         sub = WifiMeasurements.wifiresultstream.listen((event) async {
           measurement.clear();
           for(int i = 0; i < event.length; i++){
             if(event[i].level > -81){
               measurement.add(event[i]);
             }
           }
           await searchWifiFixStart(wifiLayer! , measurement, await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high,forceAndroidLocationManager: false) );
           sub.cancel();
         });
      }else{
        //controller.add(Posi(x: event.longitude , y: event.latitude));
        mapPosController.add(LocationMarkerPosition(latitude: event.latitude, longitude: event.longitude, accuracy: 7));
        draposition = event;
        estimatedPosi = Posi(x: event.longitude , y: event.latitude);
        fileuseracc.writeAsString("$estimatedPosi,${MySensors.oldheading}\n", mode: FileMode.append);
      }


    });

    WifiMeasurements.wifiresultstream.listen((event) {
      getEverything();
      measurement.clear();
      for(int i = 0; i < event.length; i++){
        if(event[i].level > -81){
          measurement.add(event[i]);
        }
      }
     // print("measurement: $measurement");
        /// ist estimated in x y
      if(wifiLayer != null){
        if(refKnown()){
          searchWifiFix(wifiLayer!, measurement);
        }else{
          updateRef();
        }
      }
    });
    print("started timer");
  }


  static bool refKnown (){
    String reftoUpdate = docidNearestRef(wifiLayer!.referencePoints, estimatedPosi);
    ReferencePoint ref = wifiLayer!.referencePoints.firstWhere((element) => element.documentId == reftoUpdate);
    if(ref.accesspoints.isNotEmpty){
      return true;
    }
    return false;
  }


  static Future<void> SetupFile() async {
    fileuseracc = await LocalData.createFile("walkingTest");
    fileuseracc.writeAsString("x,y,wifilist\n", mode: FileMode.append);
  }


  static void getEverything() {
    peaks = StepDetection.peaksAndValey;
    steps = StepDetection.steps;
    gpsposition = MySensors.positionGps;
    wifiLayer = WifiLayerGetter.wifiLayer;
    walkedDistance = DRA.walkedDistance;
    positionsWithoutFix = DRA.positionsWithoutFix;
  }

  static void searchWifiFix(WifiLayer wifiLayer, List<WiFiAccessPoint> accespoints) {
    //print("in search fix");
    if (accespoints.length < 1) {
      print("return because no accespoints");
      return;
    }
    List<PossiblePosition> pos = getPossible(wifiLayer.referencePoints, accespoints);

    /*
    List<ReferencePoint> containAccespoints = [];
    for (int i = 0; i < wifiLayer.referencePoints.length; i++) {
      for (int j = 0; j < accespoints.length; j++) {
        if (wifiLayer.referencePoints[i].accesspoints
            .contains(accespoints[j].bssid)) {
          containAccespoints.add(wifiLayer.referencePoints[i]);
        }
      }
    }
    if (containAccespoints.length < 0) {
      SetNewAccespoints(accespoints);
      return;
    }
    */

    if (pos.length > 3) {
      ReferencePoint ref = wifiLayer.referencePoints.firstWhere((element) => element.documentId == pos[0].docId);

      print("distance : ${Geolocator.distanceBetween(ref.latitude  , ref.longitude, draposition.latitude, draposition.longitude)}");
      if(Geolocator.distanceBetween(ref.latitude  , ref.longitude, draposition.latitude, draposition.longitude) < 2.1){
        estimatedPosi = Posi(x: ref.longitude, y: ref.latitude);
        print("position came from wifi ");
      }

      //controller.add(estimatedPosi);
      mapPosController.add(LocationMarkerPosition(latitude: estimatedPosi.y, longitude: estimatedPosi.x, accuracy: 7));
    }

    updateRef();

  }

  static bool searchWifiFixStart(WifiLayer wifiLayer, List<WiFiAccessPoint> accespoints ,Position posGps) {
    print("search first fix");
    if (accespoints.length < 1) {
      print("return because no accespoints");
      return false;
    }
    List<PossiblePosition> pos = getPossible(wifiLayer.referencePoints, accespoints);

    /*
    List<ReferencePoint> containAccespoints = [];
    for (int i = 0; i < wifiLayer.referencePoints.length; i++) {
      for (int j = 0; j < accespoints.length; j++) {
        if (wifiLayer.referencePoints[i].accesspoints
            .contains(accespoints[j].bssid)) {
          containAccespoints.add(wifiLayer.referencePoints[i]);
        }
      }
    }
    if (containAccespoints.length < 0) {
      SetNewAccespoints(accespoints);
      return;
    }
    */

    if (pos.length > 3) {
      ReferencePoint ref = wifiLayer.referencePoints.firstWhere((element) => element.documentId == pos[0].docId);
      double distance = 0;
      for(int i = 0; i < 4; i++){
        ReferencePoint refx = wifiLayer.referencePoints.firstWhere((element) => element.documentId == pos[i].docId);
        distance = Geolocator.distanceBetween(ref.latitude  , ref.longitude, posGps.latitude, posGps.longitude);
        if(distance < posGps.accuracy){
          ref = refx;
          distance = Geolocator.distanceBetween(refx.latitude  , refx.longitude, posGps.latitude, posGps.longitude);
          break;
        }
      }

      print("${posGps.latitude},${posGps.longitude},${posGps.accuracy}");
      print("${ref.latitude},${ref.longitude}");
      print("distance : $distance");
      if(distance <= posGps.accuracy + 2.0){
        estimatedPosi = Posi(x: ref.longitude, y: ref.latitude);
        print("position came from wifi from stream start ");
      }else{
        estimatedPosi = Posi(x: posGps.longitude, y: posGps.latitude);
        print("position came from wifi from stream gps");
      }

      //controller.add(estimatedPosi);
      mapPosController.add(LocationMarkerPosition(latitude: estimatedPosi.y, longitude: estimatedPosi.x, accuracy: 7));
      return true;
    }

    return false;

  }

  static Future<void> updateRef() async {
    String reftoUpdate = docidNearestRef(wifiLayer!.referencePoints, estimatedPosi);
    if(isstillSame != reftoUpdate){
      ReferencePoint ref = wifiLayer!.referencePoints.firstWhere((element) => element.documentId == reftoUpdate);
      if(Geolocator.distanceBetween(estimatedPosi.y, estimatedPosi.x, ref.latitude , ref.longitude) > 2.0){
        //print("too far ${Geolocator.distanceBetween(estimatedPosi.y, estimatedPosi.x, ref.latitude , ref.longitude)}");
        return;
      }else{
        List<WiFiAccessPoint> accespoints = measurement;
        SetNewAccespoints(ref, accespoints);
        uploadedrefsAccespoints++;
        //print("uploaded Ref:${ref.documentId}");
      }
      isstillSame = reftoUpdate;
    }


  }

  static List<PossiblePosition> getPossible(List<ReferencePoint> ref, List<WiFiAccessPoint> accespoints) {
    //TODO search überabeiten
    List<PossiblePosition> res = [];
    ref.forEach((reference) {
      int allError = 0;
      int countoverlap = 0;
      reference.accesspoints.forEach((ap) {
        accespoints.forEach((apm) {
          if (ap.bssid == apm.bssid) {
            int error = sqrt(pow((ap.level - apm.level), 2)).round(); //euclidean distance 1D
            if(error <= 3 ){
              countoverlap++;
              allError = allError + error;
            }
          }
        });
      });
      if (countoverlap != 0) {
        res.add(PossiblePosition(
            avgError: (allError / countoverlap).round(),
            docId: reference.documentId,
            overlap: countoverlap,
            nonoverlap: (accespoints.length - countoverlap)));
      }
    });
    res.sort(
      (a, b) {
        int x =  -a.overlap.compareTo(b.overlap);
        if (x == 0) {
          int y = a.nonoverlap.compareTo(b.nonoverlap);
          if(y == 0){
            return a.avgError.compareTo(b.avgError) ;
          }
        }
        return x;
      },
    );
    print(res);
    return res;
  }

  static void getPositionWithoutWifi() {
    if (gpsposition.latitude == 0) {
      print("always returning too early1");
      return;
    }

      if(draposition.timestamp.isAfter(gpsposition.timestamp)){
        if (gpsposition.accuracy > 7) {
          print("gps accuracy: ${gpsposition.accuracy}");
          return;
        }
        double distance = Geolocator.distanceBetween(gpsposition.latitude, gpsposition.longitude, draposition.latitude, draposition.longitude);
        if(distance < gpsposition.accuracy){
          print("always returning too early3");
          return;
        }else{
          print("set to start to gps");
          estimatedPosi.x = gpsposition.longitude;
          estimatedPosi.y = gpsposition.latitude;
          drapositionused =false;
          MySensors.userPosition.longitude = gpsposition.longitude;
          MySensors.userPosition.latitude = gpsposition.latitude;
          MySensors.userPosition.timestamp = gpsposition.timestamp;
          //controller.add(estimatedPosi);
          mapPosController.add(LocationMarkerPosition(latitude: estimatedPosi.y , longitude: estimatedPosi.x, accuracy: 7));

        }
      }else {
        print("dra positionused");
        estimatedPosi.x = draposition.longitude;
        estimatedPosi.y = draposition.latitude;
        drapositionused = true;
        //controller.add(estimatedPosi);
        mapPosController.add(LocationMarkerPosition(latitude: estimatedPosi.y , longitude: estimatedPosi.x, accuracy: 7));

      }

    if(estimatedPosi.x == 0){
      return;
    }
    print(estimatedPosi);
  }

  static ReferencePoint matchPosToRef() {
    return ReferencePoint(documentId: " ", latitude: 0, longitude: 0, accesspoints: []);
  }

  static Future<void> SetNewAccespoints(ReferencePoint referencePoint, List<WiFiAccessPoint> accespoints) async {
    for (int i = 0; i < accespoints.length; i++) {
      if (!referencePoint.accesspoints.contains(accespoints[i])) {
        AccessPointMeasurement? accessPointMeasurement =
            await AccessPointMeasurement.createAccessPointMeasurement(
                referenceId: referencePoint.documentId,
                isKnown: false,
                ssid: accespoints[i].ssid,
                bssid: accespoints[i].bssid,
                level: accespoints[i].level,
                is80211mcResponder: accespoints[i].is80211mcResponder);

        if (accessPointMeasurement != null) {
          referencePoint.accesspoints.add(AccessPointMeasurement(
              ssid: accessPointMeasurement.ssid,
              bssid: accessPointMeasurement.bssid,
              level: accessPointMeasurement.level,
              is80211mcResponder: accessPointMeasurement.is80211mcResponder,
              documentId: accessPointMeasurement.documentId,
              frequency: accespoints[i].frequency,
              capabilities: accespoints[i].capabilities,
              standard: accespoints[i].standard,
              referenceId: referencePoint.documentId, isKnown: false));
        }

      }
    }
    //print("accesspoints are points is created");
  }

  static void exceute() {
    if (wifiLayer != null) {
      docidNearestRef(wifiLayer!.referencePoints, Posi(x: 0, y: 0));
    }
  }

  static String docidNearestRef(List<ReferencePoint> ref, Posi posi) {
    final tree = RBushBase<ReferencePoint>(
        maxEntries: ref.length,
        toBBox: (item) => RBushBox(
            maxX: item.longitude,
            minX: item.longitude,
            maxY: item.latitude,
            minY: item.latitude),
        getMinX: (item) => item.longitude,
        getMinY: (item) => item.latitude);

    tree.load(ref);
    String docidRef = tree.knn(posi.x, posi.y, 1)[0].documentId;
    return docidRef;
  }

}

class PossiblePosition {
  final int avgError;
  final String docId;
  final int overlap;
  final int nonoverlap;

  PossiblePosition(
      {required this.avgError,
      required this.docId,
      required this.overlap,
      required this.nonoverlap});

  @override
  String toString() {
    // TODO: implement toString
    return "[avgEr: $avgError; overlap: $overlap; non oL: $nonoverlap]";
  }
}
