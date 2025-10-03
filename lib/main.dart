import 'package:nightowlcode/bootstrap.dart';
import 'package:nightowlcode/night_owl_app.dart';

void main() {
  bootstrap(() => const NightOwlApp());
}

// in main.dart
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const App());
//   push heavy init off the first frame
  // WidgetsBinding.instance.addPostFrameCallback((_) async {
  //   await Bootstrap()._preBoot;
  // });
// }
//Offload CPU work to an isolate (compute) instead of blocking the UI isolate. //TODO
//Avoid synchronous file I/O during initState of your first screen.
// Turn on the performance overlay during dev to find offenders: