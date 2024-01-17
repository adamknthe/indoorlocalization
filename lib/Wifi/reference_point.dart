import 'package:wifi_scan/wifi_scan.dart';

class ReferencePoint{
  final double latitude;
  final double longitude;
  final List<WiFiAccessPoint> accesspoints;
  final List<WiFiAccessPoint>? accesspointsNew;
  final List<Posi> neighborPosition;
  final bool border;


  ReferencePoint( {required this.latitude, required this.longitude, required this.accesspoints, this.accesspointsNew, required this.neighborPosition, required this.border});
}

class Posi{
  double x;
  double y;

  Posi({required this.x, required this.y});
}


