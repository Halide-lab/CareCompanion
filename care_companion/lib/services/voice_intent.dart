enum VoiceIntent {
  appointments,
  bookAppointment,
  readAppointments,
  medications,
  searchMedication,
  readMeds,
  medInfo,
  health,
  help,
  settings,
  textBigger,
  textSmaller,
  readAloudOn,
  readAloudOff,
  home,
  unknown
}

class VoiceCommand {
  final VoiceIntent intent;
  final String? medName;
  const VoiceCommand(this.intent, [this.medName]);
}

const kTypes = ['GP (Family Doctor)', 'Hospital Specialist'];
const kTimes = ['09:00', '10:30', '14:00', '15:30'];
const kDoctors = ['Dr. Emma van Dijk', 'Dr. Thomas de Vries', 'Dr. Laura Bakker', 'Dr. van den Berg'];

String _norm(String t) {
  var s = t.replaceAll('İ', 'i').toLowerCase();
  const map = {
    'ı': 'i', 'ş': 's', 'ğ': 'g', 'ç': 'c', 'ö': 'o', 'ü': 'u',
    'é': 'e', 'ë': 'e', 'ï': 'i',
  };
  map.forEach((k, v) => s = s.replaceAll(k, v));
  return s;
}

Set<String> _tokens(String s) =>
    RegExp(r'[a-z0-9]+').allMatches(s).map((m) => m.group(0)!).toSet();

bool _has(String s, List<String> words) => words.any((w) => s.contains(w));

int _lev(String a, String b) {
  if (a == b) return 0;
  if ((a.length - b.length).abs() > 3) return 99;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0);
    cur[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      var best = prev[j] + 1;
      if (cur[j - 1] + 1 < best) best = cur[j - 1] + 1;
      if (prev[j - 1] + cost < best) best = prev[j - 1] + cost;
      cur[j] = best;
    }
    prev = cur;
  }
  return prev[b.length];
}

VoiceCommand parseCommand(String text, List<String> medNames) {
  final s = _norm(text);
  final tk = _tokens(s);

  String? med;
  for (final n in medNames) {
    final key = _norm(n.split(' ').first);
    if (key.length < 4) continue;
    final maxDist = key.length >= 7 ? 2 : 1;
    final hit = tk.any((w) => w.length >= 4 && (w == key || _lev(w, key) <= maxDist));
    if (hit) {
      med = n;
      break;
    }
  }
  if (med != null) {
    const infoWords = [
      'when', 'how', 'what', 'which', 'take', 'dose', 'often', 'wanneer', 'hoe ',
      'wat ', 'nemen', 'innemen', 'ne zaman', 'nasil', 'kac', 'nedir', 'kullan', 'saat'
    ];
    const searchWords = ['find', 'search', 'look', 'zoek', 'vind', 'ara ', 'bul'];
    final ask = _has(s, infoWords) && !_has(s, searchWords);
    return VoiceCommand(ask ? VoiceIntent.medInfo : VoiceIntent.searchMedication, med);
  }

  if (_has(s, ['go home', 'home page', 'main screen', 'ana sayfa', 'anasayfa', 'startscherm', 'thuis'])) {
    return const VoiceCommand(VoiceIntent.home);
  }

  if (_has(s, ['bigger', 'larger', 'increase', 'groter', 'vergroot', 'buyut', 'buyuk'])) {
    return const VoiceCommand(VoiceIntent.textBigger);
  }
  if (_has(s, ['smaller', 'decrease', 'reduce', 'kleiner', 'verklein', 'kucult', 'kucuk'])) {
    return const VoiceCommand(VoiceIntent.textSmaller);
  }

  if (_has(s, ['read aloud', 'voorlezen', 'sesli oku', 'sesli okuma'])) {
    const onWords = {'on', 'enable', 'aan', 'ac', 'open'};
    const offWords = {'off', 'disable', 'uit', 'kapat', 'kapa', 'stop'};
    if (tk.any(offWords.contains)) return const VoiceCommand(VoiceIntent.readAloudOff);
    if (tk.any(onWords.contains)) return const VoiceCommand(VoiceIntent.readAloudOn);
    return const VoiceCommand(VoiceIntent.settings);
  }

  const apptWords = ['appointment', 'afspraak', 'afspraken', 'randevu', 'schedule', 'book '];
  const doctorWords = ['doctor', 'huisarts', 'dokter', 'doktor', 'hekim', 'specialist'];
  const listWords = [
    'my appointments', 'upcoming', 'show', 'view', 'check', 'see my',
    'mijn afspraken', 'bekijk', 'toon', 'randevularim', 'goster', 'kontrol'
  ];
  const bookVerbs = [
    'make', 'book', 'new ', 'schedule', 'want', 'need', 'would like', 'arrange',
    'maak', 'plan ', 'nieuwe', 'wil ', 'nodig', 'yeni', 'istiyorum', 'lazim',
    'gerek', 'ayarla'
  ];
  const questionWords = [
    'when', 'what', 'do i have', 'read', 'tell', 'how many', 'wanneer', 'heb ik',
    'vertel', 'lees', 'ne zaman', 'var mi', 'anlat', 'oku', 'kac'
  ];
  if (_has(s, apptWords) || _has(s, doctorWords)) {
    if (_has(s, questionWords) && !_has(s, bookVerbs) && _has(s, apptWords)) {
      return const VoiceCommand(VoiceIntent.readAppointments);
    }
    if (_has(s, listWords)) return const VoiceCommand(VoiceIntent.appointments);
    if (_has(s, bookVerbs) || _has(s, doctorWords)) {
      return const VoiceCommand(VoiceIntent.bookAppointment);
    }
    return const VoiceCommand(VoiceIntent.appointments);
  }

  const medWords = [
    'medic', 'pill', 'tablet', 'drug', 'pharmac', 'ilac', 'medicijn',
    'geneesmiddel', 'apotheek', 'eczane'
  ];
  const searchVerbs = [
    'search', 'find', 'look', 'zoek', 'vind', 'ara ', 'bul', 'another',
    'add', 'toevoeg', 'ekle'
  ];
  const readWords = [
    'read', 'tell', 'what', 'which', 'list', 'vertel', 'lees', 'welke', 'wat ',
    'anlat', 'oku', 'hangi', 'neler'
  ];
  if (_has(s, medWords)) {
    if (_has(s, searchVerbs)) return const VoiceCommand(VoiceIntent.searchMedication);
    if (_has(s, readWords)) return const VoiceCommand(VoiceIntent.readMeds);
    return const VoiceCommand(VoiceIntent.medications);
  }

  if (_has(s, [
    'health', 'gezondheid', 'saglik', 'saglig', 'test result', 'blood',
    'uitslag', 'sonuc', 'tahlil', 'history', 'geschiedenis', 'gecmis', 'allerg'
  ])) {
    return const VoiceCommand(VoiceIntent.health);
  }

  if (_has(s, ['setting', 'instelling', 'ayar', 'text size', 'font'])) {
    return const VoiceCommand(VoiceIntent.settings);
  }

  if (_has(s, ['help', 'hulp', 'yardim', 'how do', 'how to', 'nasil', 'hoe '])) {
    return const VoiceCommand(VoiceIntent.help);
  }

  return const VoiceCommand(VoiceIntent.unknown);
}

int? parseDoctorType(String text) {
  final s = _norm(text);
  if (_has(s, ['hospital', 'specialist', 'ziekenhuis', 'uzman', 'hastane'])) return 1;
  if (_has(s, ['family', 'huisarts', 'aile', 'general']) || _tokens(s).contains('gp')) return 0;
  return null;
}

const _wdNames = <int, List<String>>{
  1: ['monday', 'maandag', 'pazartesi'],
  2: ['tuesday', 'dinsdag', 'sali'],
  3: ['wednesday', 'woensdag', 'carsamba'],
  4: ['thursday', 'donderdag', 'persembe'],
  5: ['friday', 'vrijdag', 'cuma'],
  6: ['saturday', 'zaterdag', 'cumartesi'],
  7: ['sunday', 'zondag', 'pazar'],
};

int? parseDate(String text, List<DateTime> options) {
  final tk = _tokens(_norm(text));
  if (tk.any((w) => const ['tomorrow', 'morgen', 'yarin'].contains(w))) return 0;
  for (var i = 0; i < options.length; i++) {
    final names = _wdNames[options[i].weekday]!;
    if (tk.any((w) => names.contains(w))) return i;
  }
  return null;
}

int? parseTime(String text, List<String> options) {
  var s = _norm(text);
  const words = {
    'nine': '9', 'ten': '10', 'two': '2', 'three': '3', 'fourteen': '14', 'fifteen': '15',
    'negen': '9', 'tien': '10', 'twee': '2', 'drie': '3',
    'dokuz': '9', 'iki': '2', 'uc': '3',
  };
  words.forEach((k, v) => s = s.replaceAll(RegExp('\\b$k\\b'), v));
  final m = RegExp(r'(\d{1,2})(?:[:.](\d{2}))?').firstMatch(s);
  if (m != null) {
    var h = int.parse(m.group(1)!);
    final min = m.group(2) == null ? null : int.parse(m.group(2)!);
    final pm = s.contains('pm') || s.contains('p.m') || s.contains('afternoon') ||
        s.contains('middag') || s.contains('ogleden');
    if (h < 12 && (pm || h <= 6)) h += 12;
    for (var i = 0; i < options.length; i++) {
      final parts = options[i].split(':');
      if (int.parse(parts[0]) == h && (min == null || int.parse(parts[1]) == min)) return i;
    }
    for (var i = 0; i < options.length; i++) {
      if (int.parse(options[i].split(':')[0]) == h) return i;
    }
  }
  if (_has(s, ['morning', 'ochtend', 'sabah'])) return 0;
  if (_has(s, ['afternoon', 'middag', 'ogleden', 'ogle'])) return 2;
  return null;
}

int? parseDoctor(String text) {
  final s = _norm(text);
  const keys = [
    ['emma', 'dijk'],
    ['thomas', 'vries'],
    ['laura', 'bakker'],
    ['berg'],
  ];
  for (var i = 0; i < keys.length; i++) {
    if (keys[i].any((k) => s.contains(k))) return i;
  }
  return null;
}

int? parseOrdinal(String text, int count) {
  final tk = _tokens(_norm(text));
  const sets = [
    {'first', '1st', 'eerste', 'birinci'},
    {'second', '2nd', 'tweede', 'ikinci'},
    {'third', '3rd', 'derde', 'ucuncu'},
    {'fourth', '4th', 'last', 'vierde', 'dorduncu'},
  ];
  for (var i = 0; i < sets.length && i < count; i++) {
    if (tk.any((w) => sets[i].contains(w))) return i;
  }
  return null;
}

bool? parseYesNo(String text) {
  final tk = _tokens(_norm(text));
  const yes = {
    'yes', 'yeah', 'yep', 'sure', 'ok', 'okay', 'correct', 'confirm', 'please',
    'ja', 'jazeker', 'prima', 'goed', 'evet', 'tamam', 'olur', 'dogru'
  };
  const no = {'no', 'nope', 'not', 'nee', 'niet', 'hayir', 'yok', 'dont'};
  final y = tk.any(yes.contains);
  final n = tk.any(no.contains);
  if (y == n) return null;
  return y;
}

bool isCancel(String text) {
  final tk = _tokens(_norm(text));
  const c = {'cancel', 'stop', 'annuleer', 'annuleren', 'iptal', 'vazgec', 'vazgectim', 'quit'};
  return tk.any(c.contains);
}

const kWeekdays = {
  'en': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
  'nl': ['maandag', 'dinsdag', 'woensdag', 'donderdag', 'vrijdag', 'zaterdag', 'zondag'],
  'tr': ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'],
};
const kMonths = {
  'en': ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
  'nl': ['januari', 'februari', 'maart', 'april', 'mei', 'juni', 'juli', 'augustus', 'september', 'oktober', 'november', 'december'],
  'tr': ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'],
};
const _kOr = {'en': 'or', 'nl': 'of', 'tr': 'ya da'};
const _kTomorrow = {'en': 'tomorrow', 'nl': 'morgen', 'tr': 'yarın'};

String spokenDate(String lang, DateTime d) {
  final wd = (kWeekdays[lang] ?? kWeekdays['en']!)[d.weekday - 1];
  final mo = (kMonths[lang] ?? kMonths['en']!)[d.month - 1];
  return lang == 'tr' ? '${d.day} $mo $wd' : '$wd ${d.day} $mo';
}

String datesSpoken(String lang, List<DateTime> dates) {
  final items = <String>[];
  for (var i = 0; i < dates.length; i++) {
    items.add(i == 0
        ? (_kTomorrow[lang] ?? 'tomorrow')
        : (kWeekdays[lang] ?? kWeekdays['en']!)[dates[i].weekday - 1]);
  }
  final or = _kOr[lang] ?? 'or';
  return '${items.sublist(0, items.length - 1).join(', ')} $or ${items.last}';
}

String timesSpoken(String lang, int n) {
  if (lang == 'nl') return n == 1 ? 'één keer per dag' : '$n keer per dag';
  if (lang == 'tr') return n == 1 ? 'günde bir kez' : 'günde $n kez';
  return n == 1 ? 'once a day' : '$n times a day';
}

const Map<String, Map<String, String>> kReplies = {
  'en': {
    'appointments': 'Opening your appointments.',
    'medications': 'Opening your medications.',
    'searchMedication': 'Let us find your medicine.',
    'health': 'Opening your health.',
    'help': 'Opening help.',
    'settings': 'Opening settings.',
    'home': 'Going home.',
    'unknown':
        'Sorry, I did not understand. You can say: make an appointment, what medicines do I take, my health, or help.',
  },
  'nl': {
    'appointments': 'Ik open uw afspraken.',
    'medications': 'Ik open uw medicijnen.',
    'searchMedication': 'Laten we uw medicijn zoeken.',
    'health': 'Ik open uw gezondheid.',
    'help': 'Ik open de hulp.',
    'settings': 'Ik open de instellingen.',
    'home': 'Terug naar het begin.',
    'unknown':
        'Sorry, ik begreep het niet. U kunt zeggen: maak een afspraak, welke medicijnen gebruik ik, mijn gezondheid of hulp.',
  },
  'tr': {
    'appointments': 'Randevularınızı açıyorum.',
    'medications': 'İlaçlarınızı açıyorum.',
    'searchMedication': 'İlacınızı arayalım.',
    'health': 'Sağlık bilgilerinizi açıyorum.',
    'help': 'Yardımı açıyorum.',
    'settings': 'Ayarları açıyorum.',
    'home': 'Ana sayfaya dönüyorum.',
    'unknown':
        'Üzgünüm, anlayamadım. Şunları söyleyebilirsiniz: randevu almak istiyorum, hangi ilaçları kullanıyorum, sağlığım veya yardım.',
  },
};

const Map<String, Map<String, String>> kText = {
  'en': {
    'greet': 'Hello Anna. How can I help you?',
    'notHeard': 'I did not hear anything. Tap the microphone and try again.',
    'sorry': 'Sorry, I did not catch that.',
    'tapHint': 'You can also tap an answer on the screen.',
    'cancelled': 'Okay, I stopped. Nothing was booked.',
    'declined': 'Okay, I did not book anything. What else can I do for you?',
    'askType': 'Who do you need to see? You can say family doctor, or hospital specialist.',
    'askDate': 'Which day would you like? You can say: {dates}.',
    'askTime': 'What time suits you? I have nine o clock, ten thirty, two o clock, or three thirty.',
    'askDoctor': 'Which doctor? Emma van Dijk, Thomas de Vries, Laura Bakker, or Doctor van den Berg.',
    'confirm': 'Shall I book a visit with {doctor} on {date} at {time}? Say yes or no.',
    'booked': 'Your appointment is booked: {date} at {time} with {doctor}.',
    'bookError': 'Sorry, the appointment could not be saved.',
    'noAppts': 'You have no appointments.',
    'apptsOne': 'You have one appointment.',
    'apptsMany': 'You have {n} appointments.',
    'apptItem': '{date} at {time} with {doctor}.',
    'noMeds': 'Your medication list is empty.',
    'medsIntro': 'You take these medicines:',
    'textBigger': 'Okay, the text is now bigger.',
    'textSmaller': 'Okay, the text is now smaller.',
    'textMax': 'The text is already as big as it gets.',
    'textMin': 'The text is already as small as it gets.',
    'readAloudOn': 'Read aloud is on. I will read what you tap.',
    'readAloudOff': 'Read aloud is off.',
  },
  'nl': {
    'greet': 'Hallo Anna. Waarmee kan ik u helpen?',
    'notHeard': 'Ik hoorde niets. Tik op de microfoon en probeer het opnieuw.',
    'sorry': 'Sorry, dat heb ik niet verstaan.',
    'tapHint': 'U kunt ook op een antwoord op het scherm tikken.',
    'cancelled': 'Oké, ik ben gestopt. Er is niets geboekt.',
    'declined': 'Oké, ik heb niets geboekt. Wat kan ik nog meer voor u doen?',
    'askType': 'Wie moet u zien? U kunt zeggen: huisarts, of specialist in het ziekenhuis.',
    'askDate': 'Welke dag wilt u? U kunt zeggen: {dates}.',
    'askTime': 'Hoe laat schikt u? Ik heb negen uur, half elf, twee uur of half vier.',
    'askDoctor': 'Welke arts? Emma van Dijk, Thomas de Vries, Laura Bakker of dokter van den Berg.',
    'confirm': 'Zal ik een afspraak maken met {doctor} op {date} om {time}? Zeg ja of nee.',
    'booked': 'Uw afspraak is gemaakt: {date} om {time} met {doctor}.',
    'bookError': 'Sorry, de afspraak kon niet worden opgeslagen.',
    'noAppts': 'U heeft geen afspraken.',
    'apptsOne': 'U heeft één afspraak.',
    'apptsMany': 'U heeft {n} afspraken.',
    'apptItem': '{date} om {time} met {doctor}.',
    'noMeds': 'Uw medicijnlijst is leeg.',
    'medsIntro': 'U gebruikt deze medicijnen:',
    'textBigger': 'Oké, de tekst is nu groter.',
    'textSmaller': 'Oké, de tekst is nu kleiner.',
    'textMax': 'De tekst is al zo groot als kan.',
    'textMin': 'De tekst is al zo klein als kan.',
    'readAloudOn': 'Voorlezen staat aan. Ik lees voor wat u aantikt.',
    'readAloudOff': 'Voorlezen staat uit.',
  },
  'tr': {
    'greet': 'Merhaba Anna. Size nasıl yardımcı olabilirim?',
    'notHeard': 'Bir şey duymadım. Mikrofona dokunup tekrar deneyin.',
    'sorry': 'Üzgünüm, anlayamadım.',
    'tapHint': 'Ekrandaki cevaplardan birine de dokunabilirsiniz.',
    'cancelled': 'Tamam, durdurdum. Hiçbir şey kaydedilmedi.',
    'declined': 'Tamam, randevu almadım. Başka nasıl yardımcı olabilirim?',
    'askType': 'Kimi görmeniz gerekiyor? Aile doktoru ya da hastane uzmanı diyebilirsiniz.',
    'askDate': 'Hangi gün olsun? Şunları söyleyebilirsiniz: {dates}.',
    'askTime': 'Saat kaçta olsun? Dokuz, on buçuk, on dört ya da on beş buçuk var.',
    'askDoctor': 'Hangi doktor? Emma van Dijk, Thomas de Vries, Laura Bakker ya da Doktor van den Berg.',
    'confirm': '{doctor} ile {date} günü saat {time} için randevu alayım mı? Evet ya da hayır deyin.',
    'booked': 'Randevunuz alındı: {date}, saat {time}, {doctor}.',
    'bookError': 'Üzgünüm, randevu kaydedilemedi.',
    'noAppts': 'Hiç randevunuz yok.',
    'apptsOne': 'Bir randevunuz var.',
    'apptsMany': '{n} randevunuz var.',
    'apptItem': '{date}, saat {time}, {doctor}.',
    'noMeds': 'İlaç listeniz boş.',
    'medsIntro': 'Şu ilaçları kullanıyorsunuz:',
    'textBigger': 'Tamam, yazılar büyüdü.',
    'textSmaller': 'Tamam, yazılar küçüldü.',
    'textMax': 'Yazılar zaten en büyük boyutta.',
    'textMin': 'Yazılar zaten en küçük boyutta.',
    'readAloudOn': 'Sesli okuma açık. Dokunduğunuz şeyleri okuyacağım.',
    'readAloudOff': 'Sesli okuma kapalı.',
  },
};

const Map<String, List<String>> kExamples = {
  'en': [
    'Make an appointment',
    'What medicines do I take?',
    'When do I take paracetamol?',
    'Do I have an appointment?',
    'Make the text bigger',
    'My health',
  ],
  'nl': [
    'Maak een afspraak',
    'Welke medicijnen gebruik ik?',
    'Wanneer neem ik paracetamol?',
    'Heb ik een afspraak?',
    'Maak de tekst groter',
    'Mijn gezondheid',
  ],
  'tr': [
    'Randevu almak istiyorum',
    'Hangi ilaçları kullanıyorum?',
    'Parasetamolü ne zaman alıyorum?',
    'Randevum var mı?',
    'Yazıları büyüt',
    'Sağlığım',
  ],
};

String txt(String lang, String key, [Map<String, String> args = const {}]) {
  var t = (kText[lang] ?? kText['en']!)[key] ?? kText['en']![key] ?? key;
  args.forEach((k, v) => t = t.replaceAll('{$k}', v));
  return t;
}

String replyFor(String lang, VoiceCommand c) {
  final m = kReplies[lang] ?? kReplies['en']!;
  var t = m[c.intent.name] ?? m['unknown']!;
  if (c.medName != null && c.intent == VoiceIntent.searchMedication) {
    t = '$t ${c.medName}.';
  }
  return t;
}
