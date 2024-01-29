import 'package:flutter/material.dart';
import 'package:indoornavigation/Util/BuildingInfo.dart';
import 'package:indoornavigation/constants/sizes.dart';

import '../../constants/Constants.dart';

class FloorSelector extends StatefulWidget {
  int levelStart;
  int levelEnd;

  FloorSelector(this.levelStart, this.levelEnd, {super.key});


  @override
  State<FloorSelector> createState() => _FloorSelectorState();


}

class _FloorSelectorState extends State<FloorSelector> {
  static int aktivefloor = 0;
  @override
  Widget build(BuildContext context) {

    List<int> floors = [];
    floors.add(widget.levelStart);
    if (widget.levelStart != widget.levelEnd) {
      int i = widget.levelStart;
      while (widget.levelEnd != i) {
        i++;
        floors.add(i);
      }
    }
    return Container(
      margin: EdgeInsets.all(Sizes.paddingRegular),
      height: 250,
      width: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        color: white,
      ),
      child: RotatedBox(
        quarterTurns: 3,
        child: SliderTheme(
          data: SliderThemeData(
            inactiveTickMarkColor: Colors.black,
            activeTickMarkColor: Colors.red,
            trackHeight: 20.0,
            inactiveTrackColor: white,
            activeTrackColor: white
          ),
          child: Slider(
            divisions: floors.length-1,
            value: aktivefloor.toDouble(),
            label: aktivefloor.round().toString(),
            min: widget.levelStart.toDouble(),
            max: widget.levelEnd.toDouble(),
            onChanged: (double value){
              setState(() {
                aktivefloor = value.round();
                print(value);
                BuildingInfo.aktiveFloor = aktivefloor;
              });
            },
          ),
        ),
      ),
    );
  }



}
