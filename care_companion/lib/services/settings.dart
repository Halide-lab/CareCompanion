import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  bool readAloud = false; // "Tıkladığını oku" aç/kapa
  double fontScale = 1.2; // yazı boyutu çarpanı
  String lang = 'en'; // 'en', 'nl', 'tr' (ses komutları + sesli okuma dili)
  final FlutterTts _tts = FlutterTts();

  String get ttsLocale => const {'en': 'en-US', 'nl': 'nl-NL', 'tr': 'tr-TR'}[lang]!;
  String get sttLocale => const {'en': 'en_US', 'nl': 'nl_NL', 'tr': 'tr_TR'}[lang]!;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    readAloud = p.getBool('readAloud') ?? false;
    fontScale = p.getDouble('fontScale') ?? 1.2;
    lang = p.getString('lang') ?? 'en';
    await _tts.setLanguage(ttsLocale);
    await _tts.setSpeechRate(0.4);
  }

  Future<void> setReadAloud(bool v) async {
    readAloud = v;
    (await SharedPreferences.getInstance()).setBool('readAloud', v);
    notifyListeners();
  }

  Future<void> setFontScale(double v) async {
    fontScale = v;
    (await SharedPreferences.getInstance()).setDouble('fontScale', v);
    notifyListeners();
  }

  Future<void> setLang(String v) async {
    lang = v;
    (await SharedPreferences.getInstance()).setString('lang', v);
    await _tts.setLanguage(ttsLocale);
    notifyListeners();
  }

  /// force=true: ayar kapalı olsa bile okur ("Listen" butonları ve sesli asistan için)
  Future<void> speak(String text, {bool force = false}) async {
    if (!readAloud && !force) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();

  /// Konuşur ve konuşma BİTİNCE döner (mikrofon kendi sesimizi duymasın diye).
  Future<void> speakAndWait(String text) async {
    await _tts.stop();
    final c = Completer<void>();
    void finish() {
      if (!c.isCompleted) c.complete();
    }

    _tts.setCompletionHandler(finish);
    _tts.setCancelHandler(finish);
    _tts.setErrorHandler((dynamic _) => finish());
    await _tts.speak(text);
    await c.future.timeout(Duration(milliseconds: 3000 + text.length * 90), onTimeout: () {});
  }
}
