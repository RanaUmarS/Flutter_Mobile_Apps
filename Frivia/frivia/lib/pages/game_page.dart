import 'package:flutter/material.dart';
import 'package:frivia/providers/game_page_providers.dart';
import 'package:provider/provider.dart';

class GamePage extends StatelessWidget {
  double? _deviceHeight, _deviceWidth;
  final String difficultyLevel;
  GamePageProvider? _pageProvider;

  GamePage({required this.difficultyLevel});

  @override
  Widget build(BuildContext context) {
    _deviceHeight = MediaQuery.of(context).size.height;
    _deviceWidth = MediaQuery.of(context).size.width;
    return ChangeNotifierProvider(
      create: (_context) => GamePageProvider(context: context, difficultyLevel: difficultyLevel),
      child: _buildUI(),
    );
  }

  Widget _buildUI() {
    return Builder(
      builder: (_context) {
        _pageProvider = _context.watch<GamePageProvider>();
        if (_pageProvider?.questions != null) {
          return Scaffold(
            backgroundColor: const Color.fromRGBO(31, 31, 31, 1.0),
            body: SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _deviceHeight! * 0.03,
                ),
                child: _gameUI(),
              ),
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
      },
    );
  }

  Widget _gameUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _questionCard(),
        Column(
          children: [
            _trueButton(),
            SizedBox(height: _deviceHeight! * 0.02),
            _falseButton(),
          ],
        ),
      ],
    );
  }

  Widget _questionCard() {
    return Consumer<GamePageProvider>(
      builder: (context, provider, child) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(_deviceHeight! * 0.025),
          margin: EdgeInsets.symmetric(vertical: _deviceHeight! * 0.02),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(45, 45, 45, 1.0),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.deepPurple.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _deviceWidth! * 0.04,
                      vertical: _deviceHeight! * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple[700],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      "Question ${provider.currentQuestionCount + 1}/10",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _deviceWidth! * 0.04,
                      vertical: _deviceHeight! * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _getDifficultyColor(),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      difficultyLevel.toUpperCase(),
                      style: TextStyle(
                        color: _getDifficultyColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: _deviceHeight! * 0.03),

              Container(
                padding: EdgeInsets.all(_deviceHeight! * 0.02),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    provider.getCurrentQuestionText(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              SizedBox(height: _deviceHeight! * 0.02),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.help_outline,
                    color: Colors.deepPurple[300],
                    size: 16,
                  ),
                  SizedBox(width: _deviceWidth! * 0.02),
                  Text(
                    "Select True or False",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _trueButton() {
    return MaterialButton(
      onPressed: () {
        _pageProvider?.answerQuestion("True");
      },
      color: Colors.green[700],
      minWidth: _deviceWidth! * 0.8,
      height: _deviceHeight! * 0.10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Text(
        'True',
        style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _falseButton() {
    return MaterialButton(
      onPressed: () {
        _pageProvider?.answerQuestion("False");
      },
      color: Colors.red[700],
      minWidth: _deviceWidth! * 0.8,
      height: _deviceHeight! * 0.10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Text(
        'False',
        style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (difficultyLevel.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.deepPurple;
    }
  }
}