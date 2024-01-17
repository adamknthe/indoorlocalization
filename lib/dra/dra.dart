
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:indoornavigation/Util/Mercator.dart';
import 'package:vector_math/vector_math.dart';
import 'package:sensors_plus/sensors_plus.dart';

class DRA{

  static int positionsWithoutFix = 0;
  static double walkedDistance = 0.0;

  static Position nextPosition(double heading, double stepLength, Position oldPosition){
    double latNew = oldPosition.latitude + Mercator.y2lat(stepLength) * cos(radians(heading));
    double longNew = oldPosition.longitude + Mercator.x2lng(stepLength) * sin(radians(heading));


    walkedDistance = walkedDistance + stepLength;
    positionsWithoutFix++;
    print("lat: $latNew, long: $longNew");
    return Position(longitude: longNew, latitude: latNew, timestamp: DateTime.now(),accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: heading, headingAccuracy: 0, speed: 0, speedAccuracy: 0);
  }
}
