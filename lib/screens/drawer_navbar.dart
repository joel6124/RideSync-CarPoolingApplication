import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ride_sync/authentication/auth_service.dart';
import 'package:ride_sync/colours.dart';
import 'package:ride_sync/screens/ecodashboard.dart';
import 'package:ride_sync/screens/my_vehicle.dart';
import 'package:ride_sync/screens/notifications.dart';
import 'package:ride_sync/screens/profile.dart';
import 'package:ride_sync/screens/rides.dart';

class Drawer_Navbar extends StatelessWidget {
  Drawer_Navbar({super.key});

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              Container(
                height: 250,
                child: UserAccountsDrawerHeader(
                  currentAccountPicture: SizedBox(
                    width: 90,
                    height: 90,
                    child: CircleAvatar(
                      child: ClipOval(
                        child: Image.network(
                          user?.photoURL ??
                              'https://icon-library.com/images/user-icon-jpg/user-icon-jpg-0.jpg',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  accountName: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Users')
                        .doc(user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error fetching name');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('Loading...');
                      }

                      String name = snapshot.data?['name'] ?? 'User';

                      return Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  accountEmail: Text(
                    user?.email ?? 'No Email',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: deepGreen,
                    image: DecorationImage(
                      image: AssetImage('assets/drawer_bg2.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 40,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return ProfilePage();
                    }));
                  },
                  child: Icon(
                    Icons.arrow_forward_ios_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 30,
          ),
          ListTile(
            leading: Icon(
              Icons.local_taxi_rounded,
              color: deepGreen,
            ),
            title: const Text('My Rides'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return RidesPage();
              }));
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.eco_rounded,
              color: lightGreen,
            ),
            title: const Text('Eco Dashboard'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return EcoDashboardScreen();
              }));
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.directions_car,
              color: Colors.purple,
            ),
            title: const Text('My Vehicle'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return MyVehicleScreen();
              }));
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.notifications,
              color: Colors.amber,
            ),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return NotificationsScreen();
              }));
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Color.fromARGB(255, 181, 24, 12),
            ),
            title: const Text('Logout'),
            onTap: () {
              AuthService().SignOut();
            },
          ),
          Divider(),
        ],
      ),
    );
  }
}
