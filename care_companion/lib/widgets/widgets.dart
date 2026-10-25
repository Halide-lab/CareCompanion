import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/settings.dart';

/// Yazı büyüdükçe ikon, daire ve boşluklar da aynı oranda büyür.
double sc(BuildContext c, double v) => MediaQuery.textScalerOf(c).scale(v);

const kShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3)),
];
const kGradient = LinearGradient(
    colors: [Color(0xFF2E7D74), kGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight);
const kBubbleBg = Color(0xFFEAF3F0);
const kBubbleBorder = Color(0xFFCFE0DB);

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 40});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset('assets/icon/icon.png', width: size, height: size, fit: BoxFit.cover),
      );
}

class Tap extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget child;
  final double radius;
  const Tap({super.key, required this.label, required this.child, this.onTap, this.radius = 20});
  @override
  State<Tap> createState() => _TapState();
}

class _TapState extends State<Tap> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => Semantics(
        button: widget.onTap != null,
        label: widget.label,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.radius),
            onHighlightChanged: (v) => setState(() => _down = v),
            onTap: () {
              context.read<AppSettings>().speak(widget.label);
              widget.onTap?.call();
            },
            child: Stack(children: [
              widget.child,
              if (widget.onTap != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        color: _down ? const Color(0x26000000) : Colors.transparent,
                        borderRadius: BorderRadius.circular(widget.radius),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      );
}

class BigButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool outlined;
  const BigButton(this.text, {super.key, this.onTap, this.icon, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final fg = outlined ? kGreen : Colors.white;
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Tap(
        label: text,
        onTap: onTap,
        radius: 18,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: sc(context, 68)),
          padding: EdgeInsets.symmetric(vertical: sc(context, 14), horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: outlined ? Colors.white : kGreen,
              border: Border.all(color: kGreen, width: 2),
              borderRadius: BorderRadius.circular(18)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[
              Icon(icon, color: fg, size: sc(context, 30)),
              const SizedBox(width: 10)
            ],
            Flexible(
                child: Text(text,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: fg, fontSize: 21, fontWeight: FontWeight.w800))),
          ]),
        ),
      ),
    );
  }
}

class ListTileCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  const ListTileCard(this.title, {super.key, this.subtitle, this.icon, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Tap(
          label: subtitle == null ? title : '$title. $subtitle',
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            constraints: BoxConstraints(minHeight: sc(context, 76)),
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: sc(context, 14)),
            decoration: BoxDecoration(
                color: selected ? const Color(0xFFD9ECE8) : Colors.white,
                border: Border.all(color: selected ? kGreen : const Color(0x14000000), width: selected ? 3 : 1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: kShadow),
            child: Row(children: [
              if (icon != null) ...[
                Container(
                  padding: EdgeInsets.all(sc(context, 10)),
                  decoration: const BoxDecoration(color: Color(0xFFE3EFEC), shape: BoxShape.circle),
                  child: Icon(icon, color: kGreen, size: sc(context, 28)),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: const TextStyle(fontSize: 19, height: 1.3)),
                  ),
              ])),
              if (selected)
                Icon(Icons.check_circle_rounded, color: kGreen, size: sc(context, 30))
              else if (onTap != null)
                Icon(Icons.chevron_right_rounded, size: sc(context, 34), color: kGreen),
            ]),
          ),
        ),
      );
}

class Bubble extends StatelessWidget {
  final String text;
  const Bubble(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Tap(
          label: text,
          radius: 22,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(sc(context, 16)),
            decoration: BoxDecoration(
                color: kBubbleBg,
                border: Border.all(color: kBubbleBorder, width: 1.5),
                borderRadius: BorderRadius.circular(22)),
            child: Row(children: [
              Container(
                width: sc(context, 52),
                height: sc(context, 52),
                decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                child: Icon(Icons.person_outline_rounded, color: Colors.white, size: sc(context, 30)),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(text,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3))),
            ]),
          ),
        ),
      );
}

class HomeTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const HomeTile(
      {super.key, required this.label, required this.icon, required this.color, required this.onTap});
  @override
  State<HomeTile> createState() => _HomeTileState();
}

class _HomeTileState extends State<HomeTile> {
  bool _down = false;
  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: () {
          context.read<AppSettings>().speak(widget.label);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AspectRatio(
              aspectRatio: 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                decoration: BoxDecoration(
                  color: _down ? Color.lerp(c, Colors.black, 0.22) : c,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: c.withAlpha(_down ? 70 : 120),
                      blurRadius: _down ? 8 : 22,
                      offset: Offset(0, _down ? 3 : 10),
                    ),
                  ],
                ),
                child: Center(
                    child: Icon(widget.icon, color: Colors.white, size: sc(context, 58))),
              ),
            ),
            const SizedBox(height: 12),
            Text(widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}
