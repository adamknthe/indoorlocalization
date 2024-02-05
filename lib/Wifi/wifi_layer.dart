import 'dart:core';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:indoornavigation/Util/Mercator.dart';
import 'package:indoornavigation/Wifi/reference_point.dart';
import 'package:indoornavigation/constants/constants.dart';
import 'package:indoornavigation/constants/runtime.dart';
import 'package:maps_toolkit/maps_toolkit.dart';

import '../Util/posi.dart';


class WifiLayer {
  List<ReferencePoint> referencePoints;
  String Buildingname;
  int floorLevel;
  String GeojsonOfOutline;

  WifiLayer(
      {required this.referencePoints,
      required this.Buildingname,
      required this.floorLevel,
      required this.GeojsonOfOutline});

  static String jsonforall = "";
  static double x = Mercator.x2lng(2);
  static double y = Mercator.y2lat(2);

  static void getJsontoFunktionAndCall(String json) {
    jsonforall = json;
  }

  static bool isInsideOfBuilding(String geojson, Posi position) {
    return PolygonUtil.containsLocation(LatLng(position.y, position.x),
        getListFromPolygonOutline(geojson), true);
  }

  static bool isInsideOfBuildingFromList(List<LatLng> latlng, Posi position) {
    return PolygonUtil.containsLocation(
        LatLng(position.y, position.x), latlng, true);
  }

  static List<LatLng> getListFromPolygonOutline(String json) {
    List<LatLng> floor = [];
    GeoJSON geoJSON = GeoJSON.fromJSON(json);
    List<List<double>> coordinates =
        geoJSON.toMap()["features"][0]["geometry"]["coordinates"][0];
    int i = 0;
    while (coordinates.length > i) {
      floor.add(LatLng(Mercator.y2lat(coordinates[i][1]),
          Mercator.x2lng(coordinates[i][0])));
      i++;
    }
    return floor;
  }

  ///TODO implements search for wifi points

  static Future<void> createReferencePoints(WifiLayer wifiLayer) async {
    Posi root =
        getCenter(getListFromPolygonOutline(wifiLayer.GeojsonOfOutline));
    wifiLayer.referencePoints.addAll(generateMatrix(root, 500));
  }

  static List<ReferencePoint> generateMatrix(Posi center, int gridSize) {
    List<ReferencePoint> res = [];
    //instantiate matrix
    List<List<Posi>> matrixPosi = [[]];
    int centerxy = (gridSize / 2).round();
    for (int i = 0; i < gridSize; i++) {
      matrixPosi.add(<Posi>[]);
      for (int j = 0; j < gridSize; j++) {
        matrixPosi[i].add(Posi(x: 0, y: 0));
      }
    }
    print("init matrix done");
    matrixPosi[centerxy][centerxy] = Posi(x: center.x, y: center.y);
    //set real values
    // up Right;
    for (int i = centerxy; i < gridSize; i++) {
      for (int j = centerxy; j < gridSize; j++) {
        matrixPosi[i][j] = Posi(
            x: (center.x + x * (i - centerxy)),
            y: center.y + y * (j - centerxy));
      }
    }
    // down rigth
    for (int i = centerxy; i > 0; i--) {
      for (int j = centerxy; j < gridSize; j++) {
        matrixPosi[i][j] = Posi(
            x: (center.x + x * (i - centerxy)),
            y: center.y + y * (j - centerxy));
      }
    }
    //top left
    for (int i = centerxy; i < gridSize; i++) {
      for (int j = centerxy; j > 0; j--) {
        matrixPosi[i][j] = Posi(
            x: (center.x + x * (i - centerxy)),
            y: center.y + y * (j - centerxy));
      }
    }
    //down left
    for (int i = centerxy; i > 0; i--) {
      for (int j = centerxy; j > 0; j--) {
        matrixPosi[i][j] = Posi(
            x: (center.x + x * (i - centerxy)),
            y: center.y + y * (j - centerxy));
      }
    }
    print("set squares done");
    List<LatLng> latlng = getListFromPolygonOutline(jsonforall);
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (isInsideOfBuildingFromList(latlng, matrixPosi[i][j])) {
          ReferencePoint referencePoint = ReferencePoint(
              latitude: matrixPosi[i][j].y,
              longitude: matrixPosi[i][j].x,
              accesspoints: [],
              accesspointsNew: [],
              documentId: "");
          res.add(referencePoint);
        }
      }
    }
    print("alldone");
    print(res.length);
    return res;
  }

  static Posi getCenter(List<LatLng> listPolygon) {
    double x1 = 0, x2 = 0;
    double y1 = 0, y2 = 0;

    for (int i = 0; i < listPolygon.length; i++) {
      LatLng p = listPolygon[i];
      x1 = p.longitude;
      x2 = p.longitude;
      y1 = p.latitude;
      y2 = p.latitude;
      for (int j = 1; j < listPolygon.length; j++) {
        double p2x = listPolygon[j].longitude;
        double p2y = listPolygon[j].latitude;
        if (x1 > p2x) {
          x1 = p2x;
        }
        if (x2 < p2x) {
          x2 = p2x;
        }
        if (y1 > p2y) {
          y1 = p2y;
        }
        if (y2 < p2y) {
          y2 = p2y;
        }
      }
    }
    return Posi(y: (y1 + ((y2 - y1) / 2)), x: (x1 + ((x2 - x1) / 2)));
  }

  Future<bool> createWifiLayer() async {
    print("create wifiLayer");
    List<ReferencePoint> withId = [];
    try {
      print(referencePoints.length);
      for (int i = 0; i < referencePoints.length; i++) {
        ReferencePoint? ref = await ReferencePoint.createReferencePoint(
            latitude: referencePoints[i].latitude,
            longitude: referencePoints[i].longitude,
            accesspoints: referencePoints[i].accesspoints,
            accesspointsNew: referencePoints[i].accesspointsNew);
        await Future.delayed(Duration(milliseconds: 1000));
        if (ref != null) {
          withId.add(ref);
          print(ref.documentId);
        }
      }
      referencePoints = withId;
      await Runtime.database.createDocument(
          databaseId: databaseIdWifi,
          collectionId: collectionIDMar,
          documentId: "unique()",
          data: toJson());

      return true;
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "floor": floorLevel,
      "name": Buildingname,
      "GeoJsonOutline": GeojsonOfOutline,
      "ReferencePoints": List.generate(referencePoints.length, (int index) {
        return referencePoints[index].documentId;
      })
    };
  }

  static Future<WifiLayer> fromJson(Map<String, dynamic> json) async {
    //TODO Speedup!!
    List<ReferencePoint> res = [];
    DocumentList list = await Runtime.database.listDocuments(databaseId: databaseIdWifi, collectionId: collectionIDReferencePoints);
    for (int i = 0; i < json["ReferencePoints"].length; i++) {
      ReferencePoint? referencePoint = await ReferencePoint.getReferencePoint(json["ReferencePoints"][i]);

      if (referencePoint != null) {
        res.add(referencePoint);
      }
    }

    return WifiLayer(
      referencePoints: res,
      Buildingname: json["name"],
      floorLevel: json["floor"],
      GeojsonOfOutline: json["GeoJsonOutline"],
    );
  }

  static Future<WifiLayer?> getWifiLayer(String building, int floor) async {
    try {
      DocumentList result = await Runtime.database.listDocuments(
          databaseId: databaseIdWifi,
          collectionId: collectionIDMar,
          queries: [
            Query.equal("name", building),
            Query.equal("floor", floor)
          ]);
      return fromJson(result.documents[0].data);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<bool> deleteWifiLayer(String documentId) async {
    try {
      for (int i = 0; i < referencePoints.length; i++) {
        await referencePoints[i].deleteReferencePoint();
      }
      await Runtime.database.deleteDocument(
          databaseId: databaseIdWifi,
          collectionId: collectionIDMar,
          documentId: documentId);
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> updateWifiLayer(String documentId) async {
    try {
      await Runtime.database.updateDocument(
          databaseId: databaseIdWifi,
          collectionId: collectionIDMar,
          documentId: documentId,
          data: toJson(),
          permissions: [
            Permission.delete(Role.any()),
            Permission.read(Role.any()),
            Permission.write(Role.any()),
            Permission.update(Role.any()),
          ]);

      return true;
    } catch (e) {
      return false;
    }
  }

  void updateAllReferencePoints()
}

class WifiLayerGetter{
  static WifiLayer? wifiLayer;

  ///downloads wifiLayer
  static Future<bool> getFirstLayer() async{
    //String test = await DefaultAssetBundle.of(context).loadString("asset/maps/geo.json");
    //WifiLayer.getJsontoFunktionAndCall(test);
    //WifiLayer.createReferencePoints(wifiLayer);
    try{
      wifiLayer = (await WifiLayer.getWifiLayer("mar", 0))!;
      return true;
    }catch(e){
      return false;
    }

  }
}
