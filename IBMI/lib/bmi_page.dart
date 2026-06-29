import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:ibmi/info_card.dart';
import 'package:flutter/cupertino.dart';


class BMIPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _BMIPageState();
  }
}

class _BMIPageState extends State<BMIPage> {
  double? _deviceWidth, _deviceHeight;
  int _age = 25,
      _weight = 60,
      _height = 70,
      _gender = 0;

  @override
  Widget build(BuildContext context) {
    _deviceHeight = MediaQuery
        .of(context)
        .size
        .height;
    _deviceWidth = MediaQuery
        .of(context)
        .size
        .width;

    return Center(
      child: CupertinoPageScaffold(
        child: Container(
          height: _deviceHeight! * 0.90,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [_ageSelectContainer(), _weightSelectContainer()],
              ),
              _heightSelectContainer(),
              _genderSelectContainer(),
              _calculateBMI(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ageSelectContainer() {
    return InfoCard(
      height: _deviceHeight! * 0.20,
      width: _deviceWidth! * 0.45,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Age Year',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          Text(
            _age.toString(),
            style: TextStyle(fontSize: 45, fontWeight: FontWeight.w800),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      if (_age > 0) _age--;
                    });
                  },
                  child: const Text(
                    '-',
                    style: TextStyle(fontSize: 25, color: CupertinoColors.systemRed),
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _age++;
                    });
                  },
                  child: const Text(
                    '+',
                    style: TextStyle(fontSize: 25, color: CupertinoColors.systemGreen),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weightSelectContainer() {
    return InfoCard(
      height: _deviceHeight! * 0.20,
      width: _deviceWidth! * 0.45,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Weight kgs',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          Text(
            _weight.toString(),
            style: TextStyle(fontSize: 45, fontWeight: FontWeight.w800),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      if (_weight > 0) _weight--;
                    });
                  },
                  child: const Text(
                    '-',
                    style: TextStyle(fontSize: 25, color: CupertinoColors.systemRed),
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _weight++;
                    });
                  },
                  child: const Text(
                    '+',
                    style: TextStyle(fontSize: 25, color: CupertinoColors.activeGreen),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heightSelectContainer() {
    return InfoCard(
      height: _deviceHeight! * 0.15,
      width: _deviceWidth! * 0.90,
      child: Column(
        children: [
          Text(
            'Height in Inches',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          Text(
            _height.toString(),
            style: TextStyle(fontSize: 45, fontWeight: FontWeight.w800),
          ),
          SizedBox(
            width: _deviceWidth! * 0.80,
            child: CupertinoSlider(
              min: 0,
              max: 100,
              divisions: 100,
              value: _height.toDouble(),
              onChanged: (_value) {
                setState(() {
                  _height = _value.toInt();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderSelectContainer() {
    return InfoCard(
      height: _deviceHeight! * 0.11,
      width: _deviceWidth! * 0.90,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Gender',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          CupertinoSlidingSegmentedControl(
            backgroundColor: CupertinoColors.systemGrey,
            thumbColor: CupertinoColors.systemGroupedBackground,
            groupValue: _gender,
            children: const {0: Text("Male"), 1: Text("Female")},
            onValueChanged: (_value) {
              setState(() {
                _gender = _value as int;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _calculateBMI() {
    return Container(
      height: _deviceHeight! * 0.07,
      child: CupertinoButton.filled(
        child: const Text('Calculate BMI'),
        onPressed: () {
          if (_height > 0 && _weight > 0 && _age > 0) {
            double _bmi = _weight / pow(_height * 0.0254, 2);
            _showDialogResult(_bmi);
          }
        },
      ),
    );
  }

  void _showDialogResult(double _bmi) {
    String? _status;
    if (_bmi < 18.5) {
      _status = "Underweight";
    } else if (_bmi >= 18.5 && _bmi < 25) {
      _status = "Normal";
    } else if (_bmi >= 25 && _bmi < 30) {
      _status = "Overweight";
    } else if (_bmi >= 30) {
      _status = "Obese";
    }
    showCupertinoDialog(
      context: context,
      builder: (BuildContext _context) {
        return CupertinoAlertDialog(
          title: Text(_status!),
          content: Text(_bmi.toStringAsFixed(2)),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                _saveResult(_bmi.toString(), _status!);
                Navigator.pop(_context);
              },
            ),
          ],
        );
      },
    );
  }

  void _saveResult(String _bmi, String _status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'bmi_date',
      DateTime.now().toString(),
    );
    await prefs.setStringList(
      'bmi_data',
      <String>[
        _bmi,
        _status,
      ],
    );
  }
}
