import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:indoornavigation/Pages/Widgets/floorselector.dart';
import 'package:indoornavigation/Util/BuildingInfo.dart';
import 'package:indoornavigation/Util/map_loader.dart';
import 'package:indoornavigation/Wifi/wifi_layer.dart';
import 'package:indoornavigation/constants/Constants.dart';
import 'package:latlong2/latlong.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../constants/sizes.dart';

class MapPage extends StatefulWidget {
  static int selectedfloor = 0;

  MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<MapLoader> _listMaps = [];
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
            labelStyle: TextStyle(color: black, fontSize: 20));
      }
      return Polygon(
          points: points,
          holePointsList: holePointsList,
          borderColor: Colors.black,
          borderStrokeWidth: 2.0,
          color: Colors.lightGreenAccent);
    },
  );

  bool myFilterFunction(Map<String, dynamic> properties) {
    if (properties['name'].toString().contains('raum')) {
      return false;
    } else {
      return true;
    }
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getMap(0, "mar");
    getWholebuilding("mar");
  }
  int aktivefloor = 0;

  @override
  Widget build(BuildContext context) {

    if (_listMaps.length >= 1) {
      String geoJson = _listMaps.first.GeoJson;
      print(_listMaps.length);
      for (int i = 0; i < _listMaps.length; i++) {
        if (_listMaps[i].floorNumber == BuildingInfo.aktiveFloor) {
          geoJson = _listMaps[i].GeoJson;
        }
      }
      geoJsonParser.polygons.clear();
      geoJsonParser.parseGeoJsonAsString(geoJson);
      return SafeArea(
          child: Scaffold(
        appBar: AppBar(
          actions: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Icon(Icons.ac_unit),
            )
          ],
        ),
        body: Container(
          child: Stack(children: [
            FlutterMap(
              mapController: MapController(),
              options: MapOptions(
                  center: LatLng(52.51662390833064, 13.323514830215117),
                  zoom: 19.0,
                  initialRotation: -25),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  /*urlTemplate: 'asset/mar_eg/{z}/{x}/{y}.png',
                      tileProvider: AssetTileProvider(),*/
                  minZoom: 12.0,
                  maxZoom: 20.0,
                ),
                PolygonLayer(polygons: geoJsonParser.polygons),
                PolylineLayer(polylines: geoJsonParser.polylines),
                MarkerLayer(markers: geoJsonParser.markers),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Floorseletor(-1, 6)
                  ],
                ),
              ],
            )
          ]),
        ),
      ));
    } else {
      return Container(
        child: CircularProgressIndicator(
          color: Colors.red,
          value: null,
        ),
      );
    }
  }

  Widget Floorseletor(int levelStart, int levelEnd) {
    List<int> floors = [];
    floors.add(levelStart);
    if (levelStart != levelEnd) {
      int i = levelStart;
      while (levelEnd != i) {
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
              activeTrackColor: white),
          child: Slider(
            divisions: floors.length - 1,
            value: aktivefloor.toDouble(),
            label: aktivefloor.round().toString(),
            min: levelStart.toDouble(),
            max: levelEnd.toDouble(),
            onChanged: (double value) {
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
