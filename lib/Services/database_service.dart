import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:ride_sync/colours.dart';

const String PoolOffers_collection_ref = "PoolOffers";
const String vehicle_collection_ref = "Cars";
const String PoolRequests_collection_ref = "PoolRequests";
const String Rides_collection_ref = "Rides";

class VehicleDatabaseService {
  Future<void> addVehicle(
      context, String carId, Map<String, dynamic> VehicleInfoMap) async {
    showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(
              color: deepGreen,
            ),
          );
        });
    try {
      await FirebaseFirestore.instance
          .collection(vehicle_collection_ref)
          .doc(carId)
          .set(VehicleInfoMap);
      developer.log("Vehicle added successfully!");
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      developer.log("Error adding vehicle data: $e");
    }
  }

  Future<List<dynamic>> fetchVehicleDetails(String carId) async {
    try {
      var carDoc = await FirebaseFirestore.instance
          .collection(vehicle_collection_ref)
          .doc(carId)
          .get();

      if (carDoc.exists) {
        var carData = carDoc.data();
        developer.log("Fetched Car Data: ${carData.toString()}");

        String? carType = carData?['carType'];
        developer.log("Car Type: $carType");

        if (carType == "Diesel" || carType == "Petrol") {
          double? mileage = carData?['mileage'];
          // Navigator.pop(context);
          developer.log("Fetched Vehicle Details successfully! - mileage");
          return [mileage, false];
        } else if (carType == "EV") {
          String? energyConsumption = carData?['energyConsumption'];
          // Navigator.pop(context);
          developer.log("Fetched Vehicle Details successfully! - EV");
          return [energyConsumption, true];
        } else {
          // Navigator.pop(context);
          throw Exception("Unsupported car type: $carType");
        }
      } else {
        developer.log("Car with ID $carId does not exist.");
      }
    } catch (e) {
      // Navigator.pop(context);
      developer.log("Error fetching vehicle data: $e");
    }

    return [];
  }
}

class DrivingLicenseDatabaseService {
  Future<void> saveLicense(context, _licenseNo) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .update({
          'driverLicenseNo': _licenseNo.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Driver\'s License saved successfully!')),
        );

        Navigator.of(context).pop();
      } catch (e) {
        print("Error saving driver's license: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save Driver\'s License: $e')),
        );
      }
    }
  }
}

class OfferPoolDatabaseService {
  Future<void> addPoolOffer(
      context, String offerId, Map<String, dynamic> PoolOfferInfoMap) async {
    showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(
              color: deepGreen,
            ),
          );
        });
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection(PoolOffers_collection_ref)
            .doc(offerId)
            .set(PoolOfferInfoMap);
        developer.log("Pool Offer added successfully!");
        Navigator.pop(context);
      } catch (e) {
        Navigator.pop(context);
        developer.log("Error adding Pool Offer: $e");
      }
    }
  }
}

class FindPoolDatabaseService {
  Future<void> addPoolFind(
      context, String requestId, Map<String, dynamic> PoolFindInfoMap) async {
    showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(
              color: deepGreen,
            ),
          );
        });
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection(PoolRequests_collection_ref)
            .doc(requestId)
            .set(PoolFindInfoMap);
        developer.log("Pool Request added successfully!");
        Navigator.pop(context);
      } catch (e) {
        Navigator.pop(context);
        developer.log("Error adding Pool Request : $e");
      }
    }
  }
}

class RidesDatabaseService {
  Future<void> CreateRide(
      String rideId, Map<String, dynamic> CreateRideInfoMap) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection(Rides_collection_ref)
            .doc(rideId)
            .set(CreateRideInfoMap);
        developer.log("Ride Creted successfully!");
        // Navigator.pop(context);
      } catch (e) {
        // Navigator.pop(context);
        developer.log("Error creating ride : $e");
      }
    }
  }

  Future<String> UpdateSeatsOffered_OfferSeat(BuildContext context,
      String offerId, int seatsRequested, int availableSeats) async {
    // showDialog(
    //     context: context,
    //     builder: (context) {
    //       return const Center(
    //         child: CircularProgressIndicator(
    //           color: deepGreen,
    //         ),
    //       );
    //     });
    try {
      await FirebaseFirestore.instance
          .collection(PoolOffers_collection_ref)
          .doc(offerId)
          .update({
        'availableSeats': (availableSeats - seatsRequested),
      });

      var updatedDoc = await FirebaseFirestore.instance
          .collection(PoolOffers_collection_ref)
          .doc(offerId)
          .get();

      if (updatedDoc.exists) {
        // Retrieve the carId from the document
        String? carId = updatedDoc.data()?['carId'];

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Number of seats updated successfully')),
        // );

        // Navigator.of(context).pop();
        return carId!;
      } else {
        throw 'Document not found after update';
      }
    } catch (e) {
      print("Error updating number of seats: $e");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Failed to update number of seats: $e')),
      // );
      // Navigator.of(context).pop(); // Close the dialog if there's an error
      return ""; // Return null in case of an error
    }
  }

  Future<void> UpdateRequestStatus(String requestId) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection(PoolRequests_collection_ref)
            .doc(requestId)
            .update({
          'status': 'Accepted',
        });
        developer.log("Status of Ride Request updated successfully!");
        // Navigator.pop(context);
      } catch (e) {
        // Navigator.pop(context);
        developer.log("Error updating request : $e");
      }
    }
  }

  Future<void> cancelRideRequest(
      BuildContext context, DocumentSnapshot<Object?> ride) async {
    showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(
              color: deepGreen,
            ),
          );
        });
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection(Rides_collection_ref)
            .doc(ride['rideId'])
            .update({
          'passengers': FieldValue.arrayRemove([user.uid]),
        });
        developer.log("cancelRideRequest successfull!");
        Navigator.pop(context);
      } catch (e) {
        Navigator.pop(context);
        developer.log("Error cancelRideRequest : $e");
      }
    }
  }

  Future<void> cancelRideOffer(
      BuildContext context, DocumentSnapshot<Object?> ride) async {
    showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(
              color: deepGreen,
            ),
          );
        });
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection(Rides_collection_ref)
            .doc(ride['rideId'])
            .update({
          'status': 'Cancelled',
        });
        await FirebaseFirestore.instance
            .collection(PoolOffers_collection_ref)
            .doc(ride['offerId'])
            .update({
          'status': 'Cancelled',
        });
        developer.log("cancelRide Offer successfull!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Offer cancelled successfully'),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        Navigator.pop(context);
        developer.log("Error cancelRide Offer : $e");
      }
    }
  }
}
