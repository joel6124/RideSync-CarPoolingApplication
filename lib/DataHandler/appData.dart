import 'package:flutter/material.dart';
import 'package:ride_sync/Model/address.dart';
import 'package:ride_sync/Model/userDetails.dart';

class AppData extends ChangeNotifier {
  Address? pickUpLocation, dropOffLocation;
  UserDetails? userDetails;

  void updatePickUpLocationAddress(Address pickUpAddress) {
    pickUpLocation = pickUpAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Address dropoffAddress) {
    dropOffLocation = dropoffAddress;
    notifyListeners();
  }
}
