import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:random_string/random_string.dart';
import 'package:ride_sync/DataHandler/appData.dart';
import 'package:ride_sync/Services/database_service.dart';
import 'package:ride_sync/api_calls/apiMethods.dart';
import 'package:ride_sync/colours.dart';
import 'package:ride_sync/screens/result_findPool.dart';

class FindPool extends StatefulWidget {
  const FindPool({super.key});

  @override
  State<FindPool> createState() => _FindPoolState();
}

class _FindPoolState extends State<FindPool> {
  final _findPoolDatabaseService = FindPoolDatabaseService();
  final User? user = FirebaseAuth.instance.currentUser;
  Timestamp? fireStoreTimestamp;
  TextEditingController dateTimeController = TextEditingController();
  int? selectedSeats;
  String? genderPreference = "Both";

  final Completer<GoogleMapController> controllerGoogleMap =
      Completer<GoogleMapController>();
  GoogleMapController? newGoogleMapController;

  Position? pickUpPosition;
  String? currentAddress;

  var initialPos;
  var finalPos;
  var pickUpLatLng;
  var dropOffLatLng;
  var distance = "";
  var duration = "";

  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polyLineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 15.4746,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getDirection(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Find Pool',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: deepGreen,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              // height: 475,
              width: double.infinity,
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  GoogleMap(
                    mapType: MapType.normal,
                    myLocationButtonEnabled: true,
                    zoomGesturesEnabled: true,
                    initialCameraPosition: _kGooglePlex,
                    polylines: polyLineSet,
                    circles: circleSet,
                    markers: markerSet,
                    onMapCreated: (GoogleMapController controller) {
                      controllerGoogleMap.complete(controller);
                      newGoogleMapController = controller;

                      var pickUpPos =
                          Provider.of<AppData>(context, listen: false)
                              .pickUpLocation;
                      LatLng latLngPosition =
                          LatLng(pickUpPos!.latitude, pickUpPos.longitude);
                      CameraPosition cameraPosition =
                          CameraPosition(target: latLngPosition, zoom: 12);
                      newGoogleMapController?.animateCamera(
                          CameraUpdate.newCameraPosition(cameraPosition));
                    },
                  ),
                  Positioned(
                    top: 20,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        "$distance away | Approx. $duration",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15), topRight: Radius.circular(15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 2.0,
                  spreadRadius: 0.5,
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  GestureDetector(
                    onTap: () async {
                      DateTime? selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );

                      if (selectedDate != null) {
                        TimeOfDay? selectedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );

                        if (selectedTime != null) {
                          setState(() {
                            final DateTime fullDateTime = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );

                            String formattedDateTime =
                                DateFormat('EEE, MMM d, h:mm a')
                                    .format(fullDateTime);

                            dateTimeController.text = formattedDateTime;

                            fireStoreTimestamp =
                                Timestamp.fromDate(fullDateTime);
                          });
                        }
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: dateTimeController,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 12.0),
                          suffixIcon: Icon(Icons.date_range),
                          labelText: 'Date and Time',
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: lightGreen,
                              ),
                              borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: deepGreen,
                              ),
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  const Text(
                    'Select Number of Seats',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(4, (index) {
                      int seatNumber = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedSeats = seatNumber;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 4),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selectedSeats == seatNumber
                                  ? deepGreen
                                  : lightGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 13, horizontal: 22),
                            child: Text(
                              '$seatNumber',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 15),
                  const Text(
                    'Gender Preference',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 20,
                    children: [
                      ChoiceChip(
                        label: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          child: Text('Male'),
                        ),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (genderPreference == "Male")
                                ? Colors.white
                                : null),
                        selectedColor: deepGreen,
                        selected: genderPreference == 'Male',
                        onSelected: (selected) {
                          setState(() {
                            genderPreference = selected ? 'Male' : null;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          child: Text('Female'),
                        ),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (genderPreference == "Female")
                                ? Colors.white
                                : null),
                        selectedColor: deepGreen,
                        selected: genderPreference == 'Female',
                        onSelected: (selected) {
                          setState(() {
                            genderPreference = selected ? 'Female' : null;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          child: Text('Both'),
                        ),
                        checkmarkColor: Colors.white,
                        selected: genderPreference == 'Both',
                        selectedColor: deepGreen,
                        labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (genderPreference == "Both")
                                ? Colors.white
                                : null),
                        // color: MaterialStatePropertyAll(Colors.amber),
                        onSelected: (selected) {
                          setState(() {
                            genderPreference = selected ? 'Both' : null;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (selectedSeats == null ||
                          genderPreference == null ||
                          fireStoreTimestamp == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in a details!'),
                          ),
                        );
                        return;
                      }

                      String requestId = randomAlphaNumeric(28);
                      Map<String, dynamic> PoolFindInfoMap = {
                        'requestId': requestId,
                        'userId': user!.uid,
                        'startLocation': {
                          'latitude': initialPos!.latitude,
                          'longitude': initialPos.longitude,
                        },
                        'endLocation': {
                          'latitude': finalPos!.latitude,
                          'longitude': finalPos.longitude,
                        },
                        'time': fireStoreTimestamp,
                        'seatsRequested': selectedSeats,
                        'preferredGender': genderPreference,
                        'status': "Pending",
                      };

                      await _findPoolDatabaseService.addPoolFind(
                          context, requestId, PoolFindInfoMap);

                      // final appData =
                      //     Provider.of<AppData>(context, listen: false);

                      // if (appData.pickUpLocation != null) {
                      //   print(appData.pickUpLocation!.placeName);
                      //   print(appData.pickUpLocation!.placeFormattedAddress);
                      //   print(appData.pickUpLocation!.latitude);
                      //   print(appData.pickUpLocation!.longitude);
                      // } else {
                      //   print('Pick-up location is null');
                      // }
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) {
                        return ResultFindPool(
                          requestId: requestId,
                          userStartLat: initialPos!.latitude,
                          userStartLng: initialPos!.longitude,
                          userEndLat: finalPos!.latitude,
                          userEndLng: finalPos!.longitude,
                          genderPreference: genderPreference ?? "Both",
                          fireStoreTimestamp:
                              fireStoreTimestamp ?? Timestamp.now(),
                          seatsRequested: selectedSeats ?? 0,
                          distance: distance,
                        );
                      }));
                    },
                    child: Container(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: deepGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            "Find Pool",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )),
                  ),
                  // SizedBox(height: 15),
                  // const Text(
                  //   'Recurring Ride',
                  //   style:
                  //       TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getDirection(BuildContext context) async {
    initialPos = Provider.of<AppData>(context, listen: false).pickUpLocation;
    finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;
    pickUpLatLng = LatLng(initialPos!.latitude, initialPos.longitude);
    dropOffLatLng = LatLng(finalPos!.latitude, finalPos.longitude);
    showDialog(
        context: context,
        builder: (context) {
          return Center(
            child: CircularProgressIndicator(
              color: deepGreen,
            ),
          );
        });
    var directionDetails =
        await ApiMethods.getDirections(pickUpLatLng, dropOffLatLng);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(directionDetails!.encodedPoints),
      ),
    );
    distance = directionDetails.distanceText;
    duration = directionDetails.durationText;
    PolylinePoints polylinepoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResult =
        polylinepoints.decodePolyline(directionDetails.encodedPoints);
    pLineCoordinates.clear();
    if (decodedPolyLinePointsResult.isNotEmpty) {
      decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    polyLineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
          polylineId: PolylineId("PolylineId"),
          jointType: JointType.round,
          color: Colors.black,
          points: pLineCoordinates,
          width: 3,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true);
      polyLineSet.add(polyline);
    });

    //To fit polyine in screen
    LatLngBounds latLngBounds;
    if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
        pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    } else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
          northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    } else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
          northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }
    newGoogleMapController!
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocationMarker = Marker(
        markerId: MarkerId("pickUpId"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow:
            InfoWindow(title: initialPos.placeName, snippet: "Pick Up Point"),
        position: pickUpLatLng);
    Marker dropOffLocationMarker = Marker(
        markerId: MarkerId("dropOffId"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:
            InfoWindow(title: finalPos.placeName, snippet: "Drop Off Point"),
        position: dropOffLatLng);

    setState(() {
      markerSet.add(pickUpLocationMarker);
      markerSet.add(dropOffLocationMarker);
    });
  }
}

// MARKER CUSTOM IMG
// Marker pickUpLocationMarker = Marker(
//         markerId: MarkerId("pickUpId"),
//         icon: await BitmapDescriptor.asset(
//             ImageConfiguration(devicePixelRatio: 3.2),
//             "assets/pickUpMarker.png"),
//         infoWindow:
//             InfoWindow(title: initialPos.placeName, snippet: "Pick Up Point"),
//         position: pickUpLatLng);