import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/data/goal_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MetasApp(repository: GoalRepository()));
}
