import os, re
NAME = "CareCompanion"

# pubspec.yaml -> flutter_launcher_icons ayarı
p = 'pubspec.yaml'
s = open(p).read()
if 'flutter_launcher_icons:' not in s:
    if not s.endswith('\n'):
        s += '\n'
    s += '''
flutter_launcher_icons:
  android: true
  ios: true
  macos:
    generate: true
  image_path: "assets/icon/icon.png"
  remove_alpha_ios: true
'''
    open(p, 'w').write(s)
    print('pubspec.yaml: ikon ayarı eklendi')

# Android uygulama adı
p = 'android/app/src/main/AndroidManifest.xml'
if os.path.exists(p):
    s = open(p).read()
    s = re.sub(r'android:label="[^"]*"', 'android:label="%s"' % NAME, s, count=1)
    open(p, 'w').write(s)
    print('Android adı:', NAME)

# iOS uygulama adı
p = 'ios/Runner/Info.plist'
if os.path.exists(p):
    s = open(p).read()
    s = re.sub(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)', r'\g<1>%s\g<2>' % NAME, s, count=1)
    open(p, 'w').write(s)
    print('iOS adı:', NAME)
print('Bitti.')
