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