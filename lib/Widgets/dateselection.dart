import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class Dateselection extends StatefulWidget {
  final DateTime? selectedDay;
  final Function(DateTime) onDateSelected;
  final String selectedYear;
  final String selectedMonth;
  final Function(String) onYearChanged;
  final Function(String) onMonthChanged;

  const Dateselection({
    super.key,
    this.selectedDay,
    required this.onDateSelected,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onYearChanged,
    required this.onMonthChanged,
  });

  @override
  State<Dateselection> createState() => _DateselectionState();
}

class _DateselectionState extends State<Dateselection> with SingleTickerProviderStateMixin {
  late DateTime focusedDay, firstDay, lastDay;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late List<String> years;
  final List<String> allMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  late List<String> months;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller and fade animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Initialize date-related variables
    final now = DateTime.now();
    years = List.generate(5, (index) => (now.year + index).toString());
    _updateMonthsList();
    _updateCalendarBounds();

    // Start the fade animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateMonthsList() {
    final now = DateTime.now();
    months = int.parse(widget.selectedYear) == now.year ?
    allMonths.sublist(now.month - 1) : List.from(allMonths);
  }

  void _updateCalendarBounds() {
    int year = int.parse(widget.selectedYear);
    int month = allMonths.indexOf(widget.selectedMonth) + 1;
    firstDay = DateTime(year, month, 1);
    lastDay = DateTime(year, month + 1, 0);
    focusedDay = firstDay;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildHeader('Select Your Date', Icons.calendar_today),
          const SizedBox(height: 20),
          _buildDateSelector(),
          const SizedBox(height: 20),
          _buildCalendar(),
          if (widget.selectedDay != null) _buildSelectedCard(),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _iconContainer(icon, Colors.white.withOpacity(0.2)),
          const SizedBox(width: 15),
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _iconContainer(IconData icon, [Color? backgroundColor]) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.deepPurple.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: backgroundColor != null ? Colors.white : Colors.deepPurple, size: 24),
    );
  }

  BoxDecoration _cardDecoration({bool useGradient = true}) {
    return BoxDecoration(
      gradient: useGradient ? LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.blue.shade50, Colors.purple.shade50],
      ) : null,
      color: useGradient ? null : Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, style: const TextStyle(fontWeight: FontWeight.w500)),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(DateTime day, Color backgroundColor, Color textColor, bool enabled, {bool isSelected = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected ? [
          BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
        ] : null,
      ),
      child: Center(
        child: Text('${day.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: isSelected ? 16 : 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(useGradient: false),
      child: Row(
        children: [
          Expanded(child: _buildDropdown(widget.selectedYear, years, (value) {
            widget.onYearChanged(value!);
            _updateMonthsList();
            _updateCalendarBounds();
          }, Icons.calendar_view_day)),
          const SizedBox(width: 16),
          Expanded(child: _buildDropdown(widget.selectedMonth, months, (value) {
            widget.onMonthChanged(value!);
            _updateCalendarBounds();
          }, Icons.calendar_view_month)),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: _cardDecoration(useGradient: false),
      child: TableCalendar(
        firstDay: firstDay,
        lastDay: lastDay,
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(day, widget.selectedDay),
        calendarFormat: CalendarFormat.month,
        headerVisible: false,
        enabledDayPredicate: (day) => !day.isBefore(
            DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
        ),
        onDaySelected: (selected, focused) {
          widget.onDateSelected(selected);
          setState(() {
            focusedDay = focused;
          });
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: Colors.red.shade400),
          defaultTextStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
        calendarBuilders: CalendarBuilders(
          disabledBuilder: (context, day, focusedDay) => _buildCalendarDay(
              day, Colors.red.shade100, Colors.red.shade400, false
          ),
          defaultBuilder: (context, day, focusedDay) => _buildCalendarDay(
              day, Colors.green.shade100, Colors.green.shade700, true
          ),
          todayBuilder: (context, day, focusedDay) => _buildCalendarDay(
              day, Colors.blue.shade200, Colors.white, true
          ),
          selectedBuilder: (context, day, focusedDay) => _buildCalendarDay(
              day, Colors.deepPurple, Colors.white, true, isSelected: true
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selected Date', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(DateFormat('EEEE, MMMM d, yyyy').format(widget.selectedDay!),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}