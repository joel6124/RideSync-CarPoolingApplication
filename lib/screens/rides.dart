import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ride_sync/Services/database_service.dart';
import 'package:ride_sync/colours.dart';
import 'package:ride_sync/screens/home.dart';
import 'package:ride_sync/screens/startRide.dart';

class RidesPage extends StatefulWidget {
  @override
  _RidesPageState createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _RidesDatabaseService = RidesDatabaseService();

  String? currentUserId;

  List<DocumentSnapshot> upcomingRides = [];
  List<DocumentSnapshot> completedRides = [];
  List<DocumentSnapshot> cancelledRides = [];
  List<DocumentSnapshot> offeredRides = [];
  var ride;
  var offer;
  // bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    // _fetchRides();
  }

  Future<void> _getCurrentUser() async {
    User? user = _auth.currentUser;
    setState(() {
      currentUserId = user?.uid;
    });
  }

  Stream<List<dynamic>> _fetchRides() async* {
    if (currentUserId == null) return;

    try {
      // Fetch rides and pool offers
      Stream<QuerySnapshot> ridesStream =
          _firestore.collection('Rides').snapshots();
      Stream<QuerySnapshot> offersStream = _firestore
          .collection('PoolOffers')
          .where('userId', isEqualTo: currentUserId)
          .snapshots();

      await for (var ridesSnapshot in ridesStream) {
        var offersSnapshot = await offersStream.first;
        yield [
          ridesSnapshot.docs,
          offersSnapshot.docs,
        ];
      }
    } catch (e) {
      print("Error fetching rides: $e");
      yield [];
    }
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
          'My Rides',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: deepGreen,
      ),
      body: StreamBuilder<List<dynamic>>(
          stream: _fetchRides(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: deepGreen,
                ),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('No rides available');
            } else {
              List<DocumentSnapshot> rides = snapshot.data![0];
              List<DocumentSnapshot> offers = snapshot.data![1];

              List<DocumentSnapshot> upcomingRides = rides.where((ride) {
                bool isPassenger =
                    (ride['passengers'] as List).contains(currentUserId);
                return isPassenger && ride['status'] == 'Pending';
              }).toList();

              List<DocumentSnapshot> completedRides = rides.where((ride) {
                bool isPassenger =
                    (ride['passengers'] as List).contains(currentUserId);
                return isPassenger && ride['status'] == 'Completed';
              }).toList();

              List<DocumentSnapshot> cancelledRides = rides.where((ride) {
                bool isPassenger =
                    (ride['passengers'] as List).contains(currentUserId);
                return isPassenger && ride['status'] == 'Cancelled';
              }).toList();

              List<DocumentSnapshot> offeredRides = rides.where((ride) {
                return offers
                    .any((offer) => offer['offerId'] == ride['offerId']);
              }).toList();
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      height: 25,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        "Pool Requests",
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (upcomingRides.isNotEmpty) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              "Upcoming Rides",
                              style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: titleGrey),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: upcomingRides.length,
                            itemBuilder: (context, index) {
                              var ride = upcomingRides[index];
                              return RideCard(
                                  context, Colors.amber, ride, true);
                            },
                          ),
                        ],
                      )
                    ],
                    if (completedRides.isNotEmpty) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              "Completed Rides",
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: completedRides.length,
                            itemBuilder: (context, index) {
                              ride = completedRides[index];
                              return RideCard(
                                  context, Colors.green, ride, false);
                            },
                          ),
                        ],
                      )
                    ],
                    if (cancelledRides.isNotEmpty) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              "Cancelled Rides",
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: cancelledRides.length,
                            itemBuilder: (context, index) {
                              var ride = cancelledRides[index];
                              return RideCard(context, Colors.red, ride, false);
                            },
                          ),
                        ],
                      )
                    ],
                    if (upcomingRides.isEmpty &&
                        completedRides.isEmpty &&
                        cancelledRides.isEmpty) ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'No Pools Requested yet..!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: deepGreen,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (offeredRides.isNotEmpty) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              "Pool Offers",
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: offeredRides.length,
                            itemBuilder: (context, index) {
                              offer = offeredRides[index];
                              return OfferRideCard(context, offer);
                            },
                          ),
                        ],
                      )
                    ],
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) {
                            return HomePage();
                          }));
                        },
                        icon: Icon(
                          Icons.add,
                          color: deepGreen,
                          weight: 16,
                        ),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Text(
                            'Create Ride',
                            style: TextStyle(
                                color: deepGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          }),
    );
  }

  Widget OfferRideCard(BuildContext context, DocumentSnapshot offer) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: deepGreen.withOpacity(0.1),
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Offer ID: ${offer['offerId']}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: titleGrey),
              ),
              Text(
                '${DateFormat('EEE dd, MMM').format(offer['startTime'].toDate())}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: titleGrey),
              ),
              Text(
                '${DateFormat('hh:mm a').format(offer['startTime'].toDate())}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 12),
                      SizedBox(height: 5),
                      Column(
                        children: List.generate(
                          3,
                          (index) => Icon(Icons.more_vert,
                              color: Colors.grey, size: 12),
                        ),
                      ),
                      SizedBox(height: 5),
                      Icon(Icons.location_on, color: Colors.red, size: 20),
                    ],
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${offer['startLocationName']}',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        SizedBox(height: 20),
                        Text(
                          '${offer['endLocationName']}',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_walk, size: 20),
                        Text('Distance: ${offer['distance']} km',
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (offer['status'] == 'Pending') ...[
                      ElevatedButton(
                        onPressed: () {
                          _RidesDatabaseService.cancelRideOffer(context, offer);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: deepGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          textStyle: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Cancel Offer'),
                      )
                    ] else if (offer['status'] == 'Cancelled') ...[
                      Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(10),
                            color: const Color.fromARGB(255, 214, 26, 13)),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            'Pool Offer Cancelled',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.green),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            'Completed',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              if (offer['status'] == 'Pending') ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StartRidePage(offerId: offer['offerId']),
                      ),
                    );
                    // Logic to cancel ride request can be added here
                    // _RidesDatabaseService.cancelRideRequest(context, ride);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Start Ride'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget RideCard(BuildContext context, Color color, DocumentSnapshot ride,
      bool isUpcoming) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: deepGreen.withOpacity(0.1),
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ride ID: ${ride['rideId']}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: titleGrey),
              ),
              Text(
                '${DateFormat('EEE dd, MMM').format(ride['startTime'].toDate())}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: titleGrey),
              ),
              Text(
                '${DateFormat('hh:mm a').format(ride['startTime'].toDate())}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 12),
                      SizedBox(height: 5),
                      Column(
                        children: List.generate(
                            3,
                            (index) => Icon(Icons.more_vert,
                                color: Colors.grey, size: 12)),
                      ),
                      SizedBox(height: 5),
                      Icon(Icons.location_on, color: Colors.red, size: 20),
                    ],
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ride['startLocationName']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          '${ride['endLocationName']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              if (isUpcoming) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Logic to cancel ride request can be added here
                        _RidesDatabaseService.cancelRideRequest(context, ride);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deepGreen,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel Ride Request'),
                    ),
                  ],
                )
              ],
            ],
          ),
          Positioned(
            right: 1,
            top: 3,
            child: Container(
              decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(10),
                  color: color),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Text(
                  (ride['status'] == 'Pending' || ride['status'] == 'Accepted')
                      ? 'Upcoming'
                      : (ride['status'] == 'Completed')
                          ? 'Completed'
                          : 'Cancelled',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
