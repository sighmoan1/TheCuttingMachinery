import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/meditation.dart';
import 'data/meditations.dart';
import 'widgets/player.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MeditationModel(),
      child: MeditationApp(),
    ),
  );
}

// ignore: must_be_immutable
class MeditationApp extends StatelessWidget {
  Timer? _timer;

  void _incrementCounter(
      BuildContext context, int hoursChange, int daysChange) {
    final meditationModel =
        Provider.of<MeditationModel>(context, listen: false);
    meditationModel.updateStatistic(hoursChange, daysChange);

    _timer = Timer.periodic(Duration(milliseconds: 200), (timer) {
      meditationModel.updateStatistic(hoursChange, daysChange);
    });
  }

  void _cancelIncrement(BuildContext context) {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFF9a1c20),
        appBar: AppBar(
            title: Row(
              children: [
                Text('The Cutting Machinery'),
              ],
            ),
            backgroundColor: Color(0xFF9a1c20)),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(height: 32),
              Consumer<MeditationModel>(
                builder: (context, meditationModel, child) => Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                    ),
                    Text(
                      'Streak Days: ${meditationModel.statistic.streakDays}',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Listener(
                          onPointerDown: (details) {
                            _incrementCounter(context, 0, -1);
                          },
                          onPointerUp: (details) {
                            _cancelIncrement(context);
                          },
                          child: GestureDetector(
                            child: Icon(Icons.remove,
                                color: Colors.white, size: 36),
                          ),
                        ),
                        SizedBox(width: 16),
                        Listener(
                          onPointerDown: (details) {
                            _incrementCounter(context, 0, 1);
                          },
                          onPointerUp: (details) {
                            _cancelIncrement(context);
                          },
                          child: GestureDetector(
                            child:
                                Icon(Icons.add, color: Colors.white, size: 36),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              Expanded(
                child: Consumer<MeditationModel>(
                  builder: (context, meditationModel, child) =>
                      ListView.builder(
                    itemCount: sections.length,
                    itemBuilder: (context, index) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(sections[index].title,
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        ...sections[index]
                            .meditations
                            .map((meditation) => Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: InkWell(
                                    onTap: () => meditationModel
                                        .selectMeditation(meditation),
                                    child: index == 0 &&
                                            meditation.title ==
                                                'Cutting Machinery Hour'
                                        ? Row(
                                            children: [
                                              Image.asset('assets/logo.png',
                                                  width: 50, height: 50),
                                              SizedBox(width: 8),
                                              Text(meditation.title,
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.white)),
                                            ],
                                          )
                                        : Text(meditation.title,
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white)),
                                  ),
                                ))
                            .toList(),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
              Consumer<MeditationModel>(
                builder: (context, meditationModel, child) {
                  if (meditationModel.selectedMeditation != null) {
                    return MeditationPlayer(
                        audioUrl:
                            meditationModel.selectedMeditation!.assetName);
                  } else {
                    return Container();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MeditationModel extends ChangeNotifier {
  Meditation? _selectedMeditation;
  Meditation? get selectedMeditation => _selectedMeditation;
  void selectMeditation(Meditation meditation) {
    _selectedMeditation = meditation;
    notifyListeners();
  }

  MeditationModel() {
    _loadStatistic();
  }

  Future<void> _loadStatistic() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int streakDays = prefs.getInt('streakDays') ?? 0;
    _statistic = Statistic(streakDays: streakDays);
    notifyListeners();
  }

  Future<void> _saveStatistic() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('streakDays', _statistic.streakDays);
  }

  Statistic _statistic = Statistic(streakDays: 0);
  Statistic get statistic => _statistic;

  void updateStatistic(int lifetimeHoursChange, int streakDaysChange) {
    _statistic.streakDays = max(0, _statistic.streakDays + streakDaysChange);
    _saveStatistic();
    notifyListeners();
  }
}

class Statistic {
  int streakDays;

  Statistic({required this.streakDays});
}
