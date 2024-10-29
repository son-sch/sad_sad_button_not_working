import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:parallax_rain/parallax_rain.dart';
import 'package:torch_light/torch_light.dart';
import 'package:vibration/vibration.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late ConfettiController confettiController;
  bool isRain = false;
  Timer? torchTimer;
  bool isTorchOn = false;
  final Key parallaxKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    startTorchToggling();
  }

  @override
  void dispose() {
    confettiController.dispose();
    torchTimer?.cancel();
    super.dispose();
  }

  void startTorchToggling() {
    torchTimer?.cancel();

    torchTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        if (isTorchOn) {
          await TorchLight.disableTorch();
          _vibrateHeavy();
        } else {
          await TorchLight.enableTorch();
          _vibrateHeavy();
        }
        isTorchOn = !isTorchOn;
      } on Exception catch (_) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Could not toggle torch'),
          ),
        );
      }
    });
  }

  void stopTorchToggling() async {
    torchTimer?.cancel();
    try {
      await TorchLight.disableTorch();
      isTorchOn = false;
    } on Exception catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not disable torch'),
        ),
      );
    }
  }

  bool isTorchOnBool = false;

  // void handleButtonPress() async {
  //   final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  //
  //   setState(() {
  //     isRain = !isRain;
  //   });
  //
  //   if (!isDarkMode) {
  //     confettiController.play();
  //   }
  //
  //   if (isDarkMode) {
  //     stopTorchToggling();
  //   } else {
  //     startTorchToggling();
  //   }
  // }
  //


  void _vibrateHeavy() async {
    if (await Vibration.hasVibrator() ?? false) {
      if (await Vibration.hasAmplitudeControl() ?? false) {
        Vibration.vibrate(duration: 500, amplitude: 255);
      } else {
        Vibration.vibrate(pattern: [0, 500, 100, 500]);
      }
    }
  }

  void handleButtonPress() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    setState(() {
      if (isDarkMode){
        isRain = !isRain;
      } else {
        isTorchOn = !isTorchOn;
      }
    });

    if (isDarkMode && isRain) {
    }

    if (!isDarkMode && isTorchOn) {
      TorchLight.enableTorch();
      _vibrateHeavy();
    } else if (!isDarkMode && !isTorchOn) {TorchLight.disableTorch();
    }
    if (!isDarkMode) {
      confettiController.play();
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (!isDarkMode && isRain) {
      setState(() {
        isRain = false;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dark Mode/Light Mode'),
      ),
      body: Stack(
        children: [
          if (isRain) ...[
            ParallaxRain(
              key: parallaxKey,
              dropColors: const [
                Colors.green,
                Colors.blue,
                Colors.blueGrey,
                Colors.deepPurple,
              ],
              trail: true,
              numberOfDrops: 250,
              dropHeight: 30.0,
              dropWidth: 2.0,
            ),
          ],
          Center(
            child: IconButton(
              onPressed: () async {
                handleButtonPress();
              },
              icon: Icon(
                isDarkMode
                    ? Icons.sentiment_very_dissatisfied
                    : Icons.sentiment_very_satisfied,
              ),
              iconSize: 350,
            ),
          ),
          if (!isDarkMode)
            ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.green,
                Colors.blue,
                Colors.yellow
              ],
              emissionFrequency: 0.5,
              maxBlastForce: 100,
              minBlastForce: 10,
              gravity: 0.1,
            ),
        ],
      ),
    );
  }
}

