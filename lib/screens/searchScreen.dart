import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:ride_sync/DataHandler/appData.dart';
import 'package:ride_sync/Model/placePred.dart';
import 'package:ride_sync/api_calls/apiMethods.dart';
import 'package:ride_sync/colours.dart';
import 'dart:developer' as developer;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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
    });
    String tempPickUpLoc = Provider.of<AppData>(context, listen: false)
        .pickUpLocation!
        .placeFormattedAddress;
    _pickuplocationController.text = tempPickUpLoc;
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
          'Choose Your Start and End Points',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: deepGreen,
      ),
      body: Column(
        children: [
          Container(
            height: 170,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 4.0,
                  spreadRadius: 0.5,
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(children: [
                TextField(
                  onChanged: (value) {
                    isPickUp = true;
                    updateListOfPlacesPredicted(value);
                  },
                  controller: _pickuplocationController,
                  decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: lightGreen,
                          ),
                          borderRadius: BorderRadius.circular(15)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: deepGreen,
                          ),
                          borderRadius: BorderRadius.circular(15)),
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Color.fromARGB(255, 28, 108, 30),
                      ),
                      hintText: 'Select Pick Up Location'),
                ),
                const SizedBox(height: 10),
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
                          borderRadius: BorderRadius.circular(15)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: deepGreen,
                          ),
                          borderRadius: BorderRadius.circular(15)),
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Color.fromARGB(255, 181, 24, 12),
                      ),
                      hintText: 'Select Drop Location'),
                ),
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
                  onTap: () {
                    if (isPickUp == true) {
                      _pickuplocationController.text =
                          "${placesFound[index].mainText}, ${placesFound[index].secondaryText}";
                      ApiMethods.getPlaceDetails(
                          placesFound[index], true, context);
                    } else {
                      _droplocationController.text =
                          "${placesFound[index].mainText}, ${placesFound[index].secondaryText}";
                      ApiMethods.getPlaceDetails(
                          placesFound[index], false, context);
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
                  color: Colors.grey[400],
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
