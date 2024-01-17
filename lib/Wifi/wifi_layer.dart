import 'dart:core';
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
    
    print(PolygonUtil.containsLocation(LatLng(position.latitude, position.longitude),getListfromPolygon(geojson, "building_outline"),true));
    return false;

  }

  static List<LatLng> getListfromPolygon(String geojson,String type,[int? id]){
    //TODO implement extraktion from json
    List<LatLng> floor= [
      LatLng( 52.517143764464635,13.32346165693886),
      LatLng(52.51628804607495, 13.322776364805947),
      LatLng(52.516086758870046, 13.323410768910065),
      LatLng(52.51694351340379, 13.324082490900508),
    ];
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