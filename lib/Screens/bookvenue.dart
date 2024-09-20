import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../Colors/coustcolors.dart';
import '../Providers/bookingnotifier.dart';
import '../Widgets/evaluatedbutton.dart';
import '../models/propertystate.dart';

class BookVenueScreen extends ConsumerStatefulWidget {
  final Propertystate property;
  const BookVenueScreen({super.key, required this.property});

  @override
  ConsumerState<BookVenueScreen> createState() => _BookVenueScreenState();
}

class _BookVenueScreenState extends ConsumerState<BookVenueScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedDayString;
  //List<String> tempBlockedDates =[];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //ref.watch(authprovider.notifier).tryAutoLogin(),
    //ref.read(propertyprovider.notifier).getProperties();
    //PropertyNotifier().getProperties();
    ref
        .read(bookingProvider.notifier)
        .fetchBookedDates(context, widget.property, ref);
    //  tempBlockedDates =[];
    //  tempBlockedDates.add("2024-06-02");
    //  tempBlockedDates.add("2024-06-06");
    //  tempBlockedDates.add("2024-06-07");
    //  tempBlockedDates.add("2024-06-08");
    //  tempBlockedDates.add("2024-06-09");
    //  tempBlockedDates.add("2024-06-12");
    //  tempBlockedDates.add("2024-06-14");
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(bookingProvider);
    final calendarNotifier = ref.read(bookingProvider.notifier);
    List<String> formattedBlockedDates = [];
    return Scaffold(
      backgroundColor: CoustColors.colrFill,
      appBar: AppBar(
        title: Text('Manage Calendar'),
      ),
      body: Column(
        children: [
          calendarState.when(
            data: (dates) {
              List<DateTime> blockedDates = dates
                  .where((date) => date.date != null)
                  .map((date) => DateTime.parse(date.date!))
                  .toList();

              // Format the blocked dates
              formattedBlockedDates = formatDateList(blockedDates);
              print("blocked Dates ${formattedBlockedDates} ");
              return CoustCalender(formattedBlockedDates);
            },
            loading: () {
              return CoustCalender(formattedBlockedDates);
            },
            // loading: () => Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
          SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              width: double.infinity,
              child: CoustEvalButton(
                onPressed: () {
                  ref.read(bookingProvider.notifier).Bookproperties(
                      context, widget.property, _selectedDayString, ref);
                },
                buttonName: 'Book',
                bgColor: CoustColors.colrButton1,
                width: double.infinity,
                radius: 8,
                FontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsMarker(DateTime date, List events) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red,
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }

  List<String> formatDateList(List<DateTime> dates) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return dates.map((date) => formatter.format(date)).toList();
  }

  Widget CoustCalender(List<String> formattedBlockedDates) {
    return TableCalendar(
      focusedDay: DateTime.now(),
      firstDay: DateTime(_focusedDay.year, _focusedDay.month, 1),
      //firstDay: DateTime(2000),
      lastDay: DateTime(2100),
      calendarFormat: CalendarFormat.month,
      //selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        if (selectedDay.isBefore(DateTime.now())) {
          // Ignore taps on previous dates
          return;
        }
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
          _selectedDayString = DateFormat('yyyy-MM-dd').format(selectedDay);
          print("Selected Dates ${_selectedDayString} ");
        });
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          String formattedDay = DateFormat('yyyy-MM-dd').format(day);
          print("sel  Dates ${_selectedDayString} && ${formattedDay} ");
          if (formattedBlockedDates.contains(formattedDay)) {
            return Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red, // Color for blocked dates
                  shape: BoxShape.circle,
                ),
                width: 40.0,
                height: 40.0,
                child: Center(
                  child: Text(
                    day.day.toString(),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
          } else if (formattedDay == _selectedDayString) {
            print("in  Dates ${_selectedDayString} ");
            return Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green, // Color for selected date
                  shape: BoxShape.circle,
                ),
                width: 40.0,
                height: 40.0,
                child: Center(
                  child: Text(
                    day.day.toString(),
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
