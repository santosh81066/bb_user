
import 'package:flutter/material.dart';

class CoustEvalButton extends StatelessWidget {
  const CoustEvalButton(
      {super.key,
      this.onPressed,
      this.buttonName,
      this.bgColor,
      this.width,
      this.radius,
      this.textColor,
      this.FontSize,
      this.isLoading});
  final VoidCallback? onPressed;
  final String? buttonName;
  final Color? bgColor;
  final double? width;
  final double? radius;
  final Color? textColor;
  final double? FontSize;
  final bool? isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: isLoading == true
          ? SizedBox(
              height: 20, width: 20, child: const CircularProgressIndicator())
          : Text(
              buttonName!,
              style: TextStyle(color: textColor, fontSize: FontSize),
            ),
      style: ButtonStyle(
          maximumSize: MaterialStatePropertyAll(Size.fromWidth(width!)),
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(radius!))))),
    );
  }
}
