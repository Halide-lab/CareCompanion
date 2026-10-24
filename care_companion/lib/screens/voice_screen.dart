import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../main.dart';
import '../services/db.dart';
import '../services/settings.dart';
import '../services/voice_intent.dart';
import '../widgets/widgets.dart';
import 'screens.dart';

enum _Step { idle, type, date, time, doctor, confirm }

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});
  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final SpeechToText _stt = SpeechToText();
  late final AppSettings _s;
  bool _ready = false;
  bool _listening = false;
  bool _starting = false;
  bool _leaving = false;
  bool _sessionHandled = true;
  String _heard = '';
  String _agent = 'Getting ready…';
  _Step _step = _Step.idle;
  int _misses = 0;
  int? _typeI, _dateI, _timeI, _docI;
  final List<DateTime> _dates =
      List.generate(4, (i) => DateTime.now().add(Duration(days: i + 1)));

  String _t(String key, [Map<String, String> args = const {}]) => txt(_s.lang, key, args);

  @override
  void initState() {
    super.initState();
    _s = context.read<AppSettings>();
    _init();
  }

  @override
  void dispose() {
    _stt.cancel();
    if (!_leaving) _s.stopSpeaking();
    super.dispose();
  }

  // ---------------- mikrofon ----------------
  Future<void> _init() async {
    final ok = await _stt.initialize(
      onError: (e) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _finish();
        });
      },
      onStatus: (st) {
        if (st == 'done' || st == 'notListening') {
          Future.delayed(const Duration(milliseconds: 700), () {
            if (mounted) _finish();
          });
        }
      },
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _agent =
          'The microphone is not available. Check the permissions, or tap one of the options below.');
      return;
    }
    _ready = true;
    await _ask(_t('greet'));
  }

  Future<String?> _pickLocale(String wanted) async {
    final locales = await _stt.locales();
    final lang = wanted.substring(0, 2);
    for (final l in locales) {
      if (l.localeId.replaceAll('-', '_') == wanted) return l.localeId;
    }
    for (final l in locales) {
      if (l.localeId.startsWith(lang)) return l.localeId;
    }
    return null;
  }

  Future<void> _listen() async {
    if (!mounted || _leaving || _starting || _listening) return;
    if (!_ready) {
      await _init();
      return;
    }
    _starting = true;
    try {
      await _s.stopSpeaking();
      final locale = await _pickLocale(_s.sttLocale);
      if (!mounted) return;
      _sessionHandled = false;
      setState(() {
        _heard = '';
        _listening = true;
      });
      await _stt.listen(
        localeId: locale,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        onResult: (r) {
          if (!mounted) return;
          setState(() => _heard = r.recognizedWords);
          if (r.finalResult) _finish();
        },
      );
    } finally {
      _starting = false;
    }
  }

  void _finish() {
    if (_sessionHandled || !mounted) return;
    _sessionHandled = true;
    setState(() => _listening = false);
    _onHeard(_heard);
  }

  Future<void> _stop() async {
    await _stt.stop();
  }

  void _stopAll() {
    _sessionHandled = true;
    _stt.cancel();
    _s.stopSpeaking();
    if (mounted) setState(() => _listening = false);
  }

  /// Agent konuşur, bitince dinlemeye başlar.
  Future<void> _ask(String text, {bool listen = true}) async {
    if (!mounted) return;
    setState(() {
      _agent = text;
      _heard = '';
      _listening = false;
    });
    await _s.speakAndWait(text);
    if (!mounted || _leaving) return;
    if (listen) _listen();
  }

  void _navigate(Widget page) {
    _leaving = true;
    _stt.cancel();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  void _goPage(Widget page, String say) {
    _s.speak(say, force: true);
    _navigate(page);
  }

  // ---------------- gelen cümle ----------------
  Future<void> _onHeard(String text) async {
    if (!mounted) return;
    final heard = text.trim();
    if (heard.isEmpty) {
      if (_step == _Step.idle) {
        setState(() => _agent = _t('notHeard'));
      } else {
        await _retry();
      }
      return;
    }
    if (_step == _Step.idle) {
      await _command(heard);
    } else {
      await _stepInput(heard);
    }
  }

  Future<void> _command(String text) async {
    final names = await Db.medNames();
    if (!mounted) return;
    final cmd = parseCommand(text, names);
    final say = replyFor(_s.lang, cmd);

    switch (cmd.intent) {
      case VoiceIntent.unknown:
        _misses++;
        await _ask(say, listen: _misses < 2);
        return;
      case VoiceIntent.home:
        _s.speak(say, force: true);
        _leaving = true;
        Navigator.pop(context);
        return;
      case VoiceIntent.appointments:
        _goPage(const AppointmentsScreen(), say);
      case VoiceIntent.medications:
        _goPage(const MyMedsScreen(), say);
      case VoiceIntent.searchMedication:
        _goPage(SearchMedScreen(initial: cmd.medName ?? ''), say);
      case VoiceIntent.health:
        _goPage(const HealthScreen(), say);
      case VoiceIntent.help:
        _goPage(const HelpScreen(), say);
      case VoiceIntent.settings:
        _goPage(const SettingsScreen(), say);
      case VoiceIntent.bookAppointment:
        _misses = 0;
        await _startBooking(text);
      case VoiceIntent.readAppointments:
        await _readAppointments();
      case VoiceIntent.readMeds:
        await _readMeds();
      case VoiceIntent.medInfo:
        await _medInfo(cmd.medName!);
      case VoiceIntent.textBigger:
        await _changeText(0.2);
      case VoiceIntent.textSmaller:
        await _changeText(-0.2);
      case VoiceIntent.readAloudOn:
        await _s.setReadAloud(true);
        await _ask(_t('readAloudOn'));
      case VoiceIntent.readAloudOff:
        await _s.setReadAloud(false);
        await _ask(_t('readAloudOff'));
    }
  }

  // ---------------- sesli cevaplar ----------------
  Future<void> _changeText(double delta) async {
    final cur = _s.fontScale;
    if (delta > 0 && cur >= 1.79) {
      await _ask(_t('textMax'));
    } else if (delta < 0 && cur <= 1.01) {
      await _ask(_t('textMin'));
    } else {
      final v = (cur + delta).clamp(1.0, 1.8).toDouble();
      await _s.setFontScale(double.parse(v.toStringAsFixed(1)));
      await _ask(_t(delta > 0 ? 'textBigger' : 'textSmaller'));
    }
  }

  Future<void> _readMeds() async {
    final meds = await Db.myMeds();
    if (!mounted) return;
    final msg = meds.isEmpty
        ? _t('noMeds')
        : '${_t('medsIntro')} ${meds.map((m) => '${m.name} ${m.strength}, ${timesSpoken(_s.lang, m.timesPerDay)}.').join(' ')}';
    _goPage(const MyMedsScreen(), msg);
  }

  Future<void> _medInfo(String name) async {
    final mine = await Db.myMeds();
    final all = await Db.search(name);
    if (!mounted || all.isEmpty) return;
    final mineIds = mine.map((m) => m.id).toSet();
    final pick = all.firstWhere((m) => mineIds.contains(m.id), orElse: () => all.first);
    final times = timesSpoken(_s.lang, pick.timesPerDay);
    final msg = _s.lang == 'en'
        ? '${pick.name} ${pick.strength}. $times. ${pick.schedule}. ${pick.important}'
        : '${pick.name} ${pick.strength}. $times.';
    _goPage(MedInfoScreen(pick, canRemove: mineIds.contains(pick.id)), msg);
  }

  Future<void> _readAppointments() async {
    final list = await Db.appointments();
    if (!mounted) return;
    String msg;
    if (list.isEmpty) {
      msg = _t('noAppts');
    } else {
      final items = list.map((a) => _t('apptItem', {
            'date': spokenDate(_s.lang, DateTime.parse(a.date)),
            'time': a.time,
            'doctor': a.doctor,
          }));
      msg =
          '${list.length == 1 ? _t('apptsOne') : _t('apptsMany', {'n': '${list.length}'})} ${items.join(' ')}';
    }
    _goPage(const AppointmentsScreen(), msg);
  }

  // ---------------- randevu sohbeti ----------------
  void _resetFlow() {
    _step = _Step.idle;
    _typeI = _dateI = _timeI = _docI = null;
    _misses = 0;
  }

  Future<void> _startBooking(String text) async {
    _resetFlow();
    _typeI = parseDoctorType(text);
    _dateI = parseDate(text, _dates);
    _timeI = parseTime(text, kTimes);
    _docI = parseDoctor(text);
    await _next();
  }

  Future<void> _next() async {
    _misses = 0;
    if (_typeI == null) {
      _step = _Step.type;
    } else if (_dateI == null) {
      _step = _Step.date;
    } else if (_timeI == null) {
      _step = _Step.time;
    } else if (_docI == null) {
      _step = _Step.doctor;
    } else {
      _step = _Step.confirm;
    }
    setState(() {});
    await _ask(_question());
  }

  String _question() {
    switch (_step) {
      case _Step.type:
        return _t('askType');
      case _Step.date:
        return _t('askDate', {'dates': datesSpoken(_s.lang, _dates)});
      case _Step.time:
        return _t('askTime');
      case _Step.doctor:
        return _t('askDoctor');
      case _Step.confirm:
        return _t('confirm', {
          'doctor': kDoctors[_docI!],
          'date': spokenDate(_s.lang, _dates[_dateI!]),
          'time': kTimes[_timeI!],
        });
      case _Step.idle:
        return '';
    }
  }

  Future<void> _retry() async {
    _misses++;
    if (_misses >= 3) {
      await _ask('${_t('sorry')} ${_t('tapHint')}', listen: false);
      return;
    }
    await _ask('${_t('sorry')} ${_question()}');
  }

  Future<void> _stepInput(String text) async {
    if (isCancel(text)) {
      await _cancelFlow();
      return;
    }
    int? i;
    switch (_step) {
      case _Step.type:
        i = parseDoctorType(text) ?? parseOrdinal(text, 2);
      case _Step.date:
        i = parseDate(text, _dates) ?? parseOrdinal(text, 4);
      case _Step.time:
        i = parseTime(text, kTimes) ?? parseOrdinal(text, 4);
      case _Step.doctor:
        i = parseDoctor(text) ?? parseOrdinal(text, 4);
      case _Step.confirm:
        final yn = parseYesNo(text);
        if (yn == null) {
          await _retry();
        } else if (yn) {
          await _book();
        } else {
          await _declined();
        }
        return;
      case _Step.idle:
        return;
    }
    if (i == null) {
      await _retry();
    } else {
      await _apply(i);
    }
  }

  Future<void> _apply(int i) async {
    switch (_step) {
      case _Step.type:
        _typeI = i;
      case _Step.date:
        _dateI = i;
      case _Step.time:
        _timeI = i;
      case _Step.doctor:
        _docI = i;
      default:
        return;
    }
    await _next();
  }

  Future<void> _book() async {
    final date = _dates[_dateI!];
    final time = kTimes[_timeI!];
    final doctor = kDoctors[_docI!];
    try {
      await Db.addAppt(kTypes[_typeI!], iso(date), time, doctor);
    } catch (e) {
      await _ask('${_t('bookError')} $e', listen: false);
      return;
    }
    final msg = _t('booked', {'date': spokenDate(_s.lang, date), 'time': time, 'doctor': doctor});
    _resetFlow();
    if (!mounted) return;
    _goPage(const AppointmentsScreen(), msg);
  }

  Future<void> _declined() async {
    _resetFlow();
    setState(() {});
    await _ask(_t('declined'));
  }

  Future<void> _cancelFlow() async {
    _stopAll();
    _resetFlow();
    if (mounted) setState(() {});
    await _ask(_t('cancelled'), listen: false);
  }

  // ---------------- ekrandaki seçenekler ----------------
  List<String> _optionLabels() {
    switch (_step) {
      case _Step.type:
        return kTypes;
      case _Step.date:
        return [for (final d in _dates) fmtDate(d)];
      case _Step.time:
        return kTimes;
      case _Step.doctor:
        return kDoctors;
      case _Step.confirm:
        return ['Yes, book it', 'No'];
      case _Step.idle:
        return const <String>[];
    }
  }

  Future<void> _tapOption(int i) async {
    _stopAll();
    if (_step == _Step.confirm) {
      if (i == 0) {
        await _book();
      } else {
        await _declined();
      }
    } else {
      await _apply(i);
    }
  }

  Future<void> _example(String e) async {
    _stopAll();
    await _onHeard(e);
  }

  Future<void> _micTap() async {
    _s.stopSpeaking();
    await _listen();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppSettings>().lang;
    final examples = kExamples[lang] ?? kExamples['en']!;
    final labels = _optionLabels();
    final big = sc(context, 150);
    return Scaffold(
      appBar: AppBar(title: const Text('Talk to me')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Bubble(_agent),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: () => _listening ? _stop() : _micTap(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _listening ? big * 1.25 : big,
              height: _listening ? big * 1.25 : big,
              decoration: BoxDecoration(
                color: _listening ? kOrange : kGreen,
                shape: BoxShape.circle,
                boxShadow: kShadow,
              ),
              child: Icon(
                _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: Colors.white,
                size: big * 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(_listening ? 'I am listening… tap to stop' : 'Tap to speak',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: kGreen)),
        ),
        if (_heard.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: kShadow),
            child: Text('“$_heard”',
                style: const TextStyle(fontSize: 22, fontStyle: FontStyle.italic)),
          ),
        ],
        const SizedBox(height: 24),
        if (_step == _Step.idle) ...[
          const Text('You can say:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (final e in examples)
            ListTileCard(e, icon: Icons.chat_bubble_outline_rounded, onTap: () => _example(e)),
        ] else ...[
          const Text('Say it, or tap an answer:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (var i = 0; i < labels.length; i++)
            ListTileCard(labels[i], onTap: () => _tapOption(i)),
          const SizedBox(height: 4),
          BigButton('Cancel', outlined: true, onTap: _cancelFlow),
        ],
      ]),
    );
  }
}
