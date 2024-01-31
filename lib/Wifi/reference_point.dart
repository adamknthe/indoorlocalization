import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../Util/posi.dart';
import '../constants/constants.dart';
import '../constants/runtime.dart';
import 'accesspointmeasurement.dart';

class ReferencePoint{
  final String documentId;
  final double latitude;
  final double longitude;
  final List<AccessPointMeasurement> accesspoints;
  final List<AccessPointMeasurement> accesspointsNew;
  final List<Posi>? neighborPosition;


  ReferencePoint( {required this.documentId,required this.latitude, required this.longitude, required this.accesspoints, this.accesspointsNew = const[], this.neighborPosition });

  Map<String, dynamic> toJson(){
    return{
      "latitutude" : latitude,
      "longitude" : longitude,
      "accespoints" : List.generate(accesspoints.length, (int index) {
        return accesspoints[index].documentId;
      }),
      "accesspointsNew" : List.generate(accesspointsNew.length, (int index) {
        return accesspointsNew[index].documentId;
      }),
    };
  }

  static Future<ReferencePoint> fromJson(Map<String, dynamic> json, String docId) async{
    List<AccessPointMeasurement> res = [];
    for(int i = 0; i < json["accespoints"].length; i++){
      AccessPointMeasurement? accessPointMeasurement = await AccessPointMeasurement.getAccessPointMeasurement(json["accespoints"][i]);
      if(accessPointMeasurement != null){
        res.add(accessPointMeasurement);
      }
    }
    List<AccessPointMeasurement> res2 = [];
    if( json["accespointsNew"]!= null){
      for(int i = 0; i < json["accespointsNew"].length; i++){
        AccessPointMeasurement? accessPointMeasurement = await AccessPointMeasurement.getAccessPointMeasurement(json["accespoints"][i]);
        if(accessPointMeasurement != null){
          res2.add(accessPointMeasurement);
        }
      }
    }

    return ReferencePoint(
        documentId: docId,
        latitude: json["latitutude"],
        longitude: json["longitude"],
        accesspoints: res,
        accesspointsNew: res2
    );
  }

  static Future<ReferencePoint?> createReferencePoint({required double latitude,required double longitude, required List<AccessPointMeasurement> accesspoints, required List<AccessPointMeasurement> accesspointsNew})async{
    try{
      print("set reference point");
      Document document= await Runtime.database.createDocument(
          databaseId: databaseIdWifi,
          collectionId: collectionIDReferencePoints,
          documentId: "unique()",
          data: {
            "latitutude" : latitude,
            "longitude" : longitude,
            "accespoints" : List.generate(accesspoints.length, (int index) {
              return accesspoints[index].documentId;
            }),
            "accesspointsNew" : List.generate(accesspointsNew.length, (int index) {
              return accesspointsNew[index].documentId;
            }),
          },
          permissions: [
            Permission.delete(Role.any()),
            Permission.read(Role.any()),
            Permission.write(Role.any()),
            Permission.update(Role.any()),
          ]
      );

      return ReferencePoint.fromJson(document.data, document.$id);
    }catch(e){
      print(e);
      return null;
    }

  }

  Future<bool> deleteReferencePoint() async{
    try {
      for(int i = 0;i < accesspoints.length;i++){
        await accesspoints[i].deleteAccessPointMeasurement();
      }
      await Runtime.database.deleteDocument(
          databaseId: databaseIdWifi,
          collectionId: collectionIDReferencePoints,
          documentId: documentId
      );
      return true;
    }catch(e){
      print(e);
      return false;
    }
  }

  Future<bool> updateReferencePoint()async{
    try{
      await Runtime.database.updateDocument(
          databaseId: databaseIdWifi,
          collectionId: collectionIDReferencePoints,
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

  static Future<ReferencePoint?> getReferencePoint(String docId) async {
    try{
      Document result = await Runtime.database.getDocument(
          databaseId: databaseIdWifi,
          collectionId: collectionIDReferencePoints,
          documentId: docId);
      return fromJson(result.data,docId);
    }catch(e){
      print(e);
      return null;
    }
  }
}
