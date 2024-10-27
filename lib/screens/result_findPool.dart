import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:random_string/random_string.dart';
import 'package:ride_sync/Services/database_service.dart';
import 'package:ride_sync/colours.dart';
import 'package:ride_sync/screens/home.dart';
import 'dart:developer' as dev;

import 'package:ride_sync/screens/rides.dart';

class ResultFindPool extends StatefulWidget {
  final double userStartLat;
  final double userStartLng;
  final double userEndLat;
  final double userEndLng;
  final String genderPreference;
  final Timestamp fireStoreTimestamp;
  final int seatsRequested;
  final String distance;
  final String requestId;

  const ResultFindPool({
    required this.userStartLat,
    required this.userStartLng,
    required this.userEndLat,
    required this.userEndLng,
    required this.genderPreference,
    required this.fireStoreTimestamp,
    required this.seatsRequested,
    required this.distance,
    super.key,
    required this.requestId,
  });

  @override
  State<ResultFindPool> createState() => _ResultFindPoolState();
}

class _ResultFindPoolState extends State<ResultFindPool> {
  final _poolOffers = FirebaseFirestore.instance.collection('PoolOffers');
  final _users = FirebaseFirestore.instance.collection('Users');
  final User? user = FirebaseAuth.instance.currentUser;

  double endDistance = 0.0, startDistance = 0.0;

  //RideMatchingAlgorithm (Haversine Algo)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radiusOfEarthKm = 6371.0;
    double latDistance = _degreeToRadian(lat2 - lat1);
    double lonDistance = _degreeToRadian(lon2 - lon1);

    double a = sin(latDistance / 2) * sin(latDistance / 2) +
        cos(_degreeToRadian(lat1)) *
            cos(_degreeToRadian(lat2)) *
            sin(lonDistance / 2) *
            sin(lonDistance / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radiusOfEarthKm * c;
  }

  double _degreeToRadian(double degree) {
    return degree * pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Matching Ride Givers',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: deepGreen,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _poolOffers.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> poolSnapshot) {
                if (poolSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: deepGreen,
                    ),
                  );
                }
                if (poolSnapshot.hasData &&
                    poolSnapshot.data!.docs.isNotEmpty) {
                  List<QueryDocumentSnapshot> filteredDocs =
                      poolSnapshot.data!.docs.where((doc) {
                    final startLocation = doc['startLocation'];
                    final endLocation = doc['endLocation'];
                    final double startLat = startLocation['latitude'];
                    final double startLng = startLocation['longitude'];
                    final double endLat = endLocation['latitude'];
                    final double endLng = endLocation['longitude'];

                    startDistance = calculateDistance(widget.userStartLat,
                        widget.userStartLng, startLat, startLng);
                    endDistance = calculateDistance(
                        widget.userEndLat, widget.userEndLng, endLat, endLng);

                    bool isWithinRadius =
                        (startDistance <= 2.0 && endDistance <= 2.0);
                    dev.log(
                        'Start Distance: $startDistance, End Distance: $endDistance');

                    bool genderMatch =
                        doc['preferredGender'] == widget.genderPreference;

                    DateTime docDateTime = (doc['time'] as Timestamp).toDate();
                    DateTime userSelectedDateTime =
                        widget.fireStoreTimestamp.toDate();

                    bool isSameDate =
                        docDateTime.year == userSelectedDateTime.year &&
                            docDateTime.month == userSelectedDateTime.month &&
                            docDateTime.day == userSelectedDateTime.day;

                    DateTime startTime =
                        userSelectedDateTime.subtract(Duration(hours: 2));
                    DateTime endTime =
                        userSelectedDateTime.add(Duration(hours: 2));

                    bool isWithinTimeBuffer = docDateTime.isAfter(startTime) &&
                        docDateTime.isBefore(endTime);

                    bool dateTimeMatch = isSameDate && isWithinTimeBuffer;

                    // Check for seats
                    int availableSeats = doc['availableSeats'] ?? 0;
                    bool seatsAvailable =
                        availableSeats >= widget.seatsRequested;

                    bool isNotCurrentUser = (doc['userId'] != user!.uid);

                    bool isNotCancelled = (doc['status'] != 'Cancelled');

                    return isWithinRadius &&
                        genderMatch &&
                        dateTimeMatch &&
                        seatsAvailable &&
                        isNotCurrentUser &&
                        isNotCancelled;
                  }).toList();

                  List<Future<DocumentSnapshot>> userDetails =
                      filteredDocs.map((poolOffersSnapshot) {
                    return _users.doc(poolOffersSnapshot['userId']).get();
                  }).toList();
                  // List<Future<DocumentSnapshot>> userDetails =
                  //     poolSnapshot.data!.docs.map((poolOffersSnapshot) {
                  //   return _users.doc(poolOffersSnapshot['userId']).get();
                  // }).toList();

                  return FutureBuilder(
                    future: Future.wait(userDetails),
                    builder: (context,
                        AsyncSnapshot<List<DocumentSnapshot>> userSnapshots) {
                      if (userSnapshots.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: deepGreen,
                          ),
                        );
                      }

                      if (userSnapshots.hasData) {
                        if (filteredDocs.isNotEmpty) {
                          return ListView.builder(
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final poolOffersSnapshot = filteredDocs[index];
                              final userSnapshot = userSnapshots.data![index];
                              dev.log((filteredDocs.length ==
                                      userSnapshots.data!.length)
                                  .toString());
                              final userData =
                                  userSnapshot.data() as Map<String, dynamic>;
                              dev.log(userData.toString());
                              return CarpoolRequestCard(
                                profilePic: userData['imgURL'] ??
                                    'https://icon-library.com/images/user-icon-jpg/user-icon-jpg-0.jpg',
                                name: userData['name'],
                                rating: (userData['rating'] is int)
                                    ? userData['rating'].toDouble()
                                    : userData['rating'] ?? 0.0,
                                totalPools: userData['totalPools'] ?? 0,
                                time: DateFormat('HH:mm').format(
                                    poolOffersSnapshot['time'].toDate()),
                                walk_1_dist:
                                    '${startDistance.toStringAsFixed(2)} km',
                                ride_dist: widget.distance,
                                walk_2_dist:
                                    '${endDistance.toStringAsFixed(2)} km',
                                totalCo2Saved:
                                    (userData['totalCo2Saved'] is int)
                                        ? userData['totalCo2Saved'].toDouble()
                                        : userData['totalCo2Saved'] ?? 0.0,
                                isVerifiedGender: userData['verifiedGender'],
                                offerId: poolOffersSnapshot['offerId'],
                                seatsRequested: widget.seatsRequested,
                                availableSeats:
                                    poolOffersSnapshot['availableSeats'],
                                userId_SeatRequest: user!.uid,
                                duration: poolOffersSnapshot['duration'],
                                startTime: poolOffersSnapshot['time'],
                                startLocationName:
                                    poolOffersSnapshot['startLocationName'],
                                endLocationName:
                                    poolOffersSnapshot['endLocationName'],
                                userStartLat:
                                    poolOffersSnapshot['startLocation']
                                        ['latitude'],
                                userStartLng:
                                    poolOffersSnapshot['startLocation']
                                        ['longitude'],
                                userEndLat: poolOffersSnapshot['endLocation']
                                    ['latitude'],
                                userEndLng: poolOffersSnapshot['endLocation']
                                    ['longitude'],
                                requestId: widget.requestId,
                              );
                            },
                          );
                        } else {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.directions_car,
                                  color: lightGreen,
                                  size: 100,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'No matching pool offers found!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: deepGreen,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'We\'ll keep searching for matching pool offers for this ride...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }
                      }

                      return const Text('Error fetching user data');
                    },
                  );
                } else {
                  return const Center(
                    child: Text('No pool offers available'),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CarpoolRequestCard extends StatelessWidget {
  final String profilePic;
  final String name;
  final double rating;
  final int totalPools;
  final String time;
  final String walk_1_dist;
  final String ride_dist;
  final String walk_2_dist;
  final String duration;
  final String startLocationName;
  final String endLocationName;
  final double userStartLat;
  final double userStartLng;
  final double userEndLat;
  final double userEndLng;
  final Timestamp startTime;
  final double totalCo2Saved;
  final bool isVerifiedGender;
  final String offerId;
  final int seatsRequested;
  final int availableSeats;
  final String userId_SeatRequest;
  final String requestId;

  CarpoolRequestCard({
    required this.profilePic,
    required this.name,
    required this.rating,
    required this.totalPools,
    required this.time,
    required this.walk_1_dist,
    required this.ride_dist,
    required this.walk_2_dist,
    required this.totalCo2Saved,
    required this.isVerifiedGender,
    required this.offerId,
    required this.seatsRequested,
    required this.availableSeats,
    required this.userId_SeatRequest,
    required this.duration,
    required this.startTime,
    required this.startLocationName,
    required this.endLocationName,
    required this.userStartLat,
    required this.userStartLng,
    required this.userEndLat,
    required this.userEndLng,
    required this.requestId,
  });

  final _RidesDatabaseService = RidesDatabaseService();

  final _VehicleDatabaseService = VehicleDatabaseService();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: deepGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(profilePic),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 5),
                          isVerifiedGender
                              ? const Icon(
                                  Icons.verified_user_sharp,
                                  color: Colors.green,
                                  size: 18,
                                )
                              : const Row(
                                  children: [
                                    Icon(
                                      Icons.sentiment_dissatisfied_sharp,
                                      color: Colors.red,
                                      size: 15,
                                    ),
                                    SizedBox(
                                      width: 2,
                                    ),
                                    Text(
                                      'Gender Not Verified',
                                      style: TextStyle(
                                          color: titleGrey,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    )
                                  ],
                                )
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(
                            rating.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '$totalPools Pools',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.access_time, size: 16),
                          Text(time),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.directions_walk, size: 20),
                      Text(walk_1_dist, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const Icon(Icons.double_arrow),
                  Column(
                    children: [
                      const Icon(Icons.directions_car, size: 20),
                      Text(ride_dist, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const Icon(Icons.double_arrow),
                  Column(
                    children: [
                      const Icon(Icons.directions_walk, size: 20),
                      Text(walk_2_dist, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco, color: Colors.green),
                      Text(
                        ' ${totalCo2Saved.toStringAsFixed(2)} kg CO2 saved',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        // showDialog(
                        //     context: context,
                        //     builder: (context) {
                        //       return const Center(
                        //         child: CircularProgressIndicator(
                        //           color: deepGreen,
                        //         ),
                        //       );
                        //     });
                        // Handle carId and seat update
                        String? carId = await _RidesDatabaseService
                            .UpdateSeatsOffered_OfferSeat(
                          context, // Use the saved context
                          offerId,
                          seatsRequested,
                          availableSeats,
                        );

                        if (carId == null) {
                          throw Exception("Car ID is null.");
                        }
                        dev.log(carId);

                        if (ride_dist == null || ride_dist.isEmpty) {
                          throw Exception("Invalid ride distance.");
                        }
                        dev.log(ride_dist);

                        String ride_dist_double =
                            ride_dist.replaceAll(RegExp(r'[^0-9.]'), '');
                        double? ride_dist_double_km =
                            double.tryParse(ride_dist_double);
                        dev.log(ride_dist_double_km.toString());
                        if (ride_dist_double_km == null) {
                          throw Exception("Failed to parse ride distance.");
                        }

                        List<dynamic> costSharingData =
                            await _VehicleDatabaseService.fetchVehicleDetails(
                                carId);

                        dev.log(costSharingData.toString());
                        if (costSharingData.isEmpty ||
                            costSharingData.length < 2) {
                          dev.log(costSharingData.toString());
                          throw Exception("Failed to fetch vehicle details.");
                        }

                        final FirebaseFirestore _firestore =
                            FirebaseFirestore.instance;
                        String rideId = randomAlphaNumeric(28);
                        dev.log(rideId);
                        Map<String, dynamic> CreateRideInfoMap = {
                          'rideId': rideId,
                          'offerId': offerId,
                          'passengers': [userId_SeatRequest],
                          'startLocation': {
                            'latitude': userStartLat,
                            'longitude': userStartLng,
                          },
                          'startLocationName': startLocationName,
                          'endLocation': {
                            'latitude': userEndLat,
                            'longitude': userEndLng,
                          },
                          'endLocationName': endLocationName,
                          'startTime': startTime,
                          'duration': duration,
                          'distance': ride_dist_double_km,
                          'status': "Pending",
                        };

                        final ridesCollection = _firestore.collection('Rides');

                        final existingRideSnapshot = await ridesCollection
                            .where('offerId',
                                isEqualTo: CreateRideInfoMap['offerId'])
                            .limit(1)
                            .get();

                        // Navigator.of(context).pop();
                        // showAddedToRidePopup(context, name);
                        if (existingRideSnapshot.docs.isEmpty) {
                          double costPerPerson = calculateCostSharing(
                            distance: ride_dist_double_km,
                            fuelOrEnergyConsumption: costSharingData[0],
                            numberOfPassengers: 2,
                            isEV: costSharingData[1],
                          );
                          dev.log(costPerPerson.toString());
                          double co2Saved =
                              calculateCO2Saved(ride_dist_double_km, 2);
                          dev.log(co2Saved.toString());
                          CreateRideInfoMap['costPerPassenger'] = costPerPerson;
                          CreateRideInfoMap['co2Saved'] = co2Saved;
                          // showDialog(
                          //     context: context,
                          //     builder: (context) {
                          //       return const Center(
                          //         child: CircularProgressIndicator(
                          //           color: deepGreen,
                          //         ),
                          //       );
                          //     });
                          await _RidesDatabaseService.CreateRide(
                              rideId, CreateRideInfoMap);
                          await _RidesDatabaseService.UpdateRequestStatus(
                              requestId);
                          // Navigator.of(context).pop();
                          // createRide(context,rideId,CreateRideInfoMap);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Ride created successfully.')),
                          );
                        } else {
                          // final existingRideDoc =
                          //     existingRideSnapshot.docs.first;
                          // final existingRideData = existingRideDoc.data();

                          // if (!existingRideData.containsKey('passengers')) {
                          //   throw Exception(
                          //       "Passengers field is missing in the existing ride.");
                          // }

                          // List<dynamic> passengers =
                          //     existingRideData['passengers'];
                          // String newPassenger =
                          //     CreateRideInfoMap['passengers'][0];

                          // await ridesCollection.doc(existingRideDoc.id).update({
                          //   'passengers': FieldValue.arrayUnion([newPassenger]),
                          // });

                          //addeddd
                          final existingRideDoc =
                              existingRideSnapshot.docs.first;
                          final existingRideData = existingRideDoc.data();
                          List<dynamic> passengers =
                              existingRideData['passengers'];

                          if (passengers == null) {
                            throw Exception(
                                "Passengers field is missing in the existing ride.");
                          }
                          // Add new passenger to the ride
                          String newPassenger =
                              CreateRideInfoMap['passengers'][0];
                          await ridesCollection.doc(existingRideDoc.id).update({
                            'passengers': FieldValue.arrayUnion([
                              newPassenger
                            ]), // Adds new passenger if not already in array
                          });

                          // Recalculate cost per passenger based on the updated number of passengers
                          double costPerPerson = calculateCostSharing(
                            distance: ride_dist_double_km,
                            fuelOrEnergyConsumption: costSharingData[0],
                            numberOfPassengers: passengers.length + 1,
                            isEV: costSharingData[1],
                          );
                          // Update cost per passenger in Firestore
                          await ridesCollection.doc(existingRideDoc.id).update({
                            'costPerPassenger': costPerPerson,
                          });

                          double co2Saved = calculateCO2Saved(
                              ride_dist_double_km, passengers.length + 1);
                          // Update co2Saved in Firestore
                          await ridesCollection.doc(existingRideDoc.id).update({
                            'co2Saved': co2Saved,
                          });

                          await _RidesDatabaseService.UpdateRequestStatus(
                              requestId);
                          dev.log("Ride Updated successfully!");
                        }
                      } catch (e) {
                        dev.log(
                            'Error creating or updating ride: ${e.toString()}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Failed to create or update ride: $e')),
                        );
                      }
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(
                      //       content:
                      //           Text('Ride request accepted successfully.')),
                      // );
                    },
                    child: const Text('Request Seat',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deepGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showAddedToRidePopup(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          icon: Icon(
            Icons.check_circle,
            size: 100,
            color: lightGreen,
          ),
          title: Row(
            children: [
              SizedBox(width: 10), // Space between icon and title
              Expanded(
                child: Text(
                  'Seat Requested Successfully!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            padding: EdgeInsets.symmetric(vertical: 10), // Vertical padding
            child: Column(
              mainAxisSize: MainAxisSize.min, // Size of the dialog
              children: [
                SizedBox(height: 10), // Space between text elements
                Text.rich(
                  TextSpan(
                    text: "You've successfully offered a seat to ",
                    style: TextStyle(
                        fontSize: 14), // Regular style for normal text
                    children: <TextSpan>[
                      TextSpan(
                        text: name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold), // Bold style for name
                      ),
                      TextSpan(
                        text: "! 🚗💚\nEnjoy your ride and the company! 😊",
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => HomePage()),
                  (Route<dynamic> route) => false,
                );
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return RidesPage();
                }));
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: lightGreen,
                ),
                child: Text(
                  'Awesome!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double calculateCostSharing({
    required double distance, // Distance in km
    required double fuelOrEnergyConsumption, // Mileage or energy consumption
    // required double fuelOrEnergyPrice, // Price per liter (petrol/diesel) or per kWh (EV)
    required int
        numberOfPassengers, // Total number of people (including driver)
    required bool isEV, // If the vehicle is an EV
  }) {
    double totalCost;

    if (isEV) {
      // Energy consumption for EV vehicles
      double energyUsed = distance * fuelOrEnergyConsumption; // kWh
      totalCost = energyUsed * 87.5; // Total cost in currency
    } else {
      // Fuel consumption for petrol/diesel vehicles
      double fuelUsed = distance / fuelOrEnergyConsumption; // Liters
      totalCost = fuelUsed * 102; // Total cost in currency
    }

    // Cost per person (including driver)
    return totalCost / numberOfPassengers;
  }

  double calculateCO2Saved(double distance, int no_of_passengers) {
    double CO2_per_km = 0.120;
    double totalEmissionsIfSeparate = distance * no_of_passengers * CO2_per_km;
    double actualEmissionsForPooledRide = distance * CO2_per_km;
    double CO2Saved = totalEmissionsIfSeparate - actualEmissionsForPooledRide;
    return CO2Saved;
  }
}
