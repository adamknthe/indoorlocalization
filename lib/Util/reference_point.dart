import 'package:wifi_scan/wifi_scan.dart';

class ReferencePoint{
  final double latitude;
  final double longitude;
  final List<WiFiAccessPoint> accesspoints;

  ReferencePoint({required this.latitude, required this.longitude, required this.accesspoints});
}

