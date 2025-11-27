// Data Singleton

import 'package:flutter/material.dart';

class DataService extends ChangeNotifier {
  static final DataService _instance = DataService._internal();

  factory DataService() {
    return _instance;
  }

  DataService._internal();

  // Add your data properties and methods here

  String desktopAppUrl = '';
}
