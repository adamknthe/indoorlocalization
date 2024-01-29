import 'package:flutter/material.dart';

//Farben der App
const Color black = Color.fromARGB(255, 0, 0, 0);
const Color white = Color.fromARGB(255, 250, 250, 250);
const Color darkGrey = Color.fromARGB(255, 25, 25, 25);
const Color lightGrey = Color.fromARGB(255, 150, 150, 150);
const Color whiteGrey = Color.fromARGB(255, 235, 235, 235);
const Color mraBlue = Color.fromARGB(255, 0, 127, 199);

//String Konstanten
const String domain = "http://god-did.de/v1";         //URL DES APPWRITE-SERVERS
const String projectId = "65a520855c6183271dca";      //PROJEKT-ID DES APPWRITE-PROJEKTES
const String databaseIdWifi = "65a524e2c64e3e572551"; //DATABASE-ID WIFI
const String databaseIdMaps = "65a5237b786037e0cb8d";//DATABASE-ID BUILDINGS
const String collectionIDAccesPoints = "65ae950bf110097be9ce";  //COLLECTION-ID ACCESSPOINTS
const String collectionIDReferencePoints = "65ae93cceb8a712e6a06";  //COLLECTION-ID REFERENCEPOINTS
const String collectionIDMar = "65ae8e92149436177fad";  //COLLECTION-ID MAR
const String collectionIdBuildings = "65a523837ab25ceabbba"; //COLLECTION-ID BUILDINGS

//Konstanten für Animationen
const Duration animationDuration = Duration(milliseconds: 250);
const Curve animationCurve = Curves.ease;