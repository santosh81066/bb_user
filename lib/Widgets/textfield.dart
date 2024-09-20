import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ignore: must_be_immutable
class CoustTextfield extends StatefulWidget {
  CoustTextfield(
      {super.key,
      this.controller,
      this.inputtype,
      this.hint,
      this.suffixIcon,
      this.suficonColor,
      this.prefixIcon,
      this.preiconColor,
      required this.radius,
      required this.width,
      this.iLength,
      this.password = false,
      this.validator,
      this.onChanged,
      required this.isVisible,
      this.title,this.filltext,});
  TextEditingController? controller;
  final TextInputType? inputtype;
  final String? hint;
  final Widget? suffixIcon;
  final Color? suficonColor;
  final Widget? prefixIcon;
  final Color? preiconColor;
  final double radius;
  final double width;
  final int? iLength;
  final bool? password;
  final String? Function(String?)? validator;
  final String? Function(String?)? onChanged;
  final bool isVisible;
  final String? title;
  final String? filltext;
  @override
  State<CoustTextfield> createState() => _CoustTextfieldState();
}

class _CoustTextfieldState extends State<CoustTextfield> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Visibility(
            visible: widget.isVisible,
            child: Column(
              children: [
                Text(widget.title.toString()),
                const SizedBox(
                  height: 5,
                )
              ],
            )),
        TextFormField(
          onChanged: widget.onChanged,
          validator: widget.validator,
          controller: widget.controller,
          inputFormatters: [
            LengthLimitingTextInputFormatter(widget.iLength),
          ],
          keyboardType: widget.inputtype,
          obscureText: widget.password!,
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: widget.suffixIcon,
            suffixIconColor: widget.suficonColor,
            prefixIcon: widget.prefixIcon,
            prefixIconColor: widget.preiconColor,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(widget.radius)),
                borderSide: BorderSide(width: widget.width)),
          ),
        ),
      ],
    );
  }
}
