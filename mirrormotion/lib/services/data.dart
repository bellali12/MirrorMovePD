// Data Singleton

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataService extends ChangeNotifier {
  static final DataService _instance = DataService._internal();

  factory DataService() {
    return _instance;
  }

  DataService._internal();

  // Add your data properties and methods here

  String desktopAppUrl = '';

  // Get Songs from the songs collection
  Future<List<Map<String, dynamic>>> getSongs() async {
    List<Map<String, dynamic>> songs = [];
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('songs')
        .get();
    for (var doc in snapshot.docs) {
      songs.add(doc.data() as Map<String, dynamic>);
    }
    return songs;
  }
}
