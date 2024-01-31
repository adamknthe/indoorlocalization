import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:indoornavigation/constants/constants.dart';
import 'package:indoornavigation/constants/runtime.dart';
import 'package:wifi_scan/wifi_scan.dart';

class Wifi{

  List<WiFiAccessPoint> accessPoints = [];
  StreamSubscription<List<WiFiAccessPoint>>? subscription;
  bool shouldCheckCan = true;

  bool get isStreaming => subscription != null;

  void setupStream(){
    subscription = WiFiScan.instance.onScannedResultsAvailable.listen((result) {
      print(result.length);
      for(int i = 0; i < result.length; i++){
        if(result.elementAt(i).timestamp != null){
          int time = result.elementAt(i).timestamp as int;
          print(DateTime.fromMillisecondsSinceEpoch(time));
          print(result.elementAt(i).is80211mcResponder);
        }
      }
    });
  }

  Future<void> startScan() async {
    // check if "can" startScan
    if (shouldCheckCan) {
      // check if can-startScan
      final can = await WiFiScan.instance.canStartScan();
      // if can-not, then show error
      if (can != CanStartScan.yes) {
        return;
      }
    }

    // call startScan API
    await WiFiScan.instance.startScan();

    // reset access points.
    accessPoints = [];
  }

  Future<bool> canGetScannedResults() async {
    if (shouldCheckCan) {
      // check if can-getScannedResults
      final can = await WiFiScan.instance.canGetScannedResults();
      // if can-not, then show error
      if (can != CanGetScannedResults.yes) {
        accessPoints = <WiFiAccessPoint>[];
        return false;
      }
    }
    return true;
  }

  void stopListeningToScanResults() {
    subscription?.cancel();
  }

  Future<void> startListeningToScanResults() async {
    if (await canGetScannedResults()) {
      subscription = WiFiScan.instance.onScannedResultsAvailable
          .listen((result){
              accessPoints.addAll(result);
              print(result.length);
              for(int i = 0; i < result.length; i++){
                print("bssid ${result.elementAt(i).bssid} dBm: ${result.elementAt(i).level} ${result.elementAt(i).ssid}");
              }
          }
      );

    }
  }

  @override
  String toString() {
    String output = "";

    for(int i = 0; i < accessPoints.length; i++){
     output = "${output}bssid ${accessPoints.elementAt(i).bssid}, dBm: ${accessPoints.elementAt(i).level}, ${accessPoints.elementAt(i).ssid}, ${accessPoints.elementAt(i).timestamp},";
    }
    return output;
  }

}
