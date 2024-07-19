import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_tv/firebase_options.dart';

import 'package:flutter_app_tv/ui/auth/login.dart';
import 'package:flutter_app_tv/ui/channel/channel_detail.dart';
import 'package:flutter_app_tv/ui/channel/channels.dart';
import 'package:flutter_app_tv/ui/comment/comment_add.dart';
import 'package:flutter_app_tv/ui/comment/comments.dart';
import 'package:flutter_app_tv/ui/home/home.dart';
import 'package:flutter_app_tv/ui/movie/movie.dart';
import 'package:flutter_app_tv/ui/movie/movies.dart';
import 'package:flutter_app_tv/ui/pages/splash.dart';
import 'package:flutter_app_tv/ui/review/review_add.dart';
import 'package:flutter_app_tv/ui/review/reviews.dart';
import 'package:flutter_app_tv/ui/serie/serie.dart';
import 'package:flutter_app_tv/ui/serie/series.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // await WakelockPlus.enable();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (Platform.isAndroid &&
    //       MediaQuery.of(context).orientation == Orientation.portrait) {
    //     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    //     setState(() {});
    //   }
    // });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Splash(),
        theme: ThemeData(
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
        )),
        routes: {
          "/splash": (context) => Splash(),
          "/home": (context) => Home(),
          "/movie": (context) => Movie(),
          "/serie": (context) => Serie(),
          "/channel_detail": (context) => ChannelDetail(),
          "/channels": (context) => Channels(),
          "/movies": (context) => Movies(),
          "/series": (context) => Series(),
          "/reviews": (context) =>
              Reviews(id: 1, image: "image", title: 'title', type: "type"),
          "/review_add": (context) =>
              ReviewAdd(type: "", id: 1, image: 'image'),
          "/comments": (context) => Comments(),
          "/comment_add": (context) => CommentAdd(image: "", id: 1, type: ""),
          "/login": (context) => Login(),
          // "/video_player": (context) => VideoPlayer(focused_source: 0),
        },
      );
    });
  }
}
