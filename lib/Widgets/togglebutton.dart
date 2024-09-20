import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CoustTogglebutton extends StatefulWidget{
   CoustTogglebutton({super.key,required this.lable});
    String lable;

  @override
  State<CoustTogglebutton> createState() => _CoustTogglebuttonState();
}

class _CoustTogglebuttonState extends State<CoustTogglebutton> {
  bool isSwitched = false;
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
          title: Text(widget.lable),
          value: isSwitched,
          onChanged: (bool value) {
            setState(() {
              isSwitched = value;
            });
          },
        );
  }

void toggleSwitch(bool value) {  
  
    if(isSwitched == false)  
    {  
      setState(() {  
        isSwitched = true;  
      });  
      print('Switch Button is ON');  
    }  
    else  
    {  
      setState(() {  
        isSwitched = false;  
      });  
      print('Switch Button is OFF');  
    }  
  } 
}
