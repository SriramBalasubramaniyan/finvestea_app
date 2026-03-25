import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finvestea_app/core/services/auth_service.dart';
import 'package:finvestea_app/core/services/portfolio_service.dart';

Future<void> addFireUser(AuthUser user) async {
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  return users
      .add({
        'full_name': user.displayName,
        'id': user.uid,
        'email': user.email
      })
      .then((value) => dev.log("User Added"))
      .catchError((error) => dev.log("Failed to add user: $error"));
}

Future<void> addFireHolding(Holding entry) async {
  CollectionReference users = FirebaseFirestore.instance.collection('investment');

  return users
      .add(entry.toMap())
      .then((value) => dev.log("Investment Added"))
      .catchError((error) => dev.log("Failed to add Investment: $error"));
}

Future<List<Holding>> getFireHoldings() async {
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
    .collection('investment').where('portfolioId', isEqualTo: AuthService().currentUser!.uid).get();

  return querySnapshot.docs.map((doc) {
    return Holding.fromMap(doc.data() as Map<String, dynamic>);
  }).toList();
}