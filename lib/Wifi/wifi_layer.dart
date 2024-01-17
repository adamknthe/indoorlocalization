import 'dart:core';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:geolocator/geolocator.dart';
import 'package:indoornavigation/Util/Mercator.dart';
import 'package:indoornavigation/Wifi/reference_point.dart';
import 'package:maps_toolkit/maps_toolkit.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WifiLayer{
  final Position rootPosition;
  final List<ReferencePoint> referencePoints;
  final String Buildingname;
  final int floorLevel;
  final double squareSizeInMeters;
  final String GeojsonOfOutline;
  static double x = Mercator.x2lng(1);
  static double y = Mercator.y2lat(1);

  WifiLayer(this.referencePoints,{required this.rootPosition, required this.Buildingname, required this.floorLevel, required this.GeojsonOfOutline ,this.squareSizeInMeters = 1.0});


  static bool IsInsideOfBuilding(String geojson, Position position){
    return PolygonUtil.containsLocation(LatLng(position.latitude, position.longitude),getListFromPolygonOutline(geojson),true);
  }

  static List<LatLng> getListFromPolygonOutline(String json) {
    List<LatLng> floor= [];
    GeoJSON geoJSON =  GeoJSON.fromJSON(json);
    List<List<double>> coordinates =  geoJSON.toMap()["features"][0]["geometry"]["coordinates"][0];
    int i = 0;
    while(coordinates.length > i ){
      floor.add(LatLng(Mercator.y2lat(coordinates[i][1]), Mercator.x2lng(coordinates[i][0])));
      i++;
    }
    return floor;
  }

  static Position atReferencePoint(WifiLayer wifiLayer, List<WiFiAccessPoint> accessPoints){
    ///TODO implements search for wifi points
    return wifiLayer.rootPosition;
  }

  void createReferencePoints(WifiLayer wifiLayer){
    Position root = wifiLayer.rootPosition;
    Posi rootPosi = Posi(x: root.longitude, y: root.latitude);
    ReferencePoint rootreferencePoint = ReferencePoint(latitude: root.latitude, longitude: root.longitude, accesspoints: <WiFiAccessPoint>[], neighborPosition: createPosis(rootPosi));
    //TODO write instantiate and other algorithm for when loading from server




  }
  
  List<Posi> createPosis (Posi posi){
    List<Posi> result = [];
    result.add(Posi(x: posi.x+x, y: y));
    result.add(Posi(x: posi.x-x, y: y));
    result.add(Posi(x: posi.x, y: y+y));
    result.add(Posi(x: posi.x, y: y-y));
    return result;
  }

}