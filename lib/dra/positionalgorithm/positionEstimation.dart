import 'dart:async';
import 'dart:ffi';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:indoornavigation/Util/Mercator.dart';
import 'package:indoornavigation/Util/posi.dart';
import 'package:indoornavigation/Wifi/accesspointmeasurement.dart';
import 'package:indoornavigation/Wifi/reference_point.dart';
import 'package:indoornavigation/Wifi/wifi_layer.dart';
import 'package:indoornavigation/Wifi/wifimeasurements.dart';
import 'package:indoornavigation/dra/dra.dart';
import 'package:indoornavigation/dra/my_sensors.dart';
import 'package:indoornavigation/dra/step_detection.dart';
import 'package:rbush/rbush.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../peak.dart';

class PositionEstimation {
  static Posi estimatedPosi = Posi(x: 0, y: 0);

  static List<Position> _listPosition = [];
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

  static Future<void> startTimer() async {
    updateTick = Timer.periodic(Duration(seconds: 2), (timer) {
      getEverything();
      print("timer runing");
      if (wifiLayer != null) {
        print(wifiLayer!.Buildingname);
        print("Wifi measured: ${WifiMeasurements.count}");
        print(
            "Wifi measured # of measured : ${WifiMeasurements.accespoints.length}");
        searchWifiFix(wifiLayer!, measurement);
      }
    });
  }

  static void getEverything() {
    peaks = StepDetection.peaksAndValey;
    steps = StepDetection.steps;
    gpsposition = MySensors.positionGps;
    draposition = MySensors.userPosition;
    wifiLayer = WifiLayerGetter.wifiLayer;
    measurement = WifiMeasurements.accespoints;
    walkedDistance = DRA.walkedDistance;
    positionsWithoutFix = DRA.positionsWithoutFix;
  }

  static void searchWifiFix(
      WifiLayer wifiLayer, List<WiFiAccessPoint> accespoints) {
    print(accespoints.length);
    if (accespoints.length < 1) {
      return;
    }
    List<PossiblePosition> pos =
        getPossible(wifiLayer.referencePoints, accespoints);

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
    if(pos.length > 0){
      ReferencePoint ref = wifiLayer.referencePoints
          .firstWhere((element) => element.documentId == pos[0].docId);
      estimatedPosi = Posi(x: ref.longitude, y: ref.latitude);
    }

  }

  static List<PossiblePosition> getPossible(
      List<ReferencePoint> ref, List<WiFiAccessPoint> accespoints) {
    List<PossiblePosition> res = [];
    ref.forEach((reference) {
      int allError = 0;
      int countoverlap = 0;
      reference.accesspoints.forEach((ap) {
        accespoints.forEach((apm) {
          if (ap.bssid == apm.bssid) {
            int error = sqrt(pow((ap.level - apm.level), 2)).round();
            countoverlap++;
            allError = allError + error;
          }
        });
      });
      if(countoverlap != 0) {
        res.add(PossiblePosition(
            avgError: (allError / countoverlap).round(),
            docId: reference.documentId,
            overlap: countoverlap,
            nonoverlap: (accespoints.length - countoverlap))
        );
      }
    });
    res.sort(
      (a, b) {
        int x = a.avgError.compareTo(b.avgError);
        if (x == 0) {
          return -a.overlap.compareTo(b.overlap);
        }
        return x;
      },
    );
    return res;
  }

  static void getPositionWithoutWifi() {
    if (gpsposition.latitude == 0 && steps == 0) {
      return;
    }
    if (gpsposition.timestamp.isAfter(draposition.timestamp)) {
      if (gpsposition.accuracy < 7) {}
    }
  }

  static ReferencePoint matchPosToRef() {
    return ReferencePoint(
        documentId: " ", latitude: 0, longitude: 0, accesspoints: []);
  }

  static Future<void> SetNewAccespoints(
      ReferencePoint referencePoint, List<WiFiAccessPoint> accespoints) async {
    for (int i = 0; i < accespoints.length; i++) {
      if (!referencePoint.accesspoints.contains(accespoints[i])) {
        AccessPointMeasurement? accessPointMeasurement =
            await AccessPointMeasurement.createAccessPointMeasurement(
                ssid: accespoints[i].ssid,
                bssid: accespoints[i].bssid,
                level: accespoints[i].level,
                is80211mcResponder: accespoints[i].is80211mcResponder);
        if (accessPointMeasurement != null) {
          referencePoint.accesspointsNew.add(AccessPointMeasurement(
              ssid: accessPointMeasurement.ssid,
              bssid: accessPointMeasurement.bssid,
              level: accessPointMeasurement.level,
              is80211mcResponder: accessPointMeasurement.is80211mcResponder,
              documentId: accessPointMeasurement.documentId,
              frequency: accespoints[i].frequency,
              capabilities: accespoints[i].capabilities,
              standard: accespoints[i].standard));
        }
      }
    }
    referencePoint.updateReferencePoint();
  }

  static void exceute(){
    if(wifiLayer != null){
      docidNearestRef(wifiLayer!.referencePoints, Posi(x: 0,y: 0));
    }
  }


  static String docidNearestRef(List<ReferencePoint> ref, Posi posi) {
    double xm = Mercator.x2lng(1);
    double ym = Mercator.y2lat(1);
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
    String docidRef = tree.knn(posi.x , posi.y, 1)[0].documentId;
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
}
