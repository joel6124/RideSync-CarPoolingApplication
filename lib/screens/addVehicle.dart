import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';
import 'package:ride_sync/Model/vehicle.dart';
import 'package:ride_sync/Services/database_service.dart';
import 'package:ride_sync/colours.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({Key? key}) : super(key: key);

  @override
  _AddVehiclePageState createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleService = VehicleDatabaseService();
  final User? user = FirebaseAuth.instance.currentUser;

  TextEditingController makeController = TextEditingController();
  TextEditingController modelController = TextEditingController();
  TextEditingController regNumberController = TextEditingController();
  int carCapacityController = 1;
  String? carType;
  bool isDefaultVehicle = false;

  double mileage = 15.0;
  double energyConsumption = 84.0;

  final RegExp regNumberPattern = RegExp(
    r'(^[A-Z]{2}[0-9]{2}[A-HJ-NP-Z]{1,2}[0-9]{4}$)|(^[0-9]{2}BH[0-9]{4}[A-HJ-NP-Z]{1,2}$)',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Add Vehicle Details',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: deepGreen,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 15),
            ClipRRect(
                borderRadius: BorderRadius.circular(80),
                child: Container(
                  padding: EdgeInsets.only(right: 5, left: 5, bottom: 15),
                  color: const Color.fromARGB(255, 172, 195, 167),
                  child: Image.asset(
                    "assets/car_reg.jpeg",
                    width: 150,
                    height: 150,
                  ),
                )),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Make',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    TextFormField(
                      controller: makeController,
                      decoration: InputDecoration(
                        hintText: 'Enter Vehicle Manufacturer',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: lightGreen),
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: deepGreen),
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the vehicle make';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    const Text('Model',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    TextFormField(
                      controller: modelController,
                      decoration: InputDecoration(
                        hintText: 'Enter Vehicle Model',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: lightGreen),
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: deepGreen),
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the vehicle model';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    const Text('Car Type',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      value: carType,
                      items: ['EV', 'Petrol', 'Diesel'].map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          carType = value;

                          if (carType == 'Petrol' || carType == 'Diesel') {
                            mileage = 15.0;
                          } else if (carType == 'EV') {
                            energyConsumption = 84.0;
                          }
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: lightGreen),
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: deepGreen),
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a Car Type';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    if (carType == 'Petrol' || carType == 'Diesel') ...[
                      Text(
                        'Avg Mileage: ${mileage.toStringAsFixed(1)} km/l',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      Slider(
                        value: mileage,
                        activeColor: deepGreen,
                        thumbColor: lightGreen,
                        min: 5,
                        max: 25,
                        divisions: 20,
                        label: mileage.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            mileage = value;
                          });
                        },
                      ),
                    ] else if (carType == 'EV') ...[
                      Text(
                        'Avg Energy Consumption: ${energyConsumption.toStringAsFixed(1)} Wh/km',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      Slider(
                        value: energyConsumption,
                        activeColor: deepGreen,
                        thumbColor: lightGreen,
                        min: 60,
                        max: 200,
                        divisions: 140,
                        label: energyConsumption.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            energyConsumption = value;
                          });
                        },
                      ),
                    ],
                    SizedBox(height: 15),
                    const Text('Registration Number',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    TextFormField(
                      controller: regNumberController,
                      decoration: InputDecoration(
                        hintText: 'Enter Registration Number',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: lightGreen),
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: deepGreen),
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the registration number';
                        } else if (!regNumberPattern.hasMatch(value)) {
                          return 'Invalid registration number format';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    const Text('Car Capacity',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: List.generate(4, (index) {
                        int seatNumber = index + 1;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              carCapacityController = seatNumber;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 4),
                            child: Container(
                              decoration: BoxDecoration(
                                color: carCapacityController == seatNumber
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
                                    fontSize: 15),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 15),
                    CheckboxListTile(
                      title: const Text(
                        'Set as Default Vehicle',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      contentPadding: EdgeInsets.all(0),
                      value: isDefaultVehicle,
                      onChanged: (bool? value) {
                        setState(() {
                          isDefaultVehicle = value ?? false;
                        });
                      },
                      activeColor: deepGreen,
                      visualDensity:
                          VisualDensity(horizontal: -4, vertical: -4),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 50),
                    GestureDetector(
                      onTap: () async {
                        if (_formKey.currentState!.validate()) {
                          String carId = randomAlphaNumeric(28);
                          Map<String, dynamic> VehicleInfoMap = {
                            'carId': carId,
                            'userId': user!.uid,
                            'carType': carType,
                            'carMake': makeController.text,
                            'carModel': modelController.text,
                            'registrationNumber': regNumberController.text,
                            'carCapacity': carCapacityController,
                            'isDefaultVehicle': isDefaultVehicle,
                            if (carType == "EV")
                              'energyConsumption': energyConsumption
                            else
                              'mileage': mileage,
                          };
                          await _vehicleService.addVehicle(
                              context, carId, VehicleInfoMap);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: deepGreen,
                            borderRadius: BorderRadius.circular(8)),
                        child: Center(
                          child: Text(
                            "Add Vehicle",
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
