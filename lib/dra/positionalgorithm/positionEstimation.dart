import 'dart:async';
import 'dart:ffi';

import 'package:geolocator/geolocator.dart';
import 'package:indoornavigation/Util/posi.dart';
import 'package:indoornavigation/Wifi/reference_point.dart';
import 'package:indoornavigation/Wifi/wifi_layer.dart';
import 'package:indoornavigation/Wifi/wifimeasurements.dart';
import 'package:indoornavigation/dra/dra.dart';
import 'package:indoornavigation/dra/my_sensors.dart';
import 'package:indoornavigation/dra/step_detection.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../peak.dart';

class PositionEstimation {
  Posi estimatedPosi = Posi(x: 0, y: 0);

  static List<WiFiAccessPoint> measurement = [];
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

  static Future<void> startTimer() async {
    updateTick = Timer.periodic(Duration(seconds: 2), (timer) {
      getEverything();
      print("timer runing");
      if(wifiLayer != null){
        print(wifiLayer!.Buildingname);
        searchWifiFix(wifiLayer!, measurement);
      }
    });
  }

  static void getEverything() {
    peaks = StepDetection.peaksAndValey;
    gpsposition = MySensors.positionGps;
    draposition = MySensors.userPosition;
    wifiLayer = WifiLayerGetter.wifiLayer;
    measurement = WifiMeasurements.wifi.accessPoints;
    walkedDistance = DRA.walkedDistance;
    positionsWithoutFix = DRA.positionsWithoutFix;
  }

  static void searchWifiFix(WifiLayer wifiLayer, List<WiFiAccessPoint> accespoints) {
    print(accespoints.length);
    if(accespoints.length < 1){
      return;
    }
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
  }

  static void getPositionWithoutWifi() {
    //TODO return the best position estimation without wifi
  }

  static void SetNewAccespoints(List<WiFiAccessPoint> accespoints) {
    //TODO Udate DB
    getPositionWithoutWifi();
  }
}
