import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dot_curved_bottom_nav/dot_curved_bottom_nav.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ride_sync/DataHandler/appData.dart';
import 'package:ride_sync/Model/address.dart';
import 'package:ride_sync/api_calls/apiMethods.dart';
import 'package:ride_sync/colours.dart';
import 'package:ride_sync/screens/drawer_navbar.dart';
import 'package:ride_sync/screens/endSearchScreen.dart';
import 'package:ride_sync/screens/notifications.dart';
import 'package:ride_sync/screens/searchScreen.dart';
import 'package:ride_sync/screens/startSearchScreen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _fetchNotificationCount();
  }

  int notificationCount = 0;
  TextEditingController _pickuplocationController = TextEditingController();
  TextEditingController _droplocationController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  int methodOfPool = 0;

  final Completer<GoogleMapController> controllerGoogleMap =
      Completer<GoogleMapController>();
  GoogleMapController? newGoogleMapController;

  Position? currentPosition;
  String? currentAddress;
  var geoLocator = Geolocator();

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please Keep Your Location On'),
        ),
      );
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location Permission is Denied!'),
        ),
      );
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Permission is Denied Forever!'),
        ),
      );
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    LatLng latLngPosition = LatLng(position.latitude, position.longitude);
    CameraPosition cameraPosition =
        CameraPosition(target: latLngPosition, zoom: 15);
    newGoogleMapController
        ?.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String currentAddress =
        await ApiMethods.searchCoordinateAddress(position, context);

    // Provider.of<AppData>(context, listen: false).updatePickUpLocationAddress(
    //   Address(
    //     placeFormattedAddress: currentAddress,
    //     placeName: "Current Location",
    //     placeId: "current_location_id",
    //     latitude: position.latitude,
    //     longitude: position.longitude,
    //   ),
    // );
  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Future<void> _fetchNotificationCount() async {
    User? user = FirebaseAuth.instance.currentUser;
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Notifications')
        .where('userId', isEqualTo: user!.uid)
        .get();

    setState(() {
      notificationCount = querySnapshot.size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Ride',
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  TextSpan(
                    text: 'Sync',
                    style: GoogleFonts.raleway(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            )),
        centerTitle: true,
        backgroundColor: deepGreen,
        actions: [
          Stack(
            children: [
              IconButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return NotificationsScreen();
                    }));
                  },
                  icon: Icon(Icons.notifications)),
              Positioned(
                right: 10,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    '$notificationCount',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              color: Colors.amber,
              icon: const Icon(
                Icons.reorder,
                size: 24,
                weight: 100,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer_Navbar(),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;
              _determinePosition();
            },
          ),
          Positioned(
            left: 16.0,
            right: 16.0,
            bottom: 90.0,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    spreadRadius: 0.5,
                  )
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Consumer<AppData>(
                  builder: (context, appData, child) {
                    if (appData.pickUpLocation != null) {
                      _pickuplocationController.text =
                          appData.pickUpLocation!.placeFormattedAddress;
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        const Text(
                          'Hi There',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Select Location',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  borderRadius: BorderRadius.circular(25),
                                  color: Colors.amber),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                child: Text(
                                  methodOfPool == 1
                                      ? 'Offer Pool'
                                      : 'Find Pool',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: ((context) {
                              return StartSearchScreen();
                            })));
                          },
                          child: AbsorbPointer(
                            child: TextField(
                              controller: _pickuplocationController,
                              decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.location_on,
                                    color: Color.fromARGB(255, 28, 108, 30),
                                  ),
                                  hintText: 'Select Pick Up Location'),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: ((context) {
                              return EndSearchScreen(
                                methodOfPool: methodOfPool,
                              );
                            })));
                          },
                          child: TextField(
                            enabled: false,
                            controller: _droplocationController,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(
                                  Icons.location_off,
                                  color: Color.fromARGB(255, 181, 24, 12),
                                ),
                                hintText: 'Select Drop Location'),
                          ),
                        ),
                        const SizedBox(
                          height: 50,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DotCurvedBottomNav(
        scrollController: _scrollController,
        hideOnScroll: true,
        indicatorColor: deepGreen,
        backgroundColor: deepGreen,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.ease,
        selectedIndex: methodOfPool,
        indicatorSize: 5.5,
        borderRadius: 25,
        height: 70,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        onTap: (index) {
          setState(() => methodOfPool = index);
        },
        items: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_car,
                color: Colors.white,
              ),
              SizedBox(
                width: 5,
              ),
              Text(
                'Find Pool',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.local_taxi,
                color: Colors.white,
              ),
              SizedBox(
                width: 5,
              ),
              Text(
                'Offer Pool',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              )
            ],
          ),
        ],
      ),
    );
  }
}
