import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:parallax_rain/parallax_rain.dart';
import 'package:torch_light/torch_light.dart';
import 'package:vibration/vibration.dart';
import 'package:just_audio/just_audio.dart';
import 'package:workmanager/workmanager.dart';

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
  Timer? messageTimer;
  final Key parallaxKey = GlobalKey();
  late AudioPlayer audioPlayer;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    audioPlayer = AudioPlayer();
    startMessageTimer();
    initializeNotifications();
    startPeriodicNotifications();
    startPeriodicTasks();
  }

  void initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void startPeriodicTasks() {
    Workmanager().registerPeriodicTask(
      '1',
      'periodicTask',
      frequency: const Duration(minutes: 1),
      initialDelay: const Duration(seconds: 30),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
      ),
    );
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails('your_channel_id', 'your_channel_name',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker');

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
        0, title, body, platformChannelSpecifics,
        payload: 'item x');
  }

  void startPeriodicNotifications() {
    timer = Timer.periodic(const Duration(minutes: 1), (Timer t) async {
      await showNotification('Reminder', 'This is a periodic notification');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateTorchState();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (!isDarkMode) {
      playSound();
    } else {
      stopSound();
    }
  }

  @override
  void dispose() {
    confettiController.dispose();
    torchTimer?.cancel();
    stopSound();
    audioPlayer.dispose();
    messageTimer?.cancel();
    timer?.cancel();
    super.dispose();
  }

  void startMessageTimer() {
    messageTimer?.cancel();

    messageTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final message = isDarkMode
          ? 'You are in sad mode'
          : 'You are in happy mode';

      await showNotification('Mood Update', message);
    });
  }

  void updateTorchState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isDarkMode) {
      stopTorchToggling();
    } else {
      startTorchToggling();
    }
  }

  void startTorchToggling() {
    torchTimer?.cancel();

    torchTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        if (isTorchOn) {
          await TorchLight.disableTorch();
          vibrateHeavy(); // Ensure vibration when torch is toggled off
        } else {
          await TorchLight.enableTorch();
          vibrateHeavy(); // Ensure vibration when torch is toggled on
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

  void handleButtonPress() async {
    setState(() {
      isRain = !isRain;
    });

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (!isDarkMode) {
      confettiController.play();
    }
    updateTorchState();
  }


  void vibrateHeavy() async {
    if (await Vibration.hasVibrator() ?? false) {
      print('Vibration is supported');
      if (await Vibration.hasAmplitudeControl() ?? false) {
        print('Amplitude control available');
        Vibration.vibrate(duration: 500, amplitude: 255);
      }
      else {
        print('Amplitude control not available');
        Vibration.vibrate(pattern: [0, 500, 100, 500]);
      }
    } else {
      print('Vibration not available');
    }
  }




  void playSound() async {
    try {
      await audioPlayer.setAsset('assets/applause.mp3');
      audioPlayer.setLoopMode(LoopMode.one); // Loop the sound
      audioPlayer.play();
    } catch (e) {
      if (kDebugMode) {
        print('Error playing sound: $e');
      }
    }
  }

  void stopSound() async {
    try {
      audioPlayer.stop();
      audioPlayer.setLoopMode(LoopMode.off); // Disable looping
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping sound: $e');
      }
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
          IconButton(
            onPressed: () {
              vibrateHeavy(); // Trigger vibration
            },
            icon: Icon(Icons.vibration),
          ),

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