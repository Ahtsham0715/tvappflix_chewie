import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_tv/api/api_rest.dart';
import 'package:flutter_app_tv/constants.dart';
import 'package:flutter_app_tv/key_code.dart';
import 'package:flutter_app_tv/model/subscription.dart';
import 'package:flutter_app_tv/ui/auth/subscription_item_widget.dart';
import 'package:flutter_app_tv/ui/channel/channels.dart';
import 'package:flutter_app_tv/ui/comment/comment_empty_widget.dart';
import 'package:flutter_app_tv/ui/comment/comment_error_widget.dart';
import 'package:flutter_app_tv/ui/comment/comment_loading_widget.dart';
// import 'package:flutter_html/shims/dart_ui_real.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:convert' as convert;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

class Subscriptions extends StatefulWidget {
  @override
  _SubscriptionsState createState() => _SubscriptionsState();
}

class _SubscriptionsState extends State<Subscriptions> {
  FocusNode main_focus_node = FocusNode();
  int pos_y = 0;
  int pos_x = 0;
  List<Subscription> subscriptionList = [];
  ItemScrollController subscriptionScrollController = ItemScrollController();

  bool _visibile_loading = false;
  bool _visibile_error = false;
  bool _visibile_success = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration.zero, () {
      FocusScope.of(context).requestFocus(main_focus_node);
      _getList();
    });
  }

  void _getList() async {
    subscriptionList.clear();

    _showLoading();
    var response;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? id_user = prefs.getInt("ID_USER");
    String? key_user = prefs.getString("TOKEN_USER");
    var data = {
      "id": id_user.toString(),
      "key": key_user.toString(),
    };

    response = await apiRest.getSubscriptions(data);
    print(response.body);

    if (response == null) {
      _showTryAgain();
    } else {
      if (response.statusCode == 200) {
        var jsonData = convert.jsonDecode(response.body);

        for (Map<String, dynamic> i in jsonData) {
          Subscription subscription = Subscription.fromJson(i);
          subscriptionList.add(subscription);
        }

        _showData();
      } else {
        _showTryAgain();
      }
    }
    setState(() {});
  }

  void _showLoading() {
    setState(() {
      _visibile_loading = true;
      _visibile_error = false;
      _visibile_success = false;
    });
  }

  void _showTryAgain() {
    setState(() {
      _visibile_loading = false;
      _visibile_error = true;
      _visibile_success = false;
    });
  }

  void _showData() {
    setState(() {
      _visibile_loading = false;
      _visibile_error = false;
      _visibile_success = true;
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
            case LogicalKeyboardKey.select:
              break;
            case LogicalKeyboardKey.arrowUp:
              if (pos_y > 0) {
                pos_y--;
              }
              break;
            case LogicalKeyboardKey.arrowDown:
              if (pos_y < 4) {
                pos_y++;
              }
              break;

            default:
              break;
          }
          subscriptionScrollController.scrollTo(
              index: pos_y,
              alignment: 0.43,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOutQuart);
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
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black87,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 80.0, left: 10, bottom: 10),
                            child: Row(
                              children: [
                                if(Platform.isIOS)  InkWell(
                            onTap: (){
                              Navigator.pop(context);
                            },
child: Icon(Icons.arrow_back_ios, size: 30.0, color: Colors.white),
                          ),
                          if(Platform.isIOS)  SizedBox(width: 20.0,),
                                Icon(Icons.star,
                                    color: Colors.white70, size: 35),
                                SizedBox(width: 10),
                                Text(
                                  "My subscriptions",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_visibile_error) CommentErrorWidget(),
                        if (_visibile_loading) CommentLoadingWidget(),
                        if (_visibile_success)
                          if (subscriptionList.length == 0)
                            CommentEmptyWidget()
                          else
                            Expanded(
                                child: ScrollConfiguration(
                              behavior:
                                  MyBehavior(), // From this behaviour you can change the behaviour
                              child: ScrollablePositionedList.builder(
                                itemCount: subscriptionList.length,
                                itemScrollController:
                                    subscriptionScrollController,
                                scrollDirection: Axis.vertical,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                      onTap: () {},
                                      child: SubscriptionItemWidget(
                                          subscription: subscriptionList[index],
                                          isFocused:
                                              (pos_y == index) ? true : false));
                                },
                              ),
                            ))
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
