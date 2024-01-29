import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:indoornavigation/constants/Constants.dart';


import '../constants/runtime.dart';

class MapLoader{
  String GeoJson;
  int floorNumber;
  String name;

  MapLoader({required this.name, required this.floorNumber, required this.GeoJson});

  Map<String, dynamic> toJson(){
    return{
      "floor": GeoJson,
      "name" : name,
      "floor_number" : floorNumber
    };
  }

  static MapLoader fromJson(Map<String, dynamic> json){
    return MapLoader(name: json["name"], floorNumber: json["floor_number"], GeoJson: json["floor"]);
  }

  static Future<MapLoader?> getMaploader(String buildingName, int floorLevel) async {
    try{
      DocumentList result = await Runtime.database.listDocuments(
          databaseId: databaseIdMaps,
          collectionId: "65a523837ab25ceabbba",
          queries: [
            Query.equal("name", buildingName),
            Query.equal("floor_number", floorLevel)
          ]);
      return fromJson(result.documents[0].data);
    }catch(e){
      print(e);
      return null;
    }
  }
}