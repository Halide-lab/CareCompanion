import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/settings.dart';
import '../widgets/widgets.dart';
import 'screens.dart';

/// Shown the first time the app opens: asks the name, language and text size.
class WelcomeScreen extends StatefulWidget {
  final bool editing;
  const WelcomeScreen({super.key, this.editing = false});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final TextEditingController _c =
      TextEditingController(text: context.read<AppSettings>().userName);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<AppSettings>().setUserName(_c.text.trim());
    if (!mounted) return;
    if (widget.editing) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final ready = _c.text.trim().isNotEmpty;
    OutlineInputBorder border(double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: kGreen, width: w));
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(children: [
              AppLogo(size: sc(context, 44)),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(kAppName,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: kGreen)),
              ),
            ]),
            const SizedBox(height: 18),
            const Bubble('Welcome! Let us get to know you.\nWhat is your name?'),
            const SizedBox(height: 8),
            TextField(
              controller: _c,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'Your name',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(20),
                border: border(2),
                enabledBorder: border(2),
                focusedBorder: border(3),
              ),
            ),
            const SizedBox(height: 22),
            const Text('Language', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final l in const [['en', 'English'], ['nl', 'Nederlands'], ['tr', 'Türkçe']])
              ListTileCard(l[1], selected: s.lang == l[0], onTap: () => s.setLang(l[0])),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: kShadow),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Text size', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Slider(
                    min: 1.0,
                    max: 1.8,
                    divisions: 4,
                    value: s.fontScale,
                    onChanged: (v) => s.setFontScale(v)),
                const Text('Move the slider to make the text bigger or smaller.'),
              ]),
            ),
            const SizedBox(height: 18),
            BigButton(widget.editing ? 'Save' : 'Continue', onTap: ready ? _finish : null),
          ],
        ),
      ),
    );
  }
}
