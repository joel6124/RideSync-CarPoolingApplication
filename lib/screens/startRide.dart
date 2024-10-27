import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:random_string/random_string.dart';
import 'package:ride_sync/colours.dart';
import 'package:ride_sync/colours.dart';
import 'package:ride_sync/screens/home.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:pinput/pinput.dart';

class StartRidePage extends StatefulWidget {
  final String offerId;

  const StartRidePage({Key? key, required this.offerId}) : super(key: key);

  @override
  _StartRidePageState createState() => _StartRidePageState();
}

class _StartRidePageState extends State<StartRidePage> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? ride;
  List<String> pins = [];
  List<String> passengerNames = []; // To hold names of passengers
  // List<String> passengerIDS = [];
  List<String> profilePics = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRideDetails();
  }

  Future<void> _fetchRideDetails() async {
    try {
      QuerySnapshot<Map<String, dynamic>> rideSnapshot = await FirebaseFirestore
          .instance
          .collection('Rides')
          .where('offerId', isEqualTo: widget.offerId)
          .limit(1)
          .get();

      if (rideSnapshot.docs.isNotEmpty) {
        ride = rideSnapshot.docs.first.data();
        pins = List.generate(ride!['passengers'].length, (_) => '');

        await _fetchPassengerNames(ride!['passengers']);

        await _generateAndStorePins();

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No ride found with the given offerId!')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching ride details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching ride details: $e')),
      );
    }
  }

  Future<void> _updatePassengerRatings(List<double> ratings) async {
    if (ratings.isNotEmpty) {
      try {
        int index = 0;

        for (String passengerId in ride!['passengers']) {
          DocumentReference userRef =
              FirebaseFirestore.instance.collection('Users').doc(passengerId);
          DocumentSnapshot userSnapshot = await userRef.get();

          if (userSnapshot.exists) {
            var currentRating = userSnapshot['rating'];
            int totalPools = userSnapshot['totalPools'];

            double currentRatingValue = (currentRating is int)
                ? currentRating.toDouble()
                : currentRating;

            double updatedRating =
                ((currentRatingValue * totalPools) + ratings[index]) /
                    (totalPools + 1);
            updatedRating = double.parse(updatedRating.toStringAsFixed(1));

            await userRef.update({
              'rating': updatedRating,
            });

            print('Rating updated successfully for passenger: $passengerId');
          } else {
            print('User document does not exist for passenger: $passengerId');
          }

          index++;
        }
      } catch (e) {
        print('Failed to update rating: $e');
      }
    } else {
      print('No ratings provided to update.');
    }
  }

  Future<void> _fetchPassengerNames(List<dynamic> passengerIds) async {
    List<String> names = [];
    List<String> profilePic = [];
    for (String passengerId in passengerIds) {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(passengerId)
              .get();

      if (userSnapshot.exists) {
        names.add(userSnapshot.data()!['name']);
        profilePic.add(userSnapshot.data()!['imgURL'] == ""
            ? 'https://icon-library.com/images/user-icon-jpg/user-icon-jpg-0.jpg'
            : userSnapshot.data()!['imgURL']);
      } else {
        names.add('Unknown User');
        profilePic.add(
            'https://icon-library.com/images/user-icon-jpg/user-icon-jpg-0.jpg');
      }
    }
    setState(() {
      passengerNames = names;
      profilePics = profilePic;
    });
  }

  String _generateRandomPin() {
    return Random().nextInt(9000).toString().padLeft(4, '0');
  }

  Future<void> _generateAndStorePins() async {
    List<Map<String, String>> passengerPins = [];

    for (String passengerId in ride!['passengers']) {
      String pin = _generateRandomPin();
      passengerPins.add({'userId': passengerId, 'pin': pin});
      String notificationId = randomAlphaNumeric(28);
      Map<String, dynamic> notification = {
        'notificationId': notificationId,
        'userId': passengerId,
        'message':
            'Your ride has begun! Please share this PIN: $pin with your driver to confirm your ride.',
        'category': 'PIN',
        'timestamp': Timestamp.now(),
      };
      await FirebaseFirestore.instance
          .collection('Notifications')
          .doc(notificationId)
          .set(notification);

      print('Notification sent to passenger $passengerId');
    }

    await FirebaseFirestore.instance
        .collection('Rides')
        .doc(ride!['rideId'])
        .set({'passengerPins': passengerPins}, SetOptions(merge: true));
  }

  Future<void> _verifyPins() async {
    showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(
              color: deepGreen,
            ),
          );
        });
    DocumentSnapshot<Map<String, dynamic>> rideSnapshot =
        await FirebaseFirestore.instance
            .collection('Rides')
            .doc(ride!['rideId'])
            .get();

    List<dynamic> storedPins = rideSnapshot.data()!['passengerPins'];

    bool allPinsCorrect = true;

    for (var storedPin in storedPins) {
      String userId = storedPin['userId'];
      String pin = storedPin['pin'];

      // Check if the entered pin matches the stored pin
      if (!pins.any((p) => p == pin)) {
        allPinsCorrect = false;
        break;
      }
    }

    Future<void> _updateUserStats() async {
      double totalCo2Saved = ride!['co2Saved'];
      double totalDistanceCovered = ride!['distance'];
      int totalPools = 1;

      for (String passengerId in ride!['passengers']) {
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('Users').doc(passengerId);

        await userRef.set({
          'totalCo2Saved': FieldValue.increment(totalCo2Saved),
          'totalDistanceCovered': FieldValue.increment(totalDistanceCovered),
          'totalPools': FieldValue.increment(totalPools),
        }, SetOptions(merge: true));
      }
      //pool offerer
      if (user != null) {
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('Users').doc(user!.uid);

        await userRef.set({
          'totalCo2Saved': FieldValue.increment(totalCo2Saved),
          'totalDistanceCovered': FieldValue.increment(totalDistanceCovered),
          'totalPools': FieldValue.increment(totalPools),
        }, SetOptions(merge: true));
      } else {
        print("No user is signed in.");
      }
    }

    if (allPinsCorrect) {
      await _updateUserStats();
      Navigator.pop(context);
      _openMaps();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid pins for all passengers!')),
      );
      Navigator.pop(context);
    }
  }

  void _openMaps() async {
    final startLocation = ride!['startLocation'];
    final endLocation = ride!['endLocation'];

    String googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&origin=${startLocation['latitude']},${startLocation['longitude']}&destination=${endLocation['latitude']},${endLocation['longitude']}';

    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }

  void endRide() async {
    showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(
              color: deepGreen,
            ),
          );
        });
    QuerySnapshot<Map<String, dynamic>> rideSnapshot = await FirebaseFirestore
        .instance
        .collection('Rides')
        .where('offerId', isEqualTo: widget.offerId)
        .limit(1)
        .get();
    if (rideSnapshot.docs.isNotEmpty) {
      DocumentReference<Map<String, dynamic>> rideDocRef =
          rideSnapshot.docs.first.reference;
      await rideDocRef.update({
        'status': 'Completed',
      });
    } else {
      print('No ride found with the specified offerId.');
    }

    DocumentReference offerRef =
        FirebaseFirestore.instance.collection('PoolOffers').doc(widget.offerId);
    await offerRef.update({
      'status': 'Completed',
    });

    for (String passengerId in ride!['passengers']) {
      String notificationId = randomAlphaNumeric(28);
      Map<String, dynamic> notification = {
        'notificationId': notificationId,
        'userId': passengerId,
        'message':
            'Your ride with ${user!.displayName ?? "your pool partner"} has ended. The total fare is ₹${ride!['costPerPassenger'].toStringAsFixed(2)}. Please pay at your earliest convenience.',
        'category': 'payment',
        'timestamp': Timestamp.now(),
      };
      await FirebaseFirestore.instance
          .collection('Notifications')
          .doc(notificationId)
          .set(notification);

      print('Notification(payment) sent to passenger $passengerId');
    }

    Navigator.of(context).pop();
    List<double> ratings = [];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          icon: Icon(
            Icons.star_rate_rounded,
            size: 100,
            color: Colors.amber,
          ),
          title: Row(
            children: [
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Rate Your Passengers',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Please rate each passenger based on the experience.",
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),

                // Dynamically create rating widgets for each passenger
                Column(
                  children: passengerNames.map((passenger) {
                    return Column(
                      children: [
                        Text(
                          passenger,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 5),
                        RatingBar.builder(
                          initialRating: 0,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {
                            ratings.add(rating);
                            print("\n\nRating for $passenger: $rating");
                          },
                        ),
                        SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _updatePassengerRatings(ratings);
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => HomePage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.orangeAccent,
                ),
                child: Text(
                  'Submit Ratings',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Start Ride',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: deepGreen,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: deepGreen,
              ),
            )
          : ride != null
              ? Column(
                  children: [
                    Container(
                      height: 120,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [deepGreen, lightGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Together we can reduce our footprint and make every ride an eco-friendly journey!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            Text(
                              'Ride Details',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                            SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                  color: deepGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ride ID: ${ride!['rideId']}',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54),
                                  ),
                                  Text(
                                    '${DateFormat('EEE dd, MMM').format(ride!['startTime'].toDate())}',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey),
                                  ),
                                  Text(
                                    '${DateFormat('hh:mm a').format(ride!['startTime'].toDate())}',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        children: [
                                          Icon(Icons.circle,
                                              color: Colors.green, size: 12),
                                          SizedBox(height: 5),
                                          Column(
                                            children: List.generate(
                                                3,
                                                (index) => Icon(Icons.more_vert,
                                                    color: Colors.grey,
                                                    size: 12)),
                                          ),
                                          SizedBox(height: 5),
                                          Icon(Icons.location_on,
                                              color: Colors.red, size: 20),
                                        ],
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                '${ride!['startLocationName']}',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87)),
                                            SizedBox(height: 10),
                                            Text('${ride!['endLocationName']}',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87)),
                                            SizedBox(height: 20),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.access_time,
                                                        color: Colors.orange),
                                                    SizedBox(width: 5),
                                                    Text('30 mins',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .black54)),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(Icons.directions_car,
                                                        color: deepGreen),
                                                    SizedBox(width: 5),
                                                    Text('Distance: 10 km',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .black54)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Amount You’ll Receive',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Payment Summary',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Cost Per Passenger'),
                                        Text(
                                            '\₹${ride!['costPerPassenger'].toStringAsFixed(2)}'),
                                      ],
                                    ),
                                    Divider(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Total Passengers'),
                                        Text('${ride!['passengers'].length}'),
                                      ],
                                    ),
                                    Divider(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Total Earnings'),
                                        Text(
                                            '₹${(ride!['costPerPassenger'] * ride!['passengers'].length).toStringAsFixed(2)}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Enter PINs for Passengers',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                            SizedBox(height: 10),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: passengerNames.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        children: [
                                          CircleAvatar(
                                            backgroundImage: NetworkImage(
                                                profilePics[index]),
                                            radius: 20,
                                          ),
                                          SizedBox(width: 15),
                                          Text(
                                            passengerNames[index],
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                      Pinput(
                                        length: 4,
                                        onChanged: (pin) {
                                          setState(() {
                                            pins[index] = pin;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      endRide();
                                    },
                                    child: Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: const Color.fromARGB(
                                            255,
                                            166,
                                            13,
                                            13), // Color for End Ride button
                                      ),
                                      child: Center(
                                        child: const Text(
                                          'End Ride',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 15,
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      _verifyPins();
                                    },
                                    child: Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: deepGreen,
                                      ),
                                      child: Center(
                                        child: const Text(
                                          'Start Journey',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    'No ride details available',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
    );
  }
}
