import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:indoornavigation/Util/BuildingInfo.dart';
import 'package:indoornavigation/Util/map_loader.dart';
import 'package:indoornavigation/Wifi/wifi_layer.dart';
import 'package:indoornavigation/Wifi/wifimeasurements.dart';
import 'package:indoornavigation/constants/constants.dart';
import 'package:indoornavigation/dra/my_sensors.dart';
import 'package:latlong2/latlong.dart';
import '../Util/levelCalculator.dart';
import '../constants/sizes.dart';
import '../dra/positionalgorithm/positionEstimation.dart';
import 'Widgets/custom_slider_thumb.dart';

class MapPage extends StatefulWidget {
  static int selectedfloor = 0;
  final WifiLayer wifiLayer;
  static double heading = 0.0;
  const MapPage({super.key, required this.wifiLayer });

  @override
  State<MapPage> createState() => _MapPageState();

}

class _MapPageState extends State<MapPage> {


  int accuracy = 0;
  static bool showing = false;
  static bool follow = true;
  static double zoom = 19;

  final List<MapLoader> _listMaps = [];
  GeoJsonParser geoJsonParser = GeoJsonParser(
    defaultMarkerColor: Colors.red,
    defaultPolygonBorderColor: Colors.blue,
    defaultPolygonFillColor: Colors.white,
    defaultCircleMarkerColor: Colors.red.withOpacity(0.25),
    polygonCreationCallback: (points, holePointsList, properties) {
      if (properties['type'].toString().contains('Hallway')) {
        return Polygon(
            points: points,
            holePointsList: holePointsList,
            borderColor: Colors.black,
            borderStrokeWidth: 2.0,
            isFilled: true,
            color: Colors.lightGreenAccent,
            label: properties['name'].toString(),
            labelPlacement: PolygonLabelPlacement.polylabel,
            labelStyle: const TextStyle(color: black, fontSize: 20));
      }
      return Polygon(
          points: points,
          holePointsList: holePointsList,
          borderColor: Colors.black,
          borderStrokeWidth: 2.0,
          color: Colors.lightGreenAccent);
    },
  );
  late TextEditingController _controllerText;


  bool myFilterFunction(Map<String, dynamic> properties) {
    if (properties['name'].toString().contains('raum')) {
      return false;
    } else {
      return true;
    }
  }
  late StreamSubscription subscription;

  late List<StreamSubscription> streamSubscriptions = [];

  Future<void> cancelStreamsbeforeReturn() async {
    print("subscritions aktive:${streamSubscriptions.length}");
    for(int i = 0; i < streamSubscriptions.length; i++){
      await streamSubscriptions[i].cancel();
    }
  }

  void cancelstream(){
    subscription.cancel();
  }

  void showCalibrationDialog() {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        int accur = accuracy;
         subscription = MySensors.acuracyStream.listen((event) {
          if(event > accur){
            MySensors.countingLegitimated = true;
            setState(() {

            });
          }
          if(event == 3){
            cancelstream();
            Navigator.pop(context);
            setState(() {

            });
          }
        });



        return AlertDialog(
          title: const Text('Accuracy too Low'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your phone is not calibrated please calibrate it'),
              Image.asset(
                "asset/images/calivration.gif",
              ),
              const Text("Accuracy: low")
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                showing = false;
                Navigator.pop(context, 'OK');
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void onTapMarkerFunction(Map<String, dynamic> map) {
    // ignore: avoid_print
    print('onTapMarkerFunction: $map');
  }

  Future<bool> getMap(int level, String buildingName) async {
    MapLoader? mapLoader = await MapLoader.getMaploader(buildingName, level);
    if (mapLoader != null) {
      _listMaps.add(mapLoader);
      setState(() {});
      return true;
    } else {
      return false;
    }
  }

  Future<bool> getWholebuilding(String buildingName) async {
    for (int i = -1; i < 7; i++) {
      MapLoader? mapLoader = await MapLoader.getMaploader(buildingName, i);
      if (mapLoader != null && i != 0) {
        print(mapLoader.floorNumber);
        _listMaps.add(mapLoader);
      }
    }
    return true;
  }

  List<Marker> markers = [];

  void createMarkerForreferencePoints(){
    for(int i = 0; i < widget.wifiLayer.referencePoints.length; i++){
      Marker marker = Marker(
          child: const Icon(
              Icons.add_circle_outline
          ),
          point: LatLng(widget.wifiLayer.referencePoints[i].latitude, widget.wifiLayer.referencePoints[i].longitude));
      if(widget.wifiLayer.referencePoints[i].accesspoints.isNotEmpty){
        markers.add(marker);
      }

    }
  }

  void startStream(){
    streamSubscriptions.add(
      MySensors.acuracyStream.listen((event) {
        accuracy = event;
        if(MySensors.magnetometer_accuray != 3 && showing == false){
          showing = true;
          setState(() {
            accuracy = MySensors.magnetometer_accuray;
          });
          showCalibrationDialog();
          MySensors.countingLegitimated = false;
        }

        setState(() {

        });
      })
    );
  }

  MapController mapController = MapController(

  );

  Future<bool> setupSensors() async{
    MySensors mySensors = MySensors();
    return mySensors.StartSensorsAndPosition(context);
  }

  final _streamController = StreamController<double>();
  Stream<double> get onZoomChanged => _streamController.stream;

  Future<bool> SetupSensors() async{
    MySensors mySensors = MySensors();
    return mySensors.StartSensorsAndPosition(context);
  }

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
    LevelCalculator.checkSensorsAvaileble();
    WifiMeasurements.setupWifi(context);
    ////startlisten();
    //SetupSensors().then((value){
    //  print("Sensors is ready: $value");
    //});
    //PositionEstimation.startTimer();
    getMap(0, "mar");
    getWholebuilding("mar");
    //setupSensors().then((value){
    //  print("Sensors is ready: $value");
    //});
    startStream();
    //createMarkerForreferencePoints();

    _controllerText = TextEditingController();

    onZoomChanged.listen((event) {
      zoom = event;
    });
  }

  @override
  void dispose() {
    _streamController.close();
    for(int i = 0; i < streamSubscriptions.length; i++){
      streamSubscriptions[i].cancel();
    }
    super.dispose();
  }

  int aktivefloor = 0;

  @override
  Widget build(BuildContext context) {
    if (_listMaps.isNotEmpty) {
      String geoJson = _listMaps.first.GeoJson;
      //print(_listMaps.length);
      for (int i = 0; i < _listMaps.length; i++) {
        if (_listMaps[i].floorNumber == BuildingInfo.aktiveFloor) {
          geoJson = _listMaps[i].GeoJson;
        }
      }
      geoJsonParser.polygons.clear();
      geoJsonParser.parseGeoJsonAsString(geoJson);

      return SafeArea(
          child: Scaffold(
        /*appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () async {
                await cancelStreamsbeforeReturn();
                Navigator.pop(context);
              },
            ),
        ),*/
        body: Stack(children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
                initialCenter: const LatLng(52.51662390833064, 13.323514830215117),
                initialZoom: 19.0,
                minZoom: 10,
                maxZoom: 24,
                onPositionChanged: (position, hasGesture) {
                  // Fill your stream when your position changes
                  final zoom = position.zoom;
                  if (zoom != null) {
                    _streamController.sink.add(zoom);
                  }
                },

            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                /*urlTemplate: 'asset/mar_eg/{z}/{x}/{y}.png',
                    tileProvider: AssetTileProvider(),*/
                minZoom: 9.0,
                maxZoom: 25.0,
              ),
              PolygonLayer(polygons: geoJsonParser.polygons),
              PolylineLayer(polylines: geoJsonParser.polylines),
              MarkerLayer(markers: geoJsonParser.markers),
              MarkerLayer(markers: markers),
              CurrentLocationLayer(
                positionStream: PositionEstimation.mapPosStream,
                headingStream: MySensors.headingStream,
                alignDirectionOnUpdate: follow == true ?AlignOnUpdate.always : AlignOnUpdate.never,
                alignPositionOnUpdate: follow == true ?AlignOnUpdate.always : AlignOnUpdate.never,
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      floorSelector(-1, 6),
                      GestureDetector(
                        onTap: (){
                          if(follow==true) {

                            follow = false;
                            _showToast(context,"follow deactivated!");
                          }else if(follow == false){

                            follow = true;
                            _showToast(context,"follow activated!");

                          }

                        },
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: const BoxDecoration(
                            color: lightGrey,
                            borderRadius: BorderRadius.all(Radius.circular(20))

                          ),
                          margin: EdgeInsets.only(top: 20,right: Sizes.paddingRegular, bottom: Sizes.paddingBig-15 ),
                          child: const Icon(
                              Icons.navigation,
                            color: white,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 20),
                  padding: const EdgeInsets.only(left: 10,right: 10),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    color: white,
                  ),
                  child: TextField(
                    onChanged: (data){
                      print(data);
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.
                      search),
                      labelText: 'Search',
                      border: InputBorder.none
                    ),
                    controller: _controllerText,
                    style: TextStyle(
                      fontSize: Sizes.textSizeRegular,
                      color: const Color(0xff000000),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(15),
                  child: Text(
                    "lat:${PositionEstimation.estimatedPosi.y},long:${PositionEstimation.estimatedPosi.x}\n"
                    "${WifiLayerGetter.wifiLayerDowaloaded}\n"
                    "Scanned wifi${WifiMeasurements.accespoints.length}\n"
                    "walked distance: ${PositionEstimation.walkedDistance} Stepstaken:${PositionEstimation.steps}\n"
                    "heading ${MySensors.oldheading}\n"
                    "Magn Acuracy ${MySensors.magnetometer_accuray}\n"
                    "ref set with wifis:${PositionEstimation.uploadedrefsAccespoints}\n"
                  ),
                )
              ],
            ),
          )
        ]),
      ));
    } else {
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.red,
            value: null,
          ),
        ),
      );
    }
  }

  Widget floorSelector(int levelStart, int levelEnd) {
    List<int> floors = [];
    floors.add(levelStart);
    if (levelStart != levelEnd) {
      int i = levelStart;
      while (levelEnd != i) {
        i++;
        floors.add(i);
      }
    }

    int max = levelEnd;
    int min = levelStart;
    return Container(
      margin: EdgeInsets.only(right: Sizes.paddingRegular),
      height: 250,
      width: 30,

      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        color: lightGrey
      ),
      child: RotatedBox(
        quarterTurns: 3,
        child: SliderTheme(
          data: SliderThemeData(
            inactiveTickMarkColor: Colors.black,
            activeTickMarkColor: Colors.red,
            trackHeight: 30.0,
            inactiveTrackColor: lightGrey,
            activeTrackColor: lightGrey,
            thumbColor: black,

            thumbShape: CustomSliderThumbRect(
              textColor: white,
              thumbColor: const Color.fromARGB(255, 94, 94, 94),
              max: max,
              min: min,
              thumbRadius: 20,
              thumbHeight: 40.0,
            ),
            showValueIndicator: ShowValueIndicator.onlyForDiscrete,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
            ),

          ),
          child: Slider(
            divisions: floors.length - 1,
            value: aktivefloor.toDouble(),
            label: aktivefloor.round().toString(),
            min: levelStart.toDouble(),
            max: levelEnd.toDouble(),
            onChanged: (double value) {
              setState(() {
                aktivefloor = value.round();
                //print(value);
                BuildingInfo.aktiveFloor = aktivefloor;
              });
            },
          ),

        ),
      ),
    );
  }

  void _showToast(BuildContext context, String text) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(

        content: Text(text),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
