import 'package:flutter/material.dart';

class FilterWidget extends StatelessWidget {
  bool? isFocused;
  int? selected_genre;
  int? index;
  String title;

  FilterWidget(
      {this.isFocused, this.selected_genre, this.index, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              title,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            child: Theme(
              data: ThemeData.dark(),
              child: Radio(
                value: index!,
                activeColor: Colors.white,
                groupValue: selected_genre,
                onChanged: (int? value) {},
              ),
            ),
            decoration: BoxDecoration(),
          )
        ],
      ),
      decoration: BoxDecoration(
        color: (isFocused!)
            ? Colors.black.withOpacity(0.9)
            : Colors.white.withOpacity(0),
      ),
    );
    ;
  }
}
