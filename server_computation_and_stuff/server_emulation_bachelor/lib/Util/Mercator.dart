import 'dart:math';
import 'package:vector_math/vector_math.dart';
class Mercator{

  static double RADIUS = 6378137.0; /* in meters on the equator */

  /* These functions take their length parameter in meters and return an angle in degrees */

  static double y2lat(double aY) {
    return degrees(2 * atan(exp(aY/RADIUS))-pi/2);
    //return Math.toDegrees(Math.atan(Math.exp(aY / RADIUS)) * 2 - pi/2);
  }

  static double x2lng(double aX) {
    return degrees(aX / RADIUS);
  }
  /* These functions take their angle parameter in degrees and return a length in meters */

  static double lat2y(double aLat) {
    return log(tan(pi / 4 + radians(aLat) / 2)) * RADIUS;
  }

  static double lon2x(double aLong) {
    return radians(aLong) * RADIUS;
  }

}