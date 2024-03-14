import 'dart:async';
import 'package:flutter/material.dart';
import 'package:indoornavigation/Wifi/wifi.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WifiMeasurements{
  static Wifi wifi = Wifi();
  static bool wasScannedAfterset = false;
  static int count = 0;
  static List<WiFiAccessPoint> accespoints = [];

  static StreamController<List<WiFiAccessPoint>> controller = StreamController<List<WiFiAccessPoint>>.broadcast();

  static late Stream<List<WiFiAccessPoint>> wifiresultstream;

  static void setupWifi(BuildContext context) {
    wifiresultstream = controller.stream;
    wifi.canGetScannedResults();
    wifi.startScan();
    wifi.startListeningToScanResults().then((value) {
      wifi.subscription?.onData((value) async {
        //print(value);
        wasScannedAfterset = true;
        //for(int i = 0; i < value.length; i++){
        //  print("bssid${value.elementAt(i).bssid} dBm: ${value.elementAt(i).level}");
        //}

        count++;
        accespoints = value;
        controller.add(value);
        await Future.delayed(const Duration(seconds: 5));
        wifi.startScan();
      });
    });

    //test();
  }


}