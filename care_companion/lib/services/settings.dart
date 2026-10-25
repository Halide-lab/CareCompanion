import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  bool readAloud = false; // "Tıkladığını oku" aç/kapa
  double fontScale = 1.2; // yazı boyutu çarpanı
  String userName = ''; // asked on first launch
  bool get onboarded => userName.isNotEmpty;
  String lang = 'en'; // 'en', 'nl', 'tr' (ses komutları + sesli okuma dili)
  final FlutterTts _tts = FlutterTts();
  bool _voicePicked = false;

  String get ttsLocale => const {'en': 'en-US', 'nl': 'nl-NL', 'tr': 'tr-TR'}[lang]!;
  String get sttLocale => const {'en': 'en_US', 'nl': 'nl_NL', 'tr': 'tr_TR'}[lang]!;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    readAloud = p.getBool('readAloud') ?? false;
    fontScale = p.getDouble('fontScale') ?? 1.2;
    lang = p.getString('lang') ?? 'en';
    userName = p.getString('userName') ?? '';
    await _applyVoice();
  }


  Future<void> _applyVoice() async {
    try {
      await _tts.setLanguage(ttsLocale);
      await _tts.setSpeechRate(kIsWeb ? 0.95 : 0.5);
      await _tts.setPitch(1.0);
      final raw = await _tts.getVoices;
      if (raw is! List) return;
      final want = ttsLocale.toLowerCase();
      final prefix = want.split('-').first;
      Map? best;
      var bestScore = -100;
      for (final v in raw) {
        if (v is! Map) continue;
        final name = '${v['name']}'.toLowerCase();
        final loc = '${v['locale']}'.toLowerCase().replaceAll('_', '-');
        if (!loc.startsWith(prefix)) continue;
        var score = 1;
        if (loc == want) score += 2;
        if (name.contains('natural') || name.contains('neural')) {
          score += 10;
        } else if (name.contains('premium')) {
          score += 8;
        } else if (name.contains('enhanced')) {
          score += 6;
        } else if (name.contains('google')) {
          score += 5;
        }
        if (name.contains('compact') || name.contains('eloquence')) score -= 5;
        if (score > bestScore) {
          bestScore = score;
          best = v;
        }
      }
      if (best != null) {
        await _tts.setVoice({'name': '${best['name']}', 'locale': '${best['locale']}'});
        _voicePicked = true;
      }
    } catch (_) {}
  }

  Future<void> setUserName(String v) async {
    userName = v;
    (await SharedPreferences.getInstance()).setString('userName', v);
    notifyListeners();
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
    _voicePicked = false;
    await _applyVoice();
    notifyListeners();
  }

  Future<void> speak(String text, {bool force = false}) async {
    if (!readAloud && !force) return;
    if (!_voicePicked) await _applyVoice();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();

  Future<void> speakAndWait(String text) async {
    if (!_voicePicked) await _applyVoice();
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
