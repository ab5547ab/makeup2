import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/calendar_screen.dart';
import 'services/appointments_controller.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MakeupCalendarApp());
}

class MakeupCalendarApp extends StatelessWidget {
  const MakeupCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppointmentsController(),
      child: MaterialApp(
        title: 'יומן עבודה וניהול תורים',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        locale: const Locale('he', 'IL'),
        supportedLocales: const [Locale('he', 'IL'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const CalendarScreen(),
      ),
    );
  }
}
