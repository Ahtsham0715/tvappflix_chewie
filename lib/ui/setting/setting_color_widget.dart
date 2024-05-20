import 'package:flutter/material.dart';
import 'package:flutter_app_tv/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingColorWidget extends StatefulWidget {
  bool isFocused = false;
  String title;
  String subtitle;
  IconData icon;
  int color;

  SettingColorWidget(
      {required this.isFocused,
      required this.title,
      required this.subtitle,
      required this.icon,
      required this.color});

  @override
  _SettingColorWidgetState createState() => _SettingColorWidgetState();
}

class _SettingColorWidgetState extends State<SettingColorWidget> {
  @override
  void initState() {
    loadSubtitlePrefs();
    super.initState();
  }

  void loadSubtitlePrefs() async {
    var val = await getSubtitleValue("subtitle_color");
    if (val != null) {
      widget.color = val;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: 27,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontSize: 11),
                ),
                SizedBox(height: 3),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.normal,
                      fontSize: 10),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 50,
            child: Container(
              child: Row(
                children: [
                  Container(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (widget.color > 0)
                            widget.color--;
                          else
                            widget.color = 10;

                          setColor(widget.color);
                        });
                      },
                      child: Icon(
                        Icons.keyboard_arrow_left,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 250),
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70, width: 3),
                      borderRadius: BorderRadius.circular(50),
                      color: subtitleTextColors[widget.color],
                    ),
                  ),
                  Container(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (widget.color < 10)
                            widget.color++;
                          else
                            widget.color = 0;

                          setColor(widget.color);
                        });
                      },
                      child: Icon(
                        Icons.keyboard_arrow_right,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      decoration: BoxDecoration(
        color: (widget.isFocused) ? Colors.black : Colors.white.withOpacity(0),
      ),
    );
  }

  void setColor(int color) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("subtitle_color", color);
  }
}
