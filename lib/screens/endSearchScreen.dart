import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:ride_sync/DataHandler/appData.dart';
import 'package:ride_sync/Model/placePred.dart';
import 'package:ride_sync/api_calls/apiMethods.dart';
import 'package:ride_sync/colours.dart';
import 'dart:developer' as developer;

import 'package:ride_sync/screens/find_pool.dart';
import 'package:ride_sync/screens/offer_pool.dart';

class EndSearchScreen extends StatefulWidget {
  const EndSearchScreen({super.key, required this.methodOfPool});
  final int methodOfPool;

  @override
  State<EndSearchScreen> createState() => _EndSearchScreenState();
}

class _EndSearchScreenState extends State<EndSearchScreen> {
  List<PlacePredictions> placesFound = [];
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _pickuplocationController =
      TextEditingController();
  final TextEditingController _droplocationController = TextEditingController();
  bool isPickUp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
      String tempPickUpLoc = Provider.of<AppData>(context, listen: false)
          .pickUpLocation!
          .placeFormattedAddress;
      _pickuplocationController.text = tempPickUpLoc;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _droplocationController.dispose();
    super.dispose();
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
          'Choose Your End Location',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: deepGreen,
      ),
      body: Column(
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 2.0,
                  spreadRadius: 0.5,
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(children: [
                TextField(
                  focusNode: _focusNode,
                  onChanged: (value) {
                    isPickUp = false;
                    updateListOfPlacesPredicted(value);
                  },
                  controller: _droplocationController,
                  decoration: InputDecoration(
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
                      prefixIcon: const Icon(
                        Icons.location_off,
                        color: Color.fromARGB(255, 181, 24, 12),
                      ),
                      labelText: 'Select Drop Location'),
                ),
                const SizedBox(height: 10),
              ]),
            ),
          ),
          SizedBox(
            height: 12,
          ),
          Expanded(
            child: ListView.separated(
              itemCount: placesFound.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  onTap: () async {
                    _droplocationController.text =
                        "${placesFound[index].mainText}, ${placesFound[index].secondaryText}";
                    await ApiMethods.getPlaceDetails(
                        placesFound[index], false, context);
                    if (widget.methodOfPool == 0) {
                      // await getDirection(context);
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) {
                        return FindPool();
                      }));
                    } else {
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) {
                        return OfferPool();
                      }));
                    }
                  },
                  leading: Icon(Icons.add_location),
                  title: Text(
                    overflow: TextOverflow.ellipsis,
                    placesFound[index].mainText,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: titleGrey),
                  ),
                  subtitle: Text(
                    overflow: TextOverflow.ellipsis,
                    placesFound[index].secondaryText,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: subtitleGrey),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return Divider(
                  color: Colors.grey[600],
                  thickness: 1.0,
                  indent: 8.0,
                  endIndent: 8.0,
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Future<void> updateListOfPlacesPredicted(String placeName) async {
    if (placeName.isNotEmpty) {
      List<PlacePredictions> result =
          await ApiMethods.findPlace(placeName, context);
      setState(() {
        placesFound = result;
        developer.log(placesFound[0].placeId);
        developer.log(placesFound[1].mainText);
        developer.log(placesFound[2].secondaryText);
      });
    } else {
      setState(() {
        placesFound = [];
      });
    }
  }
}
