import 'package:flutter/material.dart';
import 'package:frivia/pages/game_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  double? _deviceHeight, _deviceWidth;
  double _currentDifficultyLevel = 0;
  final List<String> _difficultyTexts = ['Easy', 'Medium', 'Hard'];
  final Color _easyColor = Colors.greenAccent;
  final Color _mediumColor = Colors.orangeAccent;
  final Color _hardColor = Colors.redAccent;


  Color get _currentColor {
    switch (_currentDifficultyLevel.toInt()) {
      case 0:
        return _easyColor;
      case 1:
        return _mediumColor;
      case 2:
        return _hardColor;
      default:
        return _easyColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    _deviceHeight = MediaQuery.of(context).size.height;
    _deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: _deviceWidth! * 0.10),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _appTitle(),
                SizedBox(height: _deviceHeight! * 0.05),
                _difficultyCard(),
                SizedBox(height: _deviceHeight! * 0.05),
                _startGameButton()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _appTitle() {
    return Column(
      children: [
        const Text(
          "Frivia",
          style: TextStyle(
            fontSize: 60,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 25,
            color: _currentColor,
            fontWeight: FontWeight.w800,
            fontFamily: 'NataSans'
          ),
          child: Text(
            _difficultyTexts[_currentDifficultyLevel.toInt()],
          ),
        ),
      ],
    );
  }

  Widget _difficultyCard() {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Select Difficulty",
              style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 15),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _currentColor,
                inactiveTrackColor: Colors.white24,
                trackHeight: 4.0,
                thumbColor: _currentColor,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                overlayColor: _currentColor.withOpacity(0.2),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
                activeTickMarkColor: _currentColor,
                inactiveTickMarkColor: Colors.white30,
                valueIndicatorColor: _currentColor,
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Slider(
                label: _difficultyTexts[_currentDifficultyLevel.toInt()],
                min: 0,
                max: 2,
                divisions: 2,
                value: _currentDifficultyLevel,
                onChanged: (_value) {
                  setState(() {
                    _currentDifficultyLevel = _value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _startGameButton() {
    return MaterialButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext _context) {
              return GamePage(
                difficultyLevel:
                _difficultyTexts[_currentDifficultyLevel.toInt()].toLowerCase(),
              );
            },
          ),
        );
      },
      color: _currentColor,
      minWidth: _deviceWidth! * 0.80,
      height: _deviceHeight! * 0.075,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Text(
        "START GAME",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}


