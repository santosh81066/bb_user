import 'package:flutter/material.dart';

// ignore: must_be_immutable
class Heading extends StatelessWidget {
  final sText1, sText2;
  final bool bVisibil;

  const Heading({
    super.key,
    required this.sText1,
    required this.sText2,
    required this.bVisibil,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [ 
        const Text("BanquetBookz",
            style: TextStyle(color: Colors.white, fontSize: 30)),
        Visibility(
            visible: bVisibil,
            child: Text(sText1,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                    fontWeight: FontWeight.bold))),
        Text(
          sText2,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        )
      ],
    );
  }
}
