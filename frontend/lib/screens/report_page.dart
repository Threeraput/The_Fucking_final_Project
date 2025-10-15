import 'package:flutter/material.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime selectedMonth = DateTime.now();
  int? selectedDay;

  // Sample attendance data - replace with actual data
  final Map<int, AttendanceRecord> attendanceData = {
    1: AttendanceRecord(checkInTime: '08:45', status: AttendanceStatus.onTime),
    2: AttendanceRecord(checkInTime: '09:15', status: AttendanceStatus.late),
    3: AttendanceRecord(checkInTime: '08:30', status: AttendanceStatus.onTime),
    5: AttendanceRecord(checkInTime: '08:50', status: AttendanceStatus.onTime),
    6: AttendanceRecord(checkInTime: '09:20', status: AttendanceStatus.late),
    8: AttendanceRecord(checkInTime: '08:40', status: AttendanceStatus.onTime),
    9: AttendanceRecord(checkInTime: '08:35', status: AttendanceStatus.onTime),
    10: AttendanceRecord(checkInTime: '09:30', status: AttendanceStatus.late),
    12: AttendanceRecord(checkInTime: '08:45', status: AttendanceStatus.onTime),
    13: AttendanceRecord(checkInTime: '08:55', status: AttendanceStatus.onTime),
    15: AttendanceRecord(checkInTime: '08:40', status: AttendanceStatus.onTime),
    16: AttendanceRecord(checkInTime: '09:10', status: AttendanceStatus.late),
    17: AttendanceRecord(checkInTime: '08:50', status: AttendanceStatus.onTime),
    19: AttendanceRecord(checkInTime: '08:35', status: AttendanceStatus.onTime),
    20: AttendanceRecord(checkInTime: '08:45', status: AttendanceStatus.onTime),
  };

  int get daysInMonth {
    return DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
  }

  int get firstDayOfMonth {
    return DateTime(selectedMonth.year, selectedMonth.month, 1).weekday;
  }

  void _previousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
      selectedDay = null;
    });
  }

  void _nextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
      selectedDay = null;
    });
  }

  Map<String, int> get attendanceStats {
    int onTime = 0;
    int late = 0;
    int absent = 0;

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(selectedMonth.year, selectedMonth.month, i);
      if (date.weekday == 6 || date.weekday == 7) continue; // Skip weekends

      if (attendanceData.containsKey(i)) {
        if (attendanceData[i]!.status == AttendanceStatus.onTime) {
          onTime++;
        } else {
          late++;
        }
      } else if (date.isBefore(DateTime.now())) {
        absent++;
      }
    }

    return {'onTime': onTime, 'late': late, 'absent': absent};
  }

  @override
  Widget build(BuildContext context) {
    final stats = attendanceStats;
    final total = stats['onTime']! + stats['late']! + stats['absent']!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   elevation: 0,
      //   title: const Text(
      //     'Attendance Report',
      //     style: TextStyle(color: Colors.black87, fontSize: 20),
      //   ),
      //   centerTitle: true,
      // ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Statistics Cards
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'On Time',
                      stats['onTime']!,
                      total > 0 ? (stats['onTime']! / total * 100).toStringAsFixed(0) : '0',
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Late',
                      stats['late']!,
                      total > 0 ? (stats['late']! / total * 100).toStringAsFixed(0) : '0',
                      Colors.orange,
                      Icons.access_time,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Absent',
                      stats['absent']!,
                      total > 0 ? (stats['absent']! / total * 100).toStringAsFixed(0) : '0',
                      Colors.red,
                      Icons.cancel,
                    ),
                  ),
                ],
              ),
            ),

            // Attendance Chart
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildBarChart(stats, total),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLegend('On Time', Colors.green),
                      _buildLegend('Late', Colors.orange),
                      _buildLegend('Absent', Colors.red),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Calendar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Month Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _previousMonth,
                      ),
                      Text(
                        '${_getMonthName(selectedMonth.month)} ${selectedMonth.year}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Weekday Headers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                        .map((day) => SizedBox(
                              width: 40,
                              child: Center(
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),

                  // Calendar Grid
                  _buildCalendarGrid(),
                ],
              ),
            ),

            // Selected Day Details
            if (selectedDay != null && attendanceData.containsKey(selectedDay))
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: attendanceData[selectedDay]!.status ==
                                    AttendanceStatus.onTime
                                ? Colors.green[50]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            attendanceData[selectedDay]!.status ==
                                    AttendanceStatus.onTime
                                ? Icons.check_circle
                                : Icons.access_time,
                            color: attendanceData[selectedDay]!.status ==
                                    AttendanceStatus.onTime
                                ? Colors.green[700]
                                : Colors.orange[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getMonthName(selectedMonth.month)} $selectedDay, ${selectedMonth.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              attendanceData[selectedDay]!.status ==
                                      AttendanceStatus.onTime
                                  ? 'On Time'
                                  : 'Late',
                              style: TextStyle(
                                fontSize: 14,
                                color: attendanceData[selectedDay]!.status ==
                                        AttendanceStatus.onTime
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.grey, size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          'Check-in Time:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          attendanceData[selectedDay]!.checkInTime,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, int count, String percentage, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> stats, int total) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildBar('On Time', stats['onTime']!, total, Colors.green),
        _buildBar('Late', stats['late']!, total, Colors.orange),
        _buildBar('Absent', stats['absent']!, total, Colors.red),
      ],
    );
  }

  Widget _buildBar(String label, int value, int total, Color color) {
    final height = total > 0 ? (value / total * 150).toDouble() : 0.0;
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: height.clamp(20, 150),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    List<Widget> dayWidgets = [];

    // Add empty spaces for days before the first day of month
    for (int i = 0; i < firstDayOfMonth % 7; i++) {
      dayWidgets.add(const SizedBox(width: 40, height: 40));
    }

    // Add day widgets
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedMonth.year, selectedMonth.month, day);
      final isWeekend = date.weekday == 6 || date.weekday == 7;
      final hasAttendance = attendanceData.containsKey(day);
      final isSelected = selectedDay == day;
      final isFuture = date.isAfter(DateTime.now());

      Color? backgroundColor;
      Color? textColor = Colors.black87;

      if (isFuture) {
        textColor = Colors.grey[400];
      } else if (isSelected) {
        backgroundColor = Colors.blue[700];
        textColor = Colors.white;
      } else if (hasAttendance) {
        backgroundColor = attendanceData[day]!.status == AttendanceStatus.onTime
            ? Colors.green[100]
            : Colors.orange[100];
      } else if (!isWeekend && !isFuture) {
        backgroundColor = Colors.red[50];
      }

      dayWidgets.add(
        GestureDetector(
          onTap: hasAttendance && !isFuture
              ? () {
                  setState(() {
                    selectedDay = day;
                  });
                }
              : null,
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: isWeekend
                  ? Border.all(color: Colors.grey[300]!, width: 1)
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: dayWidgets,
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}

enum AttendanceStatus { onTime, late, absent }

class AttendanceRecord {
  final String checkInTime;
  final AttendanceStatus status;

  AttendanceRecord({
    required this.checkInTime,
    required this.status,
  });
}