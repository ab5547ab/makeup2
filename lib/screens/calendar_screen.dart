import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import '../services/appointments_controller.dart';
import '../utils/hebrew_date_helper.dart';
import '../widgets/appointment_tile.dart';
import '../widgets/hebrew_month_grid.dart';
import 'add_edit_appointment_screen.dart';
import 'settings_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(_today.year, _today.month, _today.day);
    _focusedDay = _selectedDay;
    Future.microtask(() => context.read<AppointmentsController>().load());
  }

  void _goToPreviousMonth(HebrewMonthInfo info) {
    setState(() {
      _focusedDay = HebrewDateHelper.previousMonthAnchor(info);
    });
  }

  void _goToNextMonth(HebrewMonthInfo info) {
    setState(() {
      _focusedDay = HebrewDateHelper.nextMonthAnchor(info);
    });
  }

  void _onDaySelected(DateTime day) {
    setState(() => _selectedDay = day);
    _showDayAppointmentsSheet(day);
  }

  void _showDayAppointmentsSheet(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<AppointmentsController>(
              builder: (context, controller, _) {
                final appts = controller.forDay(day);
                return SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    HebrewDateHelper.fullHebrewDate(day),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${day.day}.${day.month}.${day.year} · ${appts.length} תורים',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                _openEditor();
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('תור חדש'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: appts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.event_available_outlined,
                                        size: 44,
                                        color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text('אין תורים ביום זה',
                                        style: TextStyle(
                                            color: Colors.grey.shade500)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(8, 8, 8, 24),
                                itemCount: appts.length,
                                itemBuilder: (context, index) {
                                  final appt = appts[index];
                                  return AppointmentTile(
                                    appointment: appt,
                                    onTap: () {
                                      Navigator.pop(sheetContext);
                                      _openEditor(appointment: appt);
                                    },
                                    onDelete: () =>
                                        controller.delete(appt.id),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppointmentsController>();

    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final monthInfo = HebrewDateHelper.monthInfoFor(_focusedDay);
    final dayAppointments = controller.forDay(_selectedDay);

    // סטטיסטיקות מחושבות לפי כל ימי החודש העברי המוצג
    final monthDays = monthInfo.daysAsGregorian;
    final monthAppointments =
        monthDays.expand((d) => controller.forDay(d)).toList();
    final monthTotal = monthAppointments
        .where((a) => a.status != AppointmentStatus.cancelled)
        .fold(0.0, (sum, a) => sum + a.price);

    return Scaffold(
      appBar: AppBar(
        title: const Text('סטודיו לאיפור'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'הגדרות וסנכרון',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // מסך קטן (למשל מכשירים ישנים או תצוגה מפוצלת) - נצמצם ריווחים
            final isCompact = constraints.maxWidth < 380 ||
                constraints.maxHeight < 640;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    _MonthSummaryBar(
                      total: monthTotal,
                      count: monthAppointments.length,
                      compact: isCompact,
                    ),
                    Card(
                      margin: EdgeInsets.fromLTRB(
                          isCompact ? 4 : 8, isCompact ? 4 : 8,
                          isCompact ? 4 : 8, 0),
                      child: HebrewMonthGrid(
                        monthInfo: monthInfo,
                        selectedDay: _selectedDay,
                        today: _today,
                        daysWithAppointments: controller.daysWithAppointments,
                        onDaySelected: _onDaySelected,
                        onPreviousMonth: () => _goToPreviousMonth(monthInfo),
                        onNextMonth: () => _goToNextMonth(monthInfo),
                      ),
                    ),
                    SizedBox(height: isCompact ? 4 : 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              HebrewDateHelper.fullHebrewDate(_selectedDay),
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('${dayAppointments.length} תורים',
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_selectedDay.day}.${_selectedDay.month}.${_selectedDay.year}  ·  לחצו על היום כדי לפתוח את רשימת התורים שלו',
                          textAlign: TextAlign.right,
                          style:
                              TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    dayAppointments.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_available_outlined,
                                    size: 40, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text('אין תורים ביום זה',
                                    style:
                                        TextStyle(color: Colors.grey.shade500)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                            itemCount: dayAppointments.length,
                            itemBuilder: (context, index) {
                              final appt = dayAppointments[index];
                              return AppointmentTile(
                                appointment: appt,
                                onTap: () => _openEditor(appointment: appt),
                                onDelete: () => controller.delete(appt.id),
                              );
                            },
                          ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('תור חדש'),
      ),
    );
  }

  void _openEditor({Appointment? appointment}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAppointmentScreen(
          initialDate: _selectedDay,
          existing: appointment,
        ),
      ),
    );
  }
}

class _MonthSummaryBar extends StatelessWidget {
  final double total;
  final int count;
  final bool compact;

  const _MonthSummaryBar(
      {required this.total, required this.count, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primary,
      padding: EdgeInsets.symmetric(
          vertical: compact ? 6 : 10, horizontal: compact ? 10 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
              icon: Icons.event_note,
              label: 'תורים החודש',
              value: '$count',
              compact: compact),
          Container(width: 1, height: compact ? 22 : 28, color: Colors.white24),
          _StatItem(
              icon: Icons.payments_outlined,
              label: 'הכנסה חודשית',
              value: '₪${total.toStringAsFixed(0)}',
              compact: compact),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  const _StatItem(
      {required this.icon,
      required this.label,
      required this.value,
      this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 14 : 16, color: Colors.white70),
            const SizedBox(width: 4),
            Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 14 : 16)),
          ],
        ),
        Text(label,
            style: TextStyle(
                color: Colors.white70, fontSize: compact ? 10 : 11)),
      ],
    );
  }
}
