import 'package:flutter/material.dart';

class coustText extends StatelessWidget {
  const coustText({super.key, this.sName, this.color, this.Textsize});
  final String? sName;
  final Color? color;
  final double? Textsize;

  @override
  Widget build(BuildContext context) {
    return Text(
      sName!,
      style: TextStyle(color: color, fontSize: Textsize),
    );
  }
}
