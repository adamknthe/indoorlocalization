import 'dart:math';

class StepDetection{

  static int steps = 0;
  static int peaks = 0;
  static int valeys = 0;
  static int timeframe = 100; // milliesekond until new peak could beable must be between 110ms - 400ms in order to ensure a valid step [54] A. R. Pratama, W. Widyawan, and R. Hidayat, ‘‘Smartphone-based pedestrian dead reckoning as an indoor positioning system,’’ in Proc. ICSET,  Sep. 2012, pp. 1–6
  static int maxtimebetweenPeakandValeys = 333;
  static double accZOld = 0.0;
  static double accYOld = 0.0;
  static double threshold = 1.0; ///in M/s
  static Peak peak = Peak(timeStamp: 0, acc: 0, positive: true, counted: true);
  static Peak valey = Peak(timeStamp: 0, acc: 0, positive: false, counted: true);
  static int lasttimePeak = 0;
  static List<double> accelerations=List.filled(100, 0.0);
  static List<Peak> peaksAndValey= [];
  static double overallacctoY = 0.0;
  static double topLimit = 2.5;
  static bool wasbiggerThanTopLimit = false;

  static void detectPeakAndValey (List<double> userAccValues, int timestamp){
    double uaccz = userAccValues[2];
    double actuelleAccY = accYOld * 0.8 + userAccValues[1] * .2;
    overallacctoY= overallacctoY+actuelleAccY;
    double actuelleAcc = accZOld * 0.5 + uaccz * .5;
    //print("actuell acc $actuelleAcc");
    if(actuelleAcc >= 0){
      if(actuelleAcc > accZOld ){ /// New higher value !!!
        if(actuelleAcc < topLimit) {
          if (actuelleAcc >= threshold && !wasbiggerThanTopLimit) {
            peak = Peak(timeStamp: timestamp,
                acc: actuelleAcc,
                positive: true,
                counted: false);
          }
        }else{
          wasbiggerThanTopLimit = true;
          peak.counted = true;
        }
      }
      if(valey.positive == false){
        if(valey.counted == false){
          valeys++;
          valey.counted = true;
        }
      }
    }else{
      if (actuelleAcc < 0){
        wasbiggerThanTopLimit = false;
        if(actuelleAcc < accZOld ){ /// New higher value !!!

          if(actuelleAcc <= -threshold*0.7){
            valey = Peak(timeStamp: timestamp, acc: actuelleAcc, positive: false, counted: false);
          }
        }
        if(peak.positive == true){
          if(peak.counted == false){
            if(peak.timeStamp-lasttimePeak > timeframe){
              //print("count");
              peaks++;
              steps++;
              peak.counted = true;
            }
            lasttimePeak = peak.timeStamp;
          }
        }
      }
    }
    //print("Steps $steps");
  }

  static double Magnitude(double x, double y, double z){
    return sqrt(pow(x, 2)+pow(y, 2)+pow(z, 2));
  }

  static double calculateStandardDeviation(List<double> values) {
    double mean = values.reduce((a, b) => a + b) / values.length;
    double variance = values.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }



}


class Peak{
  int timeStamp;
  double acc;
  bool positive;
  bool counted;

  Peak({
    required this.timeStamp,
    required this.acc,
    required this.positive,
    required this.counted
  });


  @override
  String toString() {
    return "$timeStamp , $acc , $positive, $counted";
  }
}

class StepDetector {
  static const int WINDOW_SIZE = 20;
  static const double VARIANCE_THRESHOLD = .5;
  static const int STEP_TIME_THRESHOLD = 200;
  static const double DERIVATIVE_THRESHOLD = 2.0;
  static const double GYROSCOPE_WEIGHT = 0.1; // Weight for gyroscope data

  static List<List<double>> accelerometerWindow = List.filled(WINDOW_SIZE, [0.0, 0.0, 0.0]);
  static List<List<double>> gyroscopeWindow = List.filled(WINDOW_SIZE, [0.0, 0.0, 0.0]);
  static int windowIndex = 0;
  static DateTime lastStepTime = DateTime.now();

  bool detectStep(List<double> accelerometerValues, List<double> gyroscopeValues, DateTime timestamp) {
    // Update the accelerometer and gyroscope windows
    accelerometerWindow[windowIndex] = accelerometerValues;
    gyroscopeWindow[windowIndex] = gyroscopeValues;
    windowIndex = (windowIndex + 1) % WINDOW_SIZE;

    //print(accelerometerWindow);

    // Apply low-pass filter to smooth accelerometer data
    List<double> smoothedAccelerometer = applyLowPassFilter(accelerometerValues);

    // Calculate the standard deviation of the smoothed accelerometer values
    double accelerationStdDev = calculateStandardDeviation(smoothedAccelerometer);

    // Adjust the threshold dynamically based on standard deviation
    double dynamicThreshold = VARIANCE_THRESHOLD * accelerationStdDev;

    // Fuse accelerometer and gyroscope data
    double fusedAcceleration = fuseData(smoothedAccelerometer, gyroscopeValues);

    // Check if the fused acceleration exceeds the dynamic threshold
    if (fusedAcceleration > dynamicThreshold) {
      print("achieved");
      // Check for distinctive pattern in acceleration derivatives
      if (isStepPattern()) {
        print("issteppatern");
        // Check if enough time has passed since the last step
        if (timestamp.difference(lastStepTime).inMilliseconds > STEP_TIME_THRESHOLD) {
          lastStepTime = timestamp;
          return true;
        }
      }
    }

    return false;
  }

  List<double> applyLowPassFilter(List<double> values) {
    // Simulate a simple low-pass filter (adjust as needed)
    double alpha = 0.2;
    for (int i = 0; i < values.length; i++) {
      accelerometerWindow[windowIndex][i] =
          alpha * values[i] + (1.0 - alpha) * accelerometerWindow[windowIndex][i];
    }
    return accelerometerWindow[windowIndex];
  }

  double calculateStandardDeviation(List<double> values) {
    double mean = values.reduce((a, b) => a + b) / values.length;
    double variance = values.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  double fuseData(List<double> accelerometer, List<double> gyroscope) {
    // Weighted fusion of accelerometer and gyroscope data
    double fusedAcceleration = (1.0 - GYROSCOPE_WEIGHT) * calculateAcceleration(accelerometer) +
        GYROSCOPE_WEIGHT * calculateAcceleration(gyroscope);
    return fusedAcceleration;
  }

  double calculateAcceleration(List<double> sensorValues) {
    double sumOfSquares = 0.0;
    for (int i = 0; i < sensorValues.length; i++) {
      sumOfSquares +=
          pow(sensorValues[i] - accelerometerWindow[windowIndex][i], 2);
    }
    return sqrt(sumOfSquares);
  }

  bool isStepPattern() {
    // Calculate acceleration derivatives
    List<double> accelerationDerivatives = [];
    for (int i = 1; i < WINDOW_SIZE; i++) {
      accelerationDerivatives.add(calculateAcceleration(accelerometerWindow[i]) -
          calculateAcceleration(accelerometerWindow[i - 1]));
    }

    // Check for peaks in acceleration derivatives
    for (int i = 1; i < accelerationDerivatives.length - 1; i++) {
      if (accelerationDerivatives[i] > DERIVATIVE_THRESHOLD &&
          accelerationDerivatives[i] > accelerationDerivatives[i - 1] &&
          accelerationDerivatives[i] > accelerationDerivatives[i + 1]) {
        return true;
      }
    }

    return false;
  }
}
