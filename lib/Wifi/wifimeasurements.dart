import 'package:flutter/material.dart';
import 'package:indoornavigation/Wifi/reference_point.dart';
import 'package:indoornavigation/Wifi/wifi.dart';

class WifiMeasurements{
  static Wifi wifi = Wifi();
  static bool wasScannedAfterset = false;
  static int count = 0;

  static void SetupWifi(BuildContext context) {
    print("Setupwifi");
    wifi.canGetScannedResults();
    wifi.startScan();
    wifi.startListeningToScanResults().then((value) {
      print("wifi");
      wifi.subscription?.onData((value) async {
        print(value);
        wasScannedAfterset = true;
        //for(int i = 0; i < value.length; i++){
        //  print("bssid${value.elementAt(i).bssid} dBm: ${value.elementAt(i).level}");
        //}

        count++;

        wifi.accessPoints = value;

        wifi.startScan();
      });
    });

    //test();
  }
}