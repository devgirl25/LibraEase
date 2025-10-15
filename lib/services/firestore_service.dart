import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ✅ Signup user with email & password and save details to Firestore
  Future<String?> signupUser({
    required String email,
    required String password,
    required String name,
    required String role, // e.g., "student" or "librarian"
  }) async {
    try {
      // 1. Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      // 2. Save user details in Firestore
      if (user != null) {
        await _db.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "name": name,
          "email": email,
          "role": role,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      return null; // null means success
    } on FirebaseAuthException catch (e) {
      return e.message; // return error message
    } catch (e) {
      return "Something went wrong: $e";
    }
  }
}
