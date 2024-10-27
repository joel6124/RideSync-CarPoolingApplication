import 'package:flutter/material.dart';
import 'package:ride_sync/Services/database_service.dart';
import 'package:ride_sync/colours.dart';
import 'package:ride_sync/widgets/custom_buttom.dart';
import 'package:ride_sync/widgets/custom_textfield.dart';

class AddDrivingLicense extends StatefulWidget {
  @override
  _AddDrivingLicenseState createState() => _AddDrivingLicenseState();
}

class _AddDrivingLicenseState extends State<AddDrivingLicense> {
  final _DrivingLicenseService = DrivingLicenseDatabaseService();
  final TextEditingController _licenseController = TextEditingController();

  String? _validateLicense(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your driver\'s license number';
    }

    String pattern =
        r'^(([A-Z]{2}[0-9]{2})( )|([A-Z]{2}-[0-9]{2}))((19|20)[0-9][0-9])[0-9]{7}$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return 'Please enter a valid driver\'s license number';
    }

    return null;
  }

  void _validateAndSave() {
    String? validationError = _validateLicense(_licenseController.text);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
    } else {
      _DrivingLicenseService.saveLicense(context, _licenseController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Add Driving License',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: deepGreen,
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                const SizedBox(height: 70),
                Container(
                  alignment: Alignment.topCenter,
                  child: const Text(
                    'Driving License Number',
                    style: TextStyle(
                      color: titleGrey,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _licenseController,
                  hintText: "DL Number",
                  context: context,
                  obscureText: false,
                ),
                const SizedBox(height: 50),
              ],
            ),
            GestureDetector(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: CustomButton(
                  onTap: _validateAndSave,
                  txt: 'Validate and Add DL',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
