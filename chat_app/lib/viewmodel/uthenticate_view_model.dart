import 'dart:io';

import 'package:chat_app/firebase/authenticate_firebase.dart';
import 'package:chat_app/firebase/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AuthenticatedViewModel with ChangeNotifier {
  Authenticate authenticated = Authenticate();
  bool _isLoading = false;
  get isLoading => _isLoading;

  setLoading(bool isloading) {
    _isLoading = isloading;
    notifyListeners();
  }

  Future<void> signUp(String email, String password, String username,
      File? image, context) async {
    setLoading(true);
    authenticated.signUp(email, password).then((value) async {
      final imageUrl =
          await FirebaseStorages(firebaseStorage: FirebaseStorage.instance)
              .uploadFile(image!, "image");

      await FirebaseFirestore.instance
          .collection("user")
          .doc(value.user!.uid)
          .set({
        "uid": value.user!.uid,
        "email": email,
        "username": username,
        "imageUrl": imageUrl,
      });
      image = null;
      setLoading(false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Login success")));
    }).onError((error, stackTrace) {
      setLoading(false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    });
  }

  Future<void> logIn(
      String email, String password, BuildContext context) async {
    setLoading(true);
    authenticated.logIn(email, password).then((value) {
      setLoading(false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Login success")));
    }).onError((error, stackTrace) {
      setLoading(false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    });
  }
}
