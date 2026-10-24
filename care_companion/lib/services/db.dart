import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Med {
  final int id, timesPerDay;
  final String name, strength, form, what, important, warning, schedule;
  Med.fromMap(Map<String, Object?> m)
      : id = m['id'] as int,
        timesPerDay = m['times_per_day'] as int,
        name = m['name'] as String,
        strength = m['strength'] as String,
        form = m['form'] as String,
        what = m['what'] as String,
        important = m['important'] as String,
        warning = m['warning'] as String,
        schedule = m['schedule'] as String;

  String get timesText =>
      timesPerDay == 1 ? 'Once a day' : '$timesPerDay times a day';
}

class Appt {
  final int id;
  final String type, date, time, doctor;
  Appt.fromMap(Map<String, Object?> m)
      : id = m['id'] as int,
        type = m['type'] as String,
        date = m['date'] as String,
        time = m['time'] as String,
        doctor = m['doctor'] as String;
}

class Db {
  static Database? _db;
  static Future<Database> get db async => _db ??= await _open();

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'care_v2.db');
    return openDatabase(path, version: 1, onOpen: (d) async {
      await d.execute(
          'CREATE TABLE IF NOT EXISTS medications(id INTEGER PRIMARY KEY, name TEXT, strength TEXT, form TEXT, what TEXT, important TEXT, warning TEXT, times_per_day INTEGER, schedule TEXT)');
      await d.execute('CREATE TABLE IF NOT EXISTS my_meds(med_id INTEGER PRIMARY KEY)');
      await d.execute(
          'CREATE TABLE IF NOT EXISTS appointments(id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, date TEXT, time TEXT, doctor TEXT)');
      final c = Sqflite.firstIntValue(await d.rawQuery('SELECT COUNT(*) FROM medications')) ?? 0;
      if (c > 0) return;
      // ÖRNEK VERİ - gerçek kullanımdan önce eczacı/doktorla doğrulatın!
      final meds = <Map<String, Object?>>[
        {'id': 1, 'name': 'Paracetamol', 'strength': '500 mg', 'form': 'Tablet',
         'what': 'Paracetamol is a common medicine used to relieve pain and reduce fever.',
         'important': 'Take 1 tablet when needed. Wait at least 4 to 6 hours between doses.',
         'warning': 'Do not take more than 4 times in 24 hours. Do not take other medicines that contain paracetamol.',
         'times_per_day': 4, 'schedule': 'Morning, noon, afternoon, evening (only when needed)'},
        {'id': 2, 'name': 'Vitamin D', 'strength': '1000 IU', 'form': 'Capsule',
         'what': 'Vitamin D helps keep your bones and muscles strong.',
         'important': 'Take 1 capsule once a day with a meal.',
         'warning': 'Do not take extra capsules if you forget a dose.',
         'times_per_day': 1, 'schedule': 'Morning, with breakfast'},
        {'id': 3, 'name': 'Ibuprofen', 'strength': '200 mg', 'form': 'Tablet',
         'what': 'Ibuprofen is a common medicine used to reduce pain and ease high temperatures (fevers).',
         'important': 'You can take 1 tablet up to 3 times a day, with food. Wait 6 to 8 hours between doses.',
         'warning': 'Do not take ibuprofen with other medicines that contain ibuprofen to avoid overdose.',
         'times_per_day': 3, 'schedule': 'Morning, afternoon, evening (with food)'},
        {'id': 4, 'name': 'Ibuprofen', 'strength': '400 mg', 'form': 'Tablet',
         'what': 'Ibuprofen is a common medicine used to reduce pain and ease high temperatures (fevers).',
         'important': 'You can take a dose every 6 to 8 hours. Do not take more than 3 doses in 24 hours.',
         'warning': 'Do not take ibuprofen with other medicines that contain ibuprofen to avoid overdose.',
         'times_per_day': 3, 'schedule': 'Morning, afternoon, evening (with food)'},
        {'id': 5, 'name': 'Ibuprofen', 'strength': '120 mg/5 ml', 'form': 'Oral solution',
         'what': 'Ibuprofen is a common medicine used to reduce pain and ease high temperatures (fevers).',
         'important': 'Measure the dose with the spoon from the box. Follow the leaflet or ask your pharmacist.',
         'warning': 'Do not take ibuprofen with other medicines that contain ibuprofen to avoid overdose.',
         'times_per_day': 3, 'schedule': 'Morning, afternoon, evening (with food)'},
      ];
      for (final m in meds) {
        await d.insert('medications', m);
      }
      await d.insert('my_meds', {'med_id': 1});
      await d.insert('my_meds', {'med_id': 2});
    });
  }

  static Future<List<Med>> myMeds() async {
    final d = await db;
    final r = await d.rawQuery(
        'SELECT m.* FROM medications m JOIN my_meds u ON u.med_id = m.id ORDER BY m.name');
    return r.map(Med.fromMap).toList();
  }

  static Future<List<Med>> search(String q) async {
    final d = await db;
    final r = await d.query('medications',
        where: 'name LIKE ?', whereArgs: ['%$q%'], orderBy: 'name, strength');
    return r.map(Med.fromMap).toList();
  }

  static Future<void> addMine(int medId) async {
    final d = await db;
    await d.insert('my_meds', {'med_id': medId},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<List<String>> medNames() async {
    final d = await db;
    final r = await d.rawQuery('SELECT DISTINCT name FROM medications');
    return r.map((e) => e['name'] as String).toList();
  }

  static Future<void> removeMine(int medId) async {
    final d = await db;
    await d.delete('my_meds', where: 'med_id = ?', whereArgs: [medId]);
  }

  static Future<List<Appt>> appointments() async {
    final d = await db;
    final r = await d.query('appointments', orderBy: 'date, time');
    return r.map(Appt.fromMap).toList();
  }

  static Future<void> addAppt(String type, String date, String time, String doctor) async {
    final d = await db;
    await d.insert('appointments',
        {'type': type, 'date': date, 'time': time, 'doctor': doctor});
  }
}
