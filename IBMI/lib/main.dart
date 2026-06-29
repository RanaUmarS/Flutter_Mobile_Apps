// import 'package:flutter/cupertino.dart';
// import 'package:flutter/services.dart';
// import 'package:ibmi/main_page.dart';
//
// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   SystemChrome.setEnabledSystemUIMode(
//     SystemUiMode.manual,
//     overlays: [SystemUiOverlay.bottom],
//   );
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return CupertinoApp(
//       debugShowCheckedModeBanner: false,
//       title: "IBMI",
//       routes: {'/': (BuildContext _context) => MainPage()},
//       initialRoute: '/',
//     );
//   }
// }

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:ibmi/main_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.bottom],
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: "IBMI",
      routes: {'/': (BuildContext _context) => MainPage()},
      initialRoute: '/',
      theme: const CupertinoThemeData(
        brightness: Brightness.dark, // dark mode like your screenshot
        primaryColor: CupertinoColors.activeBlue,
      ),
    );
  }
}
