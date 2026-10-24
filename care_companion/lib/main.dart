import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/settings.dart';
import 'screens/screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.load();
  runApp(ChangeNotifierProvider.value(value: settings, child: const CareApp()));
}

const kGreen = Color(0xFF245B58);
const kOrange = Color(0xFFC97D2E);
const kBg = Color(0xFFF5F1E8);
const kInk = Color(0xFF1B2B2A);
const kAppName = 'CareCompanion'; // uygulama adını buradan değiştir
const kFont = 'Manrope'; // font dosyası yoksa sistem fontu kullanılır

class CareApp extends StatelessWidget {
  const CareApp({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: kFont,
      scaffoldBackgroundColor: kBg,
      colorScheme: ColorScheme.fromSeed(seedColor: kGreen),
    );
    final text = base.textTheme.apply(bodyColor: kInk, displayColor: kInk);
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: text.copyWith(
          bodyMedium: text.bodyMedium!.copyWith(fontSize: 19),
          bodyLarge: text.bodyLarge!.copyWith(fontSize: 21),
        ),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          toolbarHeight: 72,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: kGreen,
          titleTextStyle: TextStyle(
              fontFamily: kFont, fontSize: 26, fontWeight: FontWeight.w800, color: kGreen),
        ),
      ),
      // Tüm uygulamada yazı boyutunu ayarlardan büyütür
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(s.fontScale)),
        child: child!,
      ),
      home: const HomeScreen(),
    );
  }
}
