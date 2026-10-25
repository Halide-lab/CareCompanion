import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/db.dart';
import '../services/settings.dart';
import '../widgets/widgets.dart';
import 'voice_screen.dart';

void go(BuildContext c, Widget w) => Navigator.push(c, MaterialPageRoute(builder: (_) => w));
Widget pad(List<Widget> kids) =>
    ListView(padding: const EdgeInsets.all(18), children: kids);

// ---------------- HOME (Figma'daki gibi) ----------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final msg = '$_greeting, Anna. Choose a category.';

    Widget tile(String t, IconData i, Color color, Widget page) => Expanded(
          child: HomeTile(
              label: t, icon: i, color: color, onTap: () => go(context, page)),
        );

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Tap(
          label: 'Talk to your assistant',
          radius: 28,
          onTap: () => go(context, const VoiceScreen()),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: sc(context, 18)),
            decoration: BoxDecoration(
                color: kGreen,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Color(0x40000000), blurRadius: 14, offset: Offset(0, 6))
                ]),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.mic_rounded, color: Colors.white, size: sc(context, 36)),
              const SizedBox(width: 12),
              const Flexible(
                child: Text('Talk to your assistant',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ]),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
          children: [
            Row(children: [
              AppLogo(size: sc(context, 44)),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: const Text(kAppName,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: kGreen)),
                ),
              ),
              IconButton(
                  tooltip: 'Settings',
                  iconSize: sc(context, 30),
                  color: kGreen,
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => go(context, const SettingsScreen())),
            ]),
            const SizedBox(height: 18),
            Bubble(msg),
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              tile('Appointments', Icons.calendar_month_rounded, kGreen, const AppointmentsScreen()),
              const SizedBox(width: 16),
              tile('Medications', Icons.medication_rounded, kGreen, const MyMedsScreen()),
            ]),
            const SizedBox(height: 22),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              tile('My Health', Icons.favorite_rounded, kGreen, const HealthScreen()),
              const SizedBox(width: 16),
              tile('Help', Icons.help_outline_rounded, kOrange, const HelpScreen()),
            ]),
          ],
        ),
      ),
    );
  }
}

// ---------------- SETTINGS ----------------
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: pad([
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: kShadow),
          child: SwitchListTile(
            title: const Text('Read aloud on tap', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            subtitle: const Text('The app reads everything you tap.'),
            value: s.readAloud,
            onChanged: (v) {
              s.setReadAloud(v);
              if (v) s.speak('Read aloud is on');
            },
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: kShadow),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Text size', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Slider(
                min: 1.0, max: 1.8, divisions: 4,
                value: s.fontScale,
                onChanged: (v) => s.setFontScale(v)),
            const Text('Move the slider to make the text bigger or smaller.'),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('Voice language', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Used for talking to the app and for reading aloud.'),
        const SizedBox(height: 10),
        for (final l in const [['en', 'English'], ['nl', 'Nederlands'], ['tr', 'Türkçe']])
          ListTileCard(l[1], selected: s.lang == l[0], onTap: () => s.setLang(l[0])),
      ]),
    );
  }
}

// ---------------- APPOINTMENTS ----------------
const _mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
const _wd = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
String fmtDate(DateTime d) => '${_wd[d.weekday - 1]} ${d.day} ${_mo[d.month - 1]}';
String iso(DateTime d) => d.toIso8601String().substring(0, 10);

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  late Future<List<Appt>> f = Db.appointments();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Appointments')),
        body: FutureBuilder<List<Appt>>(
          future: f,
          builder: (c, snap) {
            final list = snap.data ?? [];
            return pad([
              if (snap.hasError)
                Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red, fontSize: 18)),
              const Bubble('Upcoming Appointments'),
              if (list.isEmpty) const Bubble('You have no appointments yet.'),
              for (final a in list)
                ListTileCard(a.type, icon: Icons.event_available_rounded,
                    subtitle: '${fmtDate(DateTime.parse(a.date))} at ${a.time}\n${a.doctor}'),
              const SizedBox(height: 8),
              BigButton('Make an Appointment', icon: Icons.add, onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingScreen()));
                setState(() { f = Db.appointments(); });
              }),
            ]);
          },
        ),
      );
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int step = 0;
  String? type, time, doctor;
  DateTime? date;
  final dates = List.generate(4, (i) => DateTime.now().add(Duration(days: i + 1)));

  void next() => setState(() => step++);
  void back() => step == 0 || step == 5 ? Navigator.pop(context) : setState(() => step--);

  Widget opts(List<String> items, String? sel, void Function(String) pick) => Column(children: [
        for (final i in items) ListTileCard(i, selected: sel == i, onTap: () => setState(() => pick(i)))
      ]);

  @override
  Widget build(BuildContext context) {
    final titles = ['Choose a doctor', 'Choose a date', 'Choose a time', 'Choose a doctor', 'Check your booking', 'Confirmed'];
    final bubbles = [
      'Step 1 of 5\nWho do you need to see?',
      'Step 2 of 5\nChoose an available date.',
      'Step 3 of 5\nChoose a time.',
      'Step 4 of 5\nChoose a doctor.',
      'Step 5 of 5\nCheck these details.',
      'Your appointment has been confirmed.'
    ];
    Widget body;
    VoidCallback? action;
    String actionText = 'Confirm';
    switch (step) {
      case 0:
        body = opts(['GP (Family Doctor)', 'Hospital Specialist'], type, (v) => type = v);
        action = type == null ? null : next;
      case 1:
        body = Column(children: [
          for (final d in dates)
            ListTileCard(fmtDate(d), subtitle: 'Available', selected: date == d, onTap: () => setState(() => date = d))
        ]);
        action = date == null ? null : next;
      case 2:
        body = opts(['09:00', '10:30', '14:00', '15:30'], time, (v) => time = v);
        action = time == null ? null : next;
      case 3:
        body = opts(['Dr. Emma van Dijk', 'Dr. Thomas de Vries', 'Dr. Laura Bakker', 'Dr. van den Berg'], doctor, (v) => doctor = v);
        action = doctor == null ? null : next;
      case 4:
        body = Column(children: [
          ListTileCard(type!, subtitle: 'Appointment type'),
          ListTileCard('${fmtDate(date!)} at $time', subtitle: 'Date & time'),
          ListTileCard(doctor!, subtitle: 'Doctor'),
        ]);
        actionText = 'Confirm Appointment';
        action = () async {
          await Db.addAppt(type!, iso(date!), time!, doctor!);
          next();
        };
      default:
        body = ListTileCard('GP Appointment', subtitle: '${fmtDate(date!)} at $time\n$doctor');
        actionText = 'Back to Home';
        action = () => Navigator.popUntil(context, (r) => r.isFirst);
    }
    return Scaffold(
      appBar: AppBar(
          title: Text(titles[step]),
          leading: step == 5 ? const SizedBox() : IconButton(icon: const Icon(Icons.arrow_back), onPressed: back)),
      body: pad([
        Bubble(bubbles[step]),
        body,
        const SizedBox(height: 8),
        BigButton(actionText, onTap: action),
        if (step == 4) ...[const SizedBox(height: 12), BigButton('Change Details', outlined: true, onTap: () => setState(() => step = 0))],
      ]),
    );
  }
}

// ---------------- MEDICATIONS ----------------
class MyMedsScreen extends StatefulWidget {
  const MyMedsScreen({super.key});
  @override
  State<MyMedsScreen> createState() => _MyMedsScreenState();
}

class _MyMedsScreenState extends State<MyMedsScreen> {
  late Future<List<Med>> f = Db.myMeds();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Medications')),
        body: FutureBuilder<List<Med>>(
          future: f,
          builder: (c, snap) => pad([
            if (snap.hasError)
              Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red, fontSize: 18)),
            for (final m in snap.data ?? [])
              ListTileCard(m.name, icon: Icons.medication_rounded,
                  subtitle: '${m.strength} · ${m.form}\n${m.timesText} · ${m.schedule}',
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => MedInfoScreen(m, canRemove: true)));
                    setState(() { f = Db.myMeds(); });
                  }),
            const SizedBox(height: 8),
            BigButton('Search Medication', icon: Icons.search, outlined: true, onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchMedScreen()));
              setState(() { f = Db.myMeds(); });
            }),
          ]),
        ),
      );
}

class SearchMedScreen extends StatefulWidget {
  final String initial;
  const SearchMedScreen({super.key, this.initial = ''});
  @override
  State<SearchMedScreen> createState() => _SearchMedScreenState();
}

class _SearchMedScreenState extends State<SearchMedScreen> {
  List<Med> results = [];
  String q = '';
  late final TextEditingController _c = TextEditingController(text: widget.initial);

  @override
  void initState() {
    super.initState();
    if (widget.initial.isNotEmpty) run(widget.initial);
  }

  Future<void> run(String v) async {
    q = v;
    try {
      final r = v.trim().isEmpty ? <Med>[] : await Db.search(v.trim());
      setState(() => results = r);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red, content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Search Medication')),
        body: pad([
          const Bubble('Which medicine are you looking for?'),
          TextField(
            controller: _c,
            autofocus: true,
            style: const TextStyle(fontSize: 22),
            decoration: InputDecoration(
                hintText: 'Type the medicine name',
                filled: true, fillColor: Colors.white,
                prefixIcon: Icon(Icons.search, size: sc(context, 30)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
            onChanged: run,
          ),
          const SizedBox(height: 16),
          if (q.isNotEmpty && results.isEmpty) const Bubble('No medicine found.'),
          for (final m in results) ...[
            ListTileCard(m.name, icon: Icons.medication_rounded, subtitle: '${m.strength} · ${m.form}'),
            BigButton('View information', outlined: true, onTap: () => go(context, MedInfoScreen(m))),
            const SizedBox(height: 8),
            BigButton('Add to my list', icon: Icons.add, onTap: () async {
              try {
                await Db.addMine(m.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${m.name} ${m.strength} added to your list')));
                Navigator.pop(context);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.red, content: Text('Error: $e')));
              }
            }),
            const SizedBox(height: 20),
          ],
        ]),
      );
}

class MedInfoScreen extends StatelessWidget {
  final Med m;
  final bool canRemove;
  const MedInfoScreen(this.m, {super.key, this.canRemove = false});
  @override
  Widget build(BuildContext context) {
    final all = '${m.name} ${m.strength}. What is it? ${m.what} How often? ${m.timesText}. ${m.schedule}. '
        'Important information. ${m.important} Warnings. ${m.warning}';
    Widget section(String t, String body, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Tap(
            label: '$t. $body',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: color ?? Colors.white,
                  border: Border.all(color: color == null ? Colors.black12 : Colors.red),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(body, style: const TextStyle(fontSize: 19)),
              ]),
            ),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Medication Info')),
      body: pad([
        ListTileCard(m.name, icon: Icons.medication_rounded, subtitle: '${m.strength} · ${m.form}'),
        BigButton('Listen to this information', icon: Icons.volume_up,
            onTap: () => context.read<AppSettings>().speak(all, force: true)),
        const SizedBox(height: 14),
        section('What is it?', m.what),
        section('How often should I take it?', '${m.timesText}\n${m.schedule}'),
        section('Important information', m.important),
        section('Warnings', m.warning, color: const Color(0xFFFDECEC)),
        if (canRemove) ...[
          const SizedBox(height: 10),
          Tap(
            label: 'Remove from my list',
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Are you sure?', style: TextStyle(fontSize: 26)),
                  content: Text('Remove ${m.name} ${m.strength} from your list?',
                      style: const TextStyle(fontSize: 21)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('No, keep it', style: TextStyle(fontSize: 21))),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Yes, remove',
                            style: TextStyle(fontSize: 21, color: Colors.red))),
                  ],
                ),
              );
              if (ok == true) {
                await Db.removeMine(m.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: sc(context, 16), horizontal: 12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.delete_outline, color: Colors.red, size: sc(context, 28)),
                const SizedBox(width: 10),
                const Flexible(
                  child: Text('Remove from my list',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red, fontSize: 21, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Health')),
        body: pad([
          const Bubble('Anna, choose a health category.'),
          const Text('Fictional information. Not medical advice.'),
          const SizedBox(height: 12),
          ListTileCard('Health Summary', subtitle: 'Conditions and allergies', icon: Icons.favorite_border,
              onTap: () => go(context, const InfoList('My Health Summary', 'Your health at a glance.', [
                    ['Allergy: penicillin', 'Recorded reaction: skin rash.'],
                    ['High blood pressure', 'Your GP checks your blood pressure at routine visits.'],
                    ['Knee joint pain', 'Pain in your right knee. Discussed with your GP on 12 September.'],
                  ]))),
          ListTileCard('Medical History', subtitle: 'Your previous visits', icon: Icons.history,
              onTap: () => go(context, const InfoList('My Medical History', 'Your past visits, newest first.', [
                    ['10 October · Blood pressure review', 'Your GP checked your blood pressure and blood test.'],
                    ['8 October · Routine blood check', 'Blood sample taken. See Test Results.'],
                    ['12 September · Right knee pain', 'Your GP examined your right knee and discussed the pain.'],
                  ]))),
          ListTileCard('Test Results', subtitle: 'Results checked by your doctor', icon: Icons.assignment,
              onTap: () => go(context, const InfoList('My Test Results', 'Your doctor has reviewed these results.', [
                    ['10 October · Blood pressure: 138 / 78 mmHg', "Doctor's note: within your agreed target at this visit."],
                    ['8 October · Haemoglobin: 128 g/L', 'Within this laboratory\'s usual range.'],
                    ['Reviewed by Dr. van den Berg', 'A single result does not give a diagnosis. Your doctor explains it alongside your health history.'],
                  ]))),
        ]),
      );
}

class InfoList extends StatelessWidget {
  final String title, intro;
  final List<List<String>> items;
  const InfoList(this.title, this.intro, this.items, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: pad([
          Bubble(intro),
          for (final i in items) ListTileCard(i[0], subtitle: i[1]),
          const Text('You are only viewing information. You will not change your record.'),
        ]),
      );
}

// ---------------- HELP ----------------
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Help & Support')),
        body: pad([
          const Text('How to Use the App', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Bubble('Hello Anna. I can guide you, one step at a time.'),
          ListTileCard('Book an Appointment', subtitle: 'Help to arrange a visit', icon: Icons.calendar_month,
              onTap: () => go(context, const Guide('Book an Appointment', "Let's arrange a visit, Anna.", [
                    'Tap Continue to Appointments below.',
                    'On Appointments, tap Make an Appointment.',
                    'Choose doctor type, date, time and doctor. Check the details before you confirm.'
                  ], 'Continue to My Appointments', AppointmentsScreen()))),
          ListTileCard('Find My Medication', subtitle: 'Help to find a medicine', icon: Icons.medication,
              onTap: () => go(context, const Guide('My Medications', "Let's see your medicine, Anna.", [
                    'Tap Open My Medications below to see your list.',
                    'To find another medicine, tap Search Medication.',
                    'Tap the search box and type the medicine name. Then tap the matching result.'
                  ], 'Continue to My Medications', MyMedsScreen()))),
          ListTileCard('View My Health', subtitle: 'Help to read your record', icon: Icons.favorite_border,
              onTap: () => go(context, const Guide('View My Health', "Let's look at your health record, Anna.", [
                    'Tap Open My Health below.',
                    'Choose Health Summary, Medical History or Test Results.',
                    'Read that category. Tap back to return to My Health.'
                  ], 'Back to Home', null))),
        ]),
      );
}

class Guide extends StatelessWidget {
  final String title, intro, button;
  final List<String> steps;
  final Widget? next;
  const Guide(this.title, this.intro, this.steps, this.button, this.next, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: pad([
          Bubble(intro),
          BigButton('Listen to Instructions', icon: Icons.volume_up, onTap: () {
            context.read<AppSettings>().speak(
                [for (var i = 0; i < steps.length; i++) 'Step ${i + 1}. ${steps[i]}'].join(' '),
                force: true);
          }),
          const SizedBox(height: 14),
          for (var i = 0; i < steps.length; i++) ListTileCard('${i + 1}. ${steps[i]}'),
          const SizedBox(height: 8),
          BigButton(button, onTap: () {
            if (next == null) {
              Navigator.popUntil(context, (r) => r.isFirst);
            } else {
              go(context, next!);
            }
          }),
        ]),
      );
}
