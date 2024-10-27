import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:ride_sync/DataHandler/appData.dart';
import 'package:ride_sync/Model/placePred.dart';
import 'package:ride_sync/api_calls/apiMethods.dart';
import 'package:ride_sync/colours.dart';
import 'dart:developer' as developer;

class StartSearchScreen extends StatefulWidget {
  const StartSearchScreen({super.key});

  @override
  State<StartSearchScreen> createState() => _StartSearchScreenState();
}

class _StartSearchScreenState extends State<StartSearchScreen> {
  List<PlacePredictions> placesFound = [];
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _pickuplocationController =
      TextEditingController();

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
    _pickuplocationController.dispose();
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
          'Choose Your Start Location',
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
              child: Column(
                children: [
                  TextField(
                    focusNode: _focusNode,
                    onChanged: (value) {
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
                        labelText: 'Select Pick Up Location'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
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
                    _pickuplocationController.text =
                        "${placesFound[index].mainText}, ${placesFound[index].secondaryText}";
                    await ApiMethods.getPlaceDetails(
                        placesFound[index], true, context);
                    Navigator.of(context).pop();
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
