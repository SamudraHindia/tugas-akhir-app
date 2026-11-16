import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(storage: SharedPreferencesStorage()));
}
