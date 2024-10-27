import 'package:cloud_firestore/cloud_firestore.dart';

class Sample {
  Future<void> addSample() async {
    print('reached');
    FirebaseFirestore.instance
        .collection("testCollection")
        .add({"testField": "testValue"}).then((value) {
      print("Test data added successfully!");
    }).catchError((error) {
      print("Failed to add test data: $error");
    });
  }
}
