import 'package:firebase_auth/firebase_auth.dart';

class Authenticate {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  Future<UserCredential> signUp(String email, String password) async {
    UserCredential user = await firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    return user;
  }
    Future<UserCredential> logIn(String email, String password) async {
    UserCredential user = await firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    return user;
  }
}
