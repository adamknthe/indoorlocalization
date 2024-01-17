import 'dart:core';

import 'dart:math';

int timesaver = DateTime.now().millisecondsSinceEpoch;

class Calculations {
  double alpha = 0.98; // Weighting factor for the complementary filter
  //double dt = 0.01;    // Time interval between sensor readings

  //double gyro_x,  // Angular velocity around x-axis
  //double gyro_y,  // Angular velocity around y-axis
  //double gyro_z,  // Angular velocity around z-axis

  //double acce_x,  // Linear acceleration along x-axis
  //double acce_y,  // Linear acceleration along y-axis
  //double acce_z,  // Linear acceleration along z-axis

  //double magn_x,  // Magnetic field measurement along x-axis
  //double magn_y,  // Magnetic field measurement along y-axis
  //double magn_z,  // Magnetic field measurement along z-axis

  double pitch = 0.0;
  double roll = 0.0;
  double yaw = 0.0;
  double previous_yaw = 0.0;
  double final_yaw = 0.0;

  static double thetaFilterold = 0;
  static double phiFilterOld = 0;
  static double thetaG = 0;
  static double phiG = 0;
  static double phi = 0;
  static double theta = 0;

  double updateOrientation(
      double gyro_x,
      double gyro_y,
      double gyro_z,
      double acce_x,
      double acce_y,
      double acce_z,
      double magn_x,
      double magn_y,
      double magn_z,
      double dt) {
    // Calculate pitch and roll from accelerometer data
    pitch = atan2(acce_x, sqrt(acce_y * acce_y + acce_z * acce_z));
    roll = atan2(-acce_y, -acce_z);

    // Integrate gyro data to update pitch and roll
    pitch += gyro_x * dt;
    roll += gyro_y * dt;

    // Calculate yaw from magnetometer data
    yaw = atan2(
        magn_y * cos(roll) - magn_z * sin(roll),
        magn_x * cos(pitch) +
            magn_y * sin(roll) * sin(pitch) +
            magn_z * cos(roll) * sin(pitch));

    // Apply complementary filter to combine accelerometer and gyro data for yaw
    double delta_yaw = gyro_z * dt;
    final_yaw = alpha * (yaw + delta_yaw) + (1 - alpha) * previous_yaw;
    previous_yaw = final_yaw;

    print("before");
    print(final_yaw);
    // Convert the heading to degrees from 0 to 360
    final_yaw = (final_yaw * 180.0 / pi + 360);
    print("after");

    print(final_yaw);
    return final_yaw;
  }

  void updatePosition(
    int heading,
    double acc_x,
    double acc_y,
    double acc_z,
  ) {}

  int updateHeading(
      double gyro_x,
      double gyro_y,
      double gyro_z,
      double acce_x,
      double acce_y,
      double acce_z,
      double magn_x,
      double magn_y,
      double magn_z,
      int t) {
    double dt = (t - timesaver) / 1000.0;
    timesaver = t;
    double thetaAcc = atan2(acce_y / 9.8, acce_z / 9.8) / 2 / pi * 360;
    double phiAcc = atan2(acce_x / 9.8, acce_z / 9.8) / 2 / pi * 360;
    double phiFilterNew = .9 * phiFilterOld + .1 * phiAcc;
    double thetaFilterNew = .9 * thetaFilterold + .1 * thetaAcc;
    thetaG = thetaG +
        (gyro_x / 2 / pi * 360) *
            dt; //TODO dokument why Rad to Deg there was an error
    phiG = phiG +
        (gyro_y / 2 / pi * 360) *
            dt; //TODO dokument why Rad to Deg there was an error

    theta =
        (theta + (gyro_x / 2 / pi * 360) * dt) * 0.95 + thetaFilterNew * 0.05;
    phi = (phi + (gyro_y / 2 / pi * 360) * dt) * 0.95 + phiFilterNew * 0.05;

    //print("theta: $thetaAcc, phi: $phiAcc");
    phiFilterOld = phiFilterNew;
    thetaFilterold = thetaFilterNew;

    double phiRad = phi / 360 * (2 * 3.14);
    double thetaRad = theta / 360 * (2 * 3.14);
    //double psi = atan2(magn_y, magn_x)/2/pi*360;

    //print("phirad: $phi, thetarad: $theta");

    double Ym = magn_y * cos(thetaRad) +
        magn_z *
            sin(thetaRad); //magn_y*cos(thetaRad)-magn_x*sin(phiRad)*sin(thetaRad)+magn_z*cos(phiRad)*sin(thetaRad);
    double Xm = magn_y * sin(phiRad) * sin(thetaRad) +
        magn_x * cos(phiRad) -
        magn_z *
            sin(phiRad) *
            cos(thetaRad); //magn_x*cos(phiRad)+magn_z*sin(phiRad);

    //print("magn_x: $magn_x, magn_y: $magn_y, magn_z: $magn_z, $Xm, $Ym");

    double psi = atan2(Ym, Xm) / 2 / pi * 360;
    //print("psi in 2d: ${atan2(magn_y, magn_x)/2/pi*360}");

    //print("psi in 3d space ${((psi+360)%360).round()}");
    return ((psi + 360) % 360).round();
  }
}

class StepDetectionByMe {
  int windowsSize = 50;

  ///Information steps have to be inside 1 second so max peaks have limits

  static void StepDetect(List<List<double>> accValues) {
    List<double> magnitudeValue = [];
    for (int i = 0; i < accValues.length; i++) {
      magnitudeValue.add(sqrt(accValues[i][0] * accValues[i][0] +
          accValues[i][1] * accValues[i][1] +
          accValues[i][2] * accValues[i][2]));
    }
    print(magnitudeValue);
    print(findPeaks(magnitudeValue, threshold: 0.2));
  }

  static List<num> magnitudes(List<List<double>> accValues) {
    List<double> magnitudeValue = [];
    for (int i = 0; i < accValues.length; i++) {
      double magnitude = sqrt(accValues[i][0] * accValues[i][0] +
          accValues[i][1] * accValues[i][1] +
          accValues[i][2] * accValues[i][2]);
      magnitudeValue.add(magnitude);
    }
    return magnitudeValue;
  }

  static List findPeaks(List a, {double? threshold}) {
    var N = a.length - 2;
    var ix = List.empty(growable: true);
    var ax = List.empty(growable: true);

    if (threshold != null) {
      for (var i = 1; i <= N; i++) {
        if (a[i - 1] <= a[i] && a[i] >= a[i + 1] && a[i] >= threshold) {
          ix.add(i.toDouble());
          ax.add(a[i]);
        }
      }
    } else {
      for (var i = 1; i <= N; i++) {
        if (a[i - 1] <= a[i] && a[i] >= a[i + 1]) {
          ix.add(i.toDouble());
          ax.add(a[i]);
        }
      }
    }
    return [ix, ax];
  }

  static void Stepdetect(List<num> magnitudes, double threshold){

  }
}

class SmoothedZScore {
  int lag = 50;
  num threshold = 3.5;
  num influence = 0.3;

  num sum(List<num> a) {
    num s = 0;
    for (int i = 0; i < a.length; i++) s += a[i];
    return s;
  }

  num mean(List<num> a) {
    return sum(a) / a.length;
  }

  num stddev(List<num> arr) {
    num arrMean = mean(arr);
    num dev = 0;
    for (int i = 0; i < arr.length; i++)
      dev += (arr[i] - arrMean) * (arr[i] - arrMean);
    return sqrt(dev / arr.length);
  }

  List<int> smoothedZScore(List<num> y) {
    if (y.length < lag + 2) {
      throw 'y data array too short($y.length) for given lag of $lag';
    }

    // init variables
    List<int> signals = List.filled(y.length, 0);
    List<num> filteredY = List<num>.from(y);
    List<num> leadIn = y.sublist(0, lag);

    var avgFilter = List<num>.filled(y.length, 0);
    var stdFilter = List<num>.filled(y.length, 0);
    avgFilter[lag - 1] = mean(leadIn);
    stdFilter[lag - 1] = stddev(leadIn);

    for (var i = lag; i < y.length; i++) {
      if ((y[i] - avgFilter[i - 1]).abs() > (threshold * stdFilter[i - 1])) {
        signals[i] = y[i] > avgFilter[i - 1] ? 1 : -1;
        // make influence lower
        filteredY[i] = influence * y[i] + (1 - influence) * filteredY[i - 1];
      } else {
        signals[i] = 0; // no signal
        filteredY[i] = y[i];
      }

      // adjust the filters
      List<num> yLag = filteredY.sublist(i - lag, i);
      avgFilter[i] = mean(yLag);
      stdFilter[i] = stddev(yLag);
    }

    return signals;
  }
}
