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

  Future<bool> canGetScannedResults(BuildContext context) async {
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

  Future<void> startListeningToScanResults(BuildContext context) async {
    if (await canGetScannedResults(context)) {
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

class AccessPointMeasurement extends WiFiAccessPoint{
  final documentId;
  AccessPointMeasurement({required super.ssid, required super.bssid, required super.level, required super.frequency, required super.capabilities, required super.standard, required super.is80211mcResponder , required this.documentId });

  Map<String, dynamic> toJson(){
    return{
      "bssid" : bssid,
      "level" : level,
      "ssid"  : ssid,
      "is80211mcResponder" : is80211mcResponder
    };
  }

  static AccessPointMeasurement fromJson(Map<String, dynamic>json, String docId){
    return AccessPointMeasurement(
        documentId: docId,
        bssid : json["bssid"],
        ssid : json["ssid"],
        level : json["level"],
        capabilities : "",
        frequency : 0,
        standard : WiFiStandards.unkown,
        is80211mcResponder : json["is80211mcResponder"]
    );
  }

  static Future<AccessPointMeasurement?> createAccessPointMeasurement({required String ssid, required String bssid, required int level, required bool is80211mcResponder}) async{
    try{
      Document document= await Runtime.database.createDocument(
          databaseId: databaseIdWifi,
          collectionId: collectionIDAccesPoints,
          documentId: "unique()",
          data: {
            "bssid" : bssid,
            "level" : level,
            "ssid"  : ssid,
            "is80211mcResponder" : is80211mcResponder
          },
          permissions: [
            Permission.delete(Role.any()),
            Permission.read(Role.any()),
            Permission.write(Role.any()),
            Permission.update(Role.any()),
          ]
      );
      return AccessPointMeasurement.fromJson(document.data,document.$id);
    }catch(e){
      print(e);
    }
    return null;
  }

  Future<bool> deleteAccessPointMeasurement() async{
    try {
      await Runtime.database.deleteDocument(
          databaseId: databaseIdWifi,
          collectionId: collectionIDAccesPoints,
          documentId: documentId
      );
      return true;
    }catch(e){
      print(e);
      return false;
    }
  }

  Future<bool> updateAccessPointMeasurement()async{
    try{
      await Runtime.database.updateDocument(
          databaseId: databaseIdWifi,
          collectionId: collectionIDAccesPoints,
          documentId: documentId,
          data: toJson(),
          permissions: [
            Permission.delete(Role.any()),
            Permission.read(Role.any()),
            Permission.write(Role.any()),
            Permission.update(Role.any()),
          ]
      );

      return true;
    }catch(e){
      return false;
    }
  }

  static Future<AccessPointMeasurement?> getAccessPointMeasurement(String docId) async {
    try{
      Document result = await Runtime.database.getDocument(
          databaseId: databaseIdWifi,
          collectionId: collectionIDAccesPoints,
          documentId: docId);
      return fromJson(result.data,docId);
    }catch(e){
      print(e);
      return null;
    }
  }
}