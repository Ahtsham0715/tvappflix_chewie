import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_tv/api/api_config.dart';
import 'package:flutter_app_tv/constants.dart';
import 'package:flutter_app_tv/key_code.dart';
import 'package:flutter_html/flutter_html.dart';
// import 'package:flutter_html/shims/dart_ui_real.dart';

import 'package:transparent_image/transparent_image.dart';

import 'package:http/http.dart' as http;

class Privacy extends StatefulWidget {
  Privacy();

  @override
  _PrivacyState createState() => _PrivacyState();
}

class _PrivacyState extends State<Privacy> {
  String _data = "Loading ...";

  ScrollController _scrollController = ScrollController();
  FocusNode main_focus_node = FocusNode();
  double pos_y = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
  }

  getData() async {
    String d = await http.read(Uri.parse(
        apiConfig.api_url.replaceAll("/api/", '/privacy_policy.html')));
    setState(() {
      _data = d;
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: main_focus_node,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          final logicalKey = event.logicalKey;
          switch (logicalKey) {
            case (LogicalKeyboardKey.select || LogicalKeyboardKey.enter):
              break;
            case LogicalKeyboardKey.arrowUp:
              if (pos_y > 0) {
                pos_y -= 100;
                _scrollController.animateTo(pos_y,
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOutQuart);
              }
              break;
            case LogicalKeyboardKey.arrowDown:
              if (_scrollController.position.pixels <
                  _scrollController.position.maxScrollExtent) {
                pos_y += 100;
                _scrollController.animateTo(pos_y,
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOutQuart);
              }
              break;
            case LogicalKeyboardKey.arrowLeft:
              print("play sound");

              break;
            case LogicalKeyboardKey.arrowRight:
              print("play sound");
              break;
            default:
              break;
          }
          setState(() {});
        }
      },
      child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              FadeInImage(
                  placeholder: MemoryImage(kTransparentImage),
                  image: AssetImage("assets/images/background.jpeg"),
                  fit: BoxFit.cover),
              ClipRRect(
                // Clip it cleanly.
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                  child: Container(
                    color: Colors.black.withOpacity(0.1),
                    alignment: Alignment.center,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: context.isPortrait ? 0 : -5,
                top: context.isPortrait ? null : -5,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black,
                          offset: Offset(0, 0),
                          blurRadius: 5),
                    ],
                  ),
                  height: context.isPortrait
                      ? MediaQuery.of(context).size.height * 0.75
                      : double.infinity,
                  width: context.isPortrait
                      ? MediaQuery.of(context).size.width
                      : MediaQuery.of(context).size.width / 2.5,
                  child: Container(
                    width: double.infinity,
                    color: Colors.black54,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 50.0),
                          child: Center(
                              child: Image.asset("assets/images/logo.png",
                                  height: 40, color: Colors.white)),
                        ),
                        SizedBox(height: 20),
                        Expanded(
                          child: SingleChildScrollView(
                              controller: _scrollController,
                              child: Column(
                                children: [
                                  Container(
                                    margin: EdgeInsets.all(5),
                                    child: Html(
                                      data: _data,
                                      style: {
                                        "*": Style(
                                            color: Colors.white,
                                            fontSize: FontSize.medium),
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                ],
                              )),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )),
    );
  }
}
