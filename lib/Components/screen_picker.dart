import 'package:flutter/material.dart';

class ScreenPicker extends StatefulWidget {
  const ScreenPicker({Key? key}) : super(key: key);

  @override
  _ScreenPickerState createState() => _ScreenPickerState();
}

class _ScreenPickerState extends State<ScreenPicker> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            setState(() {
              selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}
