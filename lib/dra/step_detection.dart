import 'dart:math';

class StepDetection{

  static int steps = 0;
  static int peaks = 0;
  static int valeys = 0;
  static int timeframe = 100; // milliesekond until new peak could beable must be between 110ms - 400ms in order to ensure a valid step [54] A. R. Pratama, W. Widyawan, and R. Hidayat, ‘‘Smartphone-based pedestrian dead reckoning as an indoor positioning system,’’ in Proc. ICSET,  Sep. 2012, pp. 1–6
  static double accZOld = 0.0;
  static double threshold = 1.2; ///in M/s
  static Peak peak = Peak(timeStamp: 0, acc: 0, positive: true, counted: true);
  static Peak valey = Peak(timeStamp: 0, acc: 0, positive: false, counted: true);
  static int lasttimePeak = 0;

  static void detectPeakAndValey (List<double> userAccValues, int timestamp){
    double uaccz = userAccValues[2];
    double actuelleAcc = accZOld * 0.75 + uaccz * .25;
    print("actuell acc $actuelleAcc");
    if(actuelleAcc >= 0){
      if(actuelleAcc > accZOld ){ /// New higher value !!!
        if(actuelleAcc >= threshold){
          peak = Peak(timeStamp: timestamp, acc: actuelleAcc, positive: true,counted: false);
        }
      }
      if(valey.positive == false){
        if(valey.counted == false){
          valeys++;
          valey.counted = true;
        }
      }
    }else{
      if(actuelleAcc < accZOld ){ /// New higher value !!!
        if(actuelleAcc <= threshold){
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
    //print("Steps $steps");
  }

  static double Magnitude(double x, double y, double z){
    return sqrt(pow(x, 2)+pow(y, 2)+pow(z, 2));
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