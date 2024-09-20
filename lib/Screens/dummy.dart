import 'package:flutter/material.dart';

class DetailScreen extends StatefulWidget{
     final DateTime date;
  const DetailScreen({super.key,required this.date});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {

  @override
  Widget build(BuildContext context) {
    DateTime date = widget.date;
    final String formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Selected Date:',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 16),
            Text(
              formattedDate,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            // Display more details about the date if available
          ],
        ),
      ),
    );
  }
}
