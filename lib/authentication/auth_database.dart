import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class AuthDatabase {
  Future<void> addUser(String userId, Map<String, dynamic> userInfoMap) async {
    try {
      await FirebaseFirestore.instance
          .collection("Users")
          .doc(userId)
          .set(userInfoMap);
      developer.log("User data added successfully!");
    } catch (e) {
      developer.log("Error adding user data: $e");
    }
  }
}
