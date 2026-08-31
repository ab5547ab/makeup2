import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import 'storage_service.dart';

/// המוח של האפליקציה: מחזיק את רשימת התורים בזיכרון, שומר לאחסון המקומי
/// בכל שינוי, ומודיע למסכים לרענן את עצמם.
class AppointmentsController extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<Appointment> _appointments = [];
  bool _isLoading = true;

  List<Appointment> get appointments => List.unmodifiable(_appointments);
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _appointments = await _storage.loadAppointments();
    _appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    _isLoading = false;
    notifyListeners();
  }

  List<Appointment> forDay(DateTime day) {
    return _appointments
        .where((a) =>
            a.dateTime.year == day.year &&
            a.dateTime.month == day.month &&
            a.dateTime.day == day.day)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// מפת ימים עם תורים - משמש להצגת נקודות על הלוח שנה
  Set<DateTime> get daysWithAppointments => _appointments
      .map((a) => DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day))
      .toSet();

  double totalForMonth(DateTime month) {
    return _appointments
        .where((a) =>
            a.dateTime.year == month.year &&
            a.dateTime.month == month.month &&
            a.status != AppointmentStatus.cancelled)
        .fold(0.0, (sum, a) => sum + a.price);
  }

  int countForMonth(DateTime month) {
    return _appointments
        .where((a) =>
            a.dateTime.year == month.year && a.dateTime.month == month.month)
        .length;
  }

  Future<void> add(Appointment appointment) async {
    _appointments.add(appointment);
    _appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    notifyListeners();
    await _storage.saveAppointments(_appointments);
  }

  Future<void> update(Appointment appointment) async {
    final index = _appointments.indexWhere((a) => a.id == appointment.id);
    if (index == -1) return;
    _appointments[index] = appointment;
    _appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    notifyListeners();
    await _storage.saveAppointments(_appointments);
  }

  Future<void> delete(String id) async {
    _appointments.removeWhere((a) => a.id == id);
    notifyListeners();
    await _storage.saveAppointments(_appointments);
  }

  /// מיזוג רשימת תורים שהתקבלה מסנכרון (GitHub) - לפי מזהה, האחרון מנצח
  Future<void> mergeFromRemote(List<Appointment> remote) async {
    final map = {for (final a in _appointments) a.id: a};
    for (final r in remote) {
      map[r.id] = r;
    }
    _appointments = map.values.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    notifyListeners();
    await _storage.saveAppointments(_appointments);
  }
}
