import os, re

def insert_before_last_dict_end(path, key, snippet):
    if not os.path.exists(path):
        return
    s = open(path).read()
    if key in s:
        return
    i = s.rindex('</dict>')
    s = s[:i] + snippet + s[i:]
    open(path, 'w').write(s)
    print('Eklendi:', key, '->', path)

MIC = ('\t<key>NSMicrophoneUsageDescription</key>\n'
       '\t<string>CareCompanion uses the microphone so you can talk to the app.</string>\n')
SPEECH = ('\t<key>NSSpeechRecognitionUsageDescription</key>\n'
          '\t<string>CareCompanion turns your speech into commands.</string>\n')

# iOS + macOS Info.plist
for p in ['ios/Runner/Info.plist', 'macos/Runner/Info.plist']:
    insert_before_last_dict_end(p, 'NSMicrophoneUsageDescription', MIC)
    insert_before_last_dict_end(p, 'NSSpeechRecognitionUsageDescription', SPEECH)

# macOS entitlements (mikrofon + internet)
for p in ['macos/Runner/DebugProfile.entitlements', 'macos/Runner/Release.entitlements']:
    insert_before_last_dict_end(p, 'com.apple.security.device.audio-input',
        '\t<key>com.apple.security.device.audio-input</key>\n\t<true/>\n')
    insert_before_last_dict_end(p, 'com.apple.security.network.client',
        '\t<key>com.apple.security.network.client</key>\n\t<true/>\n')

# Android
p = 'android/app/src/main/AndroidManifest.xml'
if os.path.exists(p):
    s = open(p).read()
    if 'android.permission.RECORD_AUDIO' not in s:
        add = ('\n    <uses-permission android:name="android.permission.RECORD_AUDIO"/>'
               '\n    <uses-permission android:name="android.permission.INTERNET"/>'
               '\n    <queries>\n        <intent>\n'
               '            <action android:name="android.speech.RecognitionService"/>\n'
               '        </intent>\n    </queries>')
        s = re.sub(r'(<manifest[^>]*>)', lambda m: m.group(1) + add, s, count=1)
        open(p, 'w').write(s)
        print('Android izinleri eklendi')
print('Bitti.')
