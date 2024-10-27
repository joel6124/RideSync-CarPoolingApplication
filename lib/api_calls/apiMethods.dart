import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import 'package:ride_sync/DataHandler/appData.dart';
import 'package:ride_sync/Model/address.dart';
import 'package:ride_sync/Model/directionDetails.dart';
import 'package:ride_sync/Model/placePred.dart';
import 'package:ride_sync/api_calls/api.dart';
import 'package:ride_sync/configMaps.dart';

class ApiMethods {
  static Future<String> searchCoordinateAddress(
      Position position, context) async {
    String placeAddress = "";
    String ads1, ads2, ads3, ads4, ads5, ads6;
    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    var response = await Api.getRequest(url);

    if (response != 'failed') {
      // placeAddress = response["results"][0]["formatted_address"];
      ads1 = response["results"][0]["address_components"][0]["long_name"];
      ads2 = response["results"][0]["address_components"][1]["long_name"];
      ads3 = response["results"][0]["address_components"][3]["long_name"];
      ads4 = response["results"][0]["address_components"][4]["long_name"];
      ads5 = response["results"][0]["address_components"][5]["long_name"];
      ads6 = response["results"][0]["address_components"][6]["long_name"];
      placeAddress = ads1 +
          ", " +
          ads2 +
          ", " +
          ads3 +
          ", " +
          ads4 +
          ", " +
          ads5 +
          ", " +
          ads6;

      Address userPickUpAddress = Address(
        placeFormattedAddress: placeAddress,
        placeName: '', // Provide appropriate values
        placeId: response["results"][0]["place_id"],
        latitude: position.latitude,
        longitude: position.longitude,
      );

     

      Provider.of<AppData>(context, listen: false)
          .updatePickUpLocationAddress(userPickUpAddress);
    }

    return placeAddress;
  }

  static Future<List<PlacePredictions>> findPlace(
      String placeName, BuildContext context) async {
    if (placeName.length > 1) {
      developer.log('assad');
      double lat =
          Provider.of<AppData>(context, listen: false).pickUpLocation!.latitude;
      double long = Provider.of<AppData>(context, listen: false)
          .pickUpLocation!
          .longitude;
      String autoCompleteUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&types=geocode&location=$lat,$long&radius=25000&key=$mapKey&components=country:in";

      var response = await Api.getRequest(autoCompleteUrl);
      if (response != 'failed') {
        if (response["status"] == "OK") {
          var predictions = response["predictions"];
          var placePredictionList = (predictions as List)
              .map((e) => PlacePredictions.fromJson(e))
              .toList();
          return placePredictionList;
        }

        // developer.log("\n\n\n\n Placed Found:  $response");
      }
    }
    return [];
  }

  static Future<String> getPlaceDetails(
      PlacePredictions placeName, bool isPickUp, context) async {
    String placeDetailsURL =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeName.placeId}&key=$mapKey";
    var response = await Api.getRequest(placeDetailsURL);
    if (response != "failed") {
      if (response["status"] == "OK") {
        Address address = Address(
            placeFormattedAddress:
                (placeName.mainText + placeName.secondaryText),
            placeName: response["result"]["name"],
            placeId: placeName.placeId,
            latitude: response["result"]["geometry"]["location"]["lat"],
            longitude: response["result"]["geometry"]["location"]["lng"]);

        if (isPickUp == true) {
          Provider.of<AppData>(context, listen: false)
              .updatePickUpLocationAddress(address);
        } else {
          Provider.of<AppData>(context, listen: false)
              .updateDropOffLocationAddress(address);
        }
      }
    }
    return "";
  }

  static Future<DirectionDetails?> getDirections(
      LatLng initialPos, LatLng finalPos) async {
    String directionUrl =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPos.latitude},${initialPos.longitude}&destination=${finalPos.latitude},${finalPos.longitude}&key=$mapKey";
    var response = await Api.getRequest(directionUrl);
    if (response == "failed") {
      return null;
    }

    if (response["status"] == "OK") {
      String encodedPoints =
          response["routes"][0]["overview_polyline"]["points"];
      String distanceText =
          response["routes"][0]["legs"][0]["distance"]["text"];
      int distanceValue = response["routes"][0]["legs"][0]["distance"]["value"];
      String durationText =
          response["routes"][0]["legs"][0]["duration"]["text"];
      int durationValue = response["routes"][0]["legs"][0]["duration"]["value"];

      DirectionDetails directionDetails = DirectionDetails(
          distanceValue: distanceValue,
          durationValue: durationValue,
          distanceText: distanceText,
          durationText: durationText,
          encodedPoints: encodedPoints);

      return directionDetails;
    }

    return null;
  }
}
