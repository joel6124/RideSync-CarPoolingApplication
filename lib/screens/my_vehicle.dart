import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ride_sync/colours.dart';
import 'package:ride_sync/screens/addDrivingLicense.dart';
import 'package:ride_sync/screens/addVehicle.dart';

class MyVehicleScreen extends StatefulWidget {
  const MyVehicleScreen({super.key});

  @override
  State<MyVehicleScreen> createState() => _MyVehicleScreenState();
}

class _MyVehicleScreenState extends State<MyVehicleScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final _cars = FirebaseFirestore.instance.collection('Cars');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          title: const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'My Vehicle',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ),
          backgroundColor: deepGreen,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: StreamBuilder(
                stream: _cars.where('userId', isEqualTo: user?.uid).snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> streamSnaphot) {
                  if (streamSnaphot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: deepGreen,
                      ),
                    );
                  }
                  if (streamSnaphot.hasData &&
                      streamSnaphot.data!.docs.isNotEmpty) {
                    return ListView.builder(
                        itemCount: streamSnaphot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final DocumentSnapshot documentSnapshot =
                              streamSnaphot.data!.docs[index];
                          return VehicleTile(
                            vehicleMakeModel: documentSnapshot['carMake'] +
                                " " +
                                documentSnapshot['carModel'],
                            regNo: documentSnapshot['registrationNumber'],
                            carType: documentSnapshot['carType'],
                            costDesc: (documentSnapshot['carType'] == "EV")
                                ? 'Energy Use: ${documentSnapshot['energyConsumption']} Wh/km'
                                : 'Avg Mileage: ${documentSnapshot['mileage']} km/l',
                            seats: documentSnapshot['carCapacity'],
                            isDefault: documentSnapshot['isDefaultVehicle'],
                          );
                        });
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
                            'No vehicle added yet!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: deepGreen,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Add a vehicle now and start pooling!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ]));
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return AddVehiclePage();
                  }));
                },
                icon: Icon(
                  Icons.local_taxi,
                  color: deepGreen,
                  weight: 16,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    'Add Vehicle',
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
            // const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: deepGreen,
                child: ListTile(
                  leading: Icon(
                    Icons.credit_card,
                    color: Colors.white,
                  ),
                  title: Text(
                    "Offering Rides?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    "Add Driving License",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return AddDrivingLicense();
                    }));
                  },
                ),
              ),
            ),
          ],
        ));
  }
}

class VehicleTile extends StatelessWidget {
  final String vehicleMakeModel;
  final String regNo;
  final String carType;
  final String costDesc;
  final int seats;
  final bool isDefault;

  VehicleTile({
    required this.vehicleMakeModel,
    required this.regNo,
    required this.carType,
    required this.costDesc,
    required this.seats,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: BoxDecoration(
          color: deepGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ListTile(
            leading: ClipOval(
              child: Image.asset('assets/vehicle_details.jpg'),
            ),
            title: Text(
              vehicleMakeModel,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(regNo),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$carType'),
                Text('$costDesc'),
                Text('$seats seats'),
              ],
            ),
            onTap: () {
              // Action when a vehicle is tapped
            },
          ),
        ),
      ),
      if (isDefault)
        Positioned(
          top: 15,
          right: 25,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Text(
              'DEFAULT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.0,
              ),
            ),
          ),
        ),
    ]);
  }
}
