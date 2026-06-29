import 'package:flutter/cupertino.dart';
import 'package:ibmi/bmi_page.dart';
import 'package:ibmi/history_page.dart';

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MainPageState();
  }
}

class _MainPageState extends State<MainPage> {
  final List<Widget> _tabs =[BMIPage(), HistoryPage()];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text("IBMI", style: TextStyle()),
      ),
      child: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.home),
              label: "BMI",
            ),BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person),
              label: "History",
            )
          ],
        ),
        tabBuilder: (context, index){
          return CupertinoTabView(
            builder: (context){
              return _tabs[index];
            },
          );

        },
      ),
    );
  }
}
