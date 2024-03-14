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
    if( json["accesspointsNew"]!= null){
      for(int i = 0; i < json["accesspointsNew"].length; i++){
        AccessPointMeasurement? accessPointMeasurement = await AccessPointMeasurement.getAccessPointMeasurement(json["accesspointsNew"][i]);
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

  static ReferencePoint fromJsonfast(Map<String, dynamic> json, String docId, List<AccessPointMeasurement> listAccessPoints){

    List<AccessPointMeasurement> res = [];
    for(int i = 0; i < listAccessPoints.length; i++){
      if(listAccessPoints[i].referenceId == docId){
        res.add(listAccessPoints[i]);
      }
    }

    return ReferencePoint(
      documentId: docId,
      latitude: json["latitutude"],
      longitude: json["longitude"],
      accesspoints: res,
      accesspointsNew: [],
    );
  }

  static Future<ReferencePoint?> createReferencePoint({required double latitude,required double longitude, required List<AccessPointMeasurement> accesspoints, required List<AccessPointMeasurement> accesspointsNew})async{
    try{
      Document document= await Runtime.database.createDocument(
          databaseId: databaseIdWifi,
          collectionId: collectionIDReferencePoints,
          documentId: "unique()",
          data: {
            "latitutude" : latitude, "longitude" : longitude,
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
      print(e.toString() +"docId not found" + docId);
      return null;
    }
  }



  Future<void> calculateAccespoints() async {
     accesspointsNew.sort((a, b) {
       return a.bssid.compareTo(b.bssid);
     },);
     AccessPointMeasurement a1 = accesspointsNew[0];
     int occurence =1;
     int avg = a1.level;
     for(int i = 1; i < accesspointsNew.length; i++){
       if(a1.bssid == accesspointsNew[i].bssid){
         occurence++;
         avg = avg + accesspointsNew[i].level;
         await accesspointsNew[i].deleteAccessPointMeasurement().then((value) => print("deleted"));
       }else{
         print("addded 1");
         a1.level = (avg/ occurence).round();
         a1.updateAccessPointMeasurement();
         accesspoints.add(a1);
         avg = accesspointsNew[i].level;
         a1 = accesspointsNew[i];
         occurence = 1;
       }
     }

     //TODO change the update stuff
     await updateReferencePoint().then((value) => print("updated"));
     print(accesspoints.length);
     for(int i = 0; i < accesspoints.length; i++){
       print(accesspoints[i].bssid +" "+ accesspoints[i].level.toString());
     }
     print("if nothing error ${accesspoints.length}");
  }
}
