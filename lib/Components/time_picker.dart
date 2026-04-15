import 'package:flutter/material.dart';
import '../Model/Showtime.dart';
import 'package:intl/intl.dart';

class TimePicker extends StatefulWidget {
  final List<Showtime> availableShowtimes;
  final Function(Showtime) onTimeSelected;
  final double height;
  final Map<String, bool> selectedTimeStates;

  const TimePicker({
    Key? key,
    required this.availableShowtimes,
    required this.onTimeSelected,
    required this.height,
    required this.selectedTimeStates,
  }) : super(key: key);

  @override
  _TimePickerState createState() => _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  @override
  Widget build(BuildContext context) {
    double buttonHeight = widget.height;
    double spacing = 10;
    double maxHeight = (buttonHeight * 2) + spacing * 3;

    return SizedBox(
      height: maxHeight,
      child: GridView.builder(
        shrinkWrap: true,
        physics: widget.availableShowtimes.length > 6
            ? const BouncingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: widget.availableShowtimes.length,
        itemBuilder: (context, index) {
          final showtime = widget.availableShowtimes[index];
          return GestureDetector(
            onTap: () => widget.onTimeSelected(showtime),
            child: _buildTimeButton(showtime),
          );
        },
      ),
    );
  }

  Widget _buildTimeButton(Showtime showtime) {
    final isSelected = widget.selectedTimeStates[showtime.id] ?? false;
    return GestureDetector(
      onTap: () => widget.onTimeSelected(showtime),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 185, 177, 164)
                : const Color.fromARGB(255, 255, 255, 255),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            DateFormat('HH:mm').format(showtime.startTime),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
