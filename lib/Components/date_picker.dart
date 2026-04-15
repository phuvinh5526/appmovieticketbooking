import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePicker extends StatefulWidget {
  final List<DateTime> dates;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const DatePicker({
    Key? key,
    required this.dates,
    required this.selectedDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  _DatePickerState createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.dates.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            widget.onDateSelected(widget.dates[index]);
          },
          child: Container(
            width: 60,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(
                color: DateFormat('yyyy-MM-dd').format(widget.dates[index]) ==
                        DateFormat('yyyy-MM-dd').format(widget.selectedDate)
                    ? Colors.orangeAccent
                    : Colors.grey.shade800,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
              color: DateFormat('yyyy-MM-dd').format(widget.dates[index]) ==
                      DateFormat('yyyy-MM-dd').format(widget.selectedDate)
                  ? Colors.black54
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE').format(widget.dates[index]).toUpperCase(),
                  style: TextStyle(
                    color: DateFormat('yyyy-MM-dd')
                                .format(widget.dates[index]) ==
                            DateFormat('yyyy-MM-dd').format(widget.selectedDate)
                        ? Colors.orangeAccent
                        : Colors.white54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  DateFormat('d').format(widget.dates[index]),
                  style: TextStyle(
                    color: DateFormat('yyyy-MM-dd')
                                .format(widget.dates[index]) ==
                            DateFormat('yyyy-MM-dd').format(widget.selectedDate)
                        ? Colors.orangeAccent
                        : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
