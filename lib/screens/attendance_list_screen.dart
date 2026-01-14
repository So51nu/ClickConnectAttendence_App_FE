import 'package:flutter/material.dart';
import '../services/attendance_service.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  bool _loading = true;
  String _error = "";
  List<dynamic> _items = [];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = "";
    });

    try {
      final data = await AttendanceService.myAttendance();
      if (!mounted) return;
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Attendance")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error))
          : _items.isEmpty
          ? const Center(child: Text("No attendance found."))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final it = _items[i] as Map<String, dynamic>;
          final date = it["date"]?.toString() ?? "-";
          final office = it["office_name"]?.toString() ?? "-";
          final inTime = it["check_in_time"]?.toString();
          final outTime = it["check_out_time"]?.toString();

          return Card(
            child: ListTile(
              title: Text("$date • $office"),
              subtitle: Text(
                "IN: ${inTime ?? '-'}\nOUT: ${outTime ?? '-'}",
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
