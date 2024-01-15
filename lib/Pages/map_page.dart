import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

String testGeoJson = '''{
    "type": "FeatureCollection",
"features": [
{
"type": "Feature",
"properties": {
"id": 0,
"floor": 0,
"name": "groundplane",
"info": "",
"roomnumber": ""
},
"geometry": {
"coordinates": [
[
[
13.322940714764513,
52.51643401664231
],
[
13.322828983202783,
52.51628757114776
],
[
13.323387641014733,
52.51611758915834
],
[
13.324066625125653,
52.516938726838646
],
[
13.323490777841442,
52.517116550811636
],
[
13.323370451543639,
52.51696749253023
],
[
13.323503669945666,
52.51693088164697
],
[
13.32352085941676,
52.51694918709225
],
[
13.323748619909367,
52.516886425533215
],
[
13.323576725197029,
52.516666759370366
],
[
13.323344667337551,
52.51673475139518
],
[
13.323232935774712,
52.51659353707183
],
[
13.323452101532268,
52.51652554482848
],
[
13.323267314716901,
52.51631110706387
],
[
13.323030959488165,
52.516373869444664
],
[
13.32306533843041,
52.51640525060145
],
[
13.322940714764513,
52.51643401664231
]
]
],
"type": "Polygon"
},
"id": 0
},
{
"type": "Feature",
"properties": {
"id": 1,
"floor": 0,
"name": "mensa",
"info": "kantine",
"roomnumber": "005"
},
"geometry": {
"coordinates": [
[
[
13.323339324016871,
52.51673318938515
],
[
13.323233037876975,
52.51659589677985
],
[
13.323450900385893,
52.51652776180373
],
[
13.323572581609511,
52.51666612036897
],
[
13.323339324016871,
52.51673318938515
]
]
],
"type": "Polygon"
},
"id": 1
},
{
"type": "Feature",
"properties": {
"id": 2,
"floor": 0,
"name": "flur",
"info": "flur",
"roomnumber": ""
},
"geometry": {
"coordinates": [
[
[
13.322933224177405,
52.51630910567735
],
[
13.32336628870027,
52.516184441451685
],
[
13.323961268240964,
52.51690418135473
],
[
13.323550191466808,
52.51702267398906
],
[
13.32353218427383,
52.51698325409885
],
[
13.323868445133712,
52.51687964711218
],
[
13.323634339471852,
52.51658436585916
],
[
13.32354921014013,
52.5166154481897
],
[
13.323502389006904,
52.51656364429326
],
[
13.32360028773914,
52.516529971727635
],
[
13.32339014190319,
52.51626513484814
],
[
13.323320010344816,
52.51627806744963
],
[
13.323292382761366,
52.51624185615631
],
[
13.322956601364268,
52.51633755736697
],
[
13.322933224177405,
52.51630910567735
]
]
],
"type": "Polygon"
},
"id": 2
},
{
"type": "Feature",
"properties": {
"id": 3,
"floor": 0,
"name": "raum",
"info": "raum 001",
"roomnumber": "001"
},
"geometry": {
"coordinates": [
[
[
13.323647662463486,
52.516744553319086
],
[
13.323582259730784,
52.51667325344272
],
[
13.323680997403585,
52.51664636434677
],
[
13.32373770764579,
52.51671588410636
],
[
13.323647662463486,
52.516744553319086
]
]
],
"type": "Polygon"
},
"id": 3
}
]
}''';

class _MapPageState extends State<MapPage> {
  GeoJsonParser geoJsonParser = GeoJsonParser(
    defaultMarkerColor: Colors.red,
    defaultPolygonBorderColor: Colors.blue,
    defaultPolygonFillColor: Colors.white,
    defaultCircleMarkerColor: Colors.red.withOpacity(0.25),
    polygonCreationCallback: (points, holePointsList, properties) {
      if(properties['name'].toString().contains('raum')){
        return Polygon(points:points,holePointsList: holePointsList, borderColor: Colors.red,borderStrokeWidth: 20.0, isFilled: true,color: Colors.lightGreenAccent);
      }
      return Polygon(points: points,holePointsList: holePointsList,borderColor: Colors.black,borderStrokeWidth: 2.0,color: Colors.lightGreenAccent);
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

  @override
  Widget build(BuildContext context) {
    geoJsonParser.parseGeoJsonAsString(testGeoJson);
    for(int i = 0; i < geoJsonParser.polygons.length; i++){
      print(geoJsonParser.polygons[i].borderColor);
    }
    return SafeArea(
      child: Scaffold(
        body: Container(
          height: 500,
          width: 500,
          child: FlutterMap(
            mapController: MapController(),
            options: MapOptions(
              center: LatLng(52.512451, 13.321862),
              zoom: 12.0
            ),
            children: [
              TileLayer(
                urlTemplate: 'asset/mar_eg/{z}/{x}/{y}.png',
                tileProvider: AssetTileProvider(),
                minZoom: 12.0,
                maxZoom: 20.0,
              ),
              PolygonLayer(polygons: geoJsonParser.polygons),
              PolylineLayer(polylines: geoJsonParser.polylines),
              MarkerLayer(markers: geoJsonParser.markers)
            ],
          ),
        ),
      )
    );
  }
}
