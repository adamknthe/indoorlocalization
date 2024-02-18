import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:wifi_scan/wifi_scan.dart';

import '../constants/Constants.dart';
import '../constants/runtime.dart';

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
      print(e.toString() + " accesspointdocId not found:$docId");
      return null;
    }
  }
}