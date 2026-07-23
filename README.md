# LearnEN

Ứng dụng học tiếng Anh trên điện thoại bằng phương pháp **nhắc nhớ thường xuyên** qua notification và lock screen.

MVP hiện tại target **Android**. Source code dùng **Flutter** nên sau này build iOS rất đơn giản (chỉ cần Mac + Xcode).

## Tính năng MVP

### Cơ bản
- Nhập và lưu câu tiếng Anh
- Nhắc nhớ theo tần suất (15 phút → 4 giờ)
- Notification hiển thị trên **lock screen**
- Nút **🔊 Speak** trên notification để đọc câu (Text-to-Speech)
- Tạo **Collection** để nhóm câu theo chủ đề

### Nâng cao
- Import script từ **YouTube link** (nếu video có phụ đề)
- Upload file **.txt** làm script
- Tự động tách script thành từng câu và lưu (có thể chọn collection)

## Công nghệ (100% miễn phí)

| Thành phần | Công nghệ |
|---|---|
| UI / App | Flutter (Dart) |
| Database local | SQLite (sqflite) |
| Notification | flutter_local_notifications |
| Nhắc định kỳ nền | workmanager |
| Đọc câu | flutter_tts (engine TTS của hệ thống) |
| YouTube subtitle | youtube_explode_dart (không cần API key) |

**Không cần** tài khoản, API key hay AI model cho MVP này.

## Yêu cầu máy dev

1. [Flutter SDK](https://docs.flutter.dev/get-started/install) (đã cài)
2. Android Studio hoặc VS Code + extension Flutter
3. Android SDK (cài qua Android Studio)
4. Điện thoại Android **hoặc** emulator

Kiểm tra môi trường:

```bash
flutter doctor
```

## Chạy app trên Android

```bash
cd E:\code\learnEN
flutter pub get
flutter run
```

Nếu có nhiều thiết bị:

```bash
flutter devices
flutter run -d <device_id>
```

Build APK cài thử:

```bash
flutter build apk --debug
```

File APK: `build/app/outputs/flutter-apk/app-debug.apk`

## Hướng dẫn sử dụng nhanh

1. Mở app → tab **Home** → **Thêm câu**
2. Tab **Settings** → bật nhắc nhớ, chọn tần suất
3. Nhấn **Gửi notification thử** để kiểm tra lock screen + TTS
4. Tab **Import** → dán link YouTube hoặc upload `.txt`
5. Tab **Collections** → tạo nhóm câu (Business, IELTS, ...)

### Lock screen trên Android

- Khi cài lần đầu, app sẽ xin quyền **Notifications** → chọn **Allow**
- Vào **Settings > Apps > LearnEN > Notifications** → bật **Show on lock screen**
- Một số máy (Xiaomi, Samsung, Oppo) cần tắt battery optimization cho app để nhắc chạy nền ổn định

### TTS (đọc câu)

- Dùng engine TTS có sẵn trên Android
- Vào **Settings > System > Text-to-speech** → chọn English (US) nếu chưa có

## Cấu trúc source code

```
lib/
├── main.dart                 # Entry point
├── app.dart                  # Root widget + Provider
├── models/                   # Sentence, Collection, Settings
├── database/                 # SQLite helper
├── services/
│   ├── notification_service.dart
│   ├── reminder_service.dart
│   ├── tts_service.dart
│   ├── youtube_service.dart
│   └── script_parser_service.dart
├── providers/                # State management
├── screens/                  # UI màn hình
├── widgets/                  # Component tái sử dụng
└── theme/                    # Material 3 theme
```

## Build iOS (giai đoạn sau)

Cần Mac với Xcode:

```bash
flutter build ios
```

Một số quyền notification/TTS trên iOS sẽ cần cấu hình thêm trong `ios/Runner/Info.plist`.

## Giới hạn MVP cần biết

| Hạng mục | Giới hạn |
|---|---|
| Tần suất nhắc | Android tối thiểu **15 phút/lần** (giới hạn WorkManager) |
| YouTube | Chỉ video **có phụ đề** (manual hoặc auto-generated) |
| TTS từ notification nền | Một số máy có thể cần mở app trước khi TTS hoạt động lần đầu |
| Battery saver | Có thể delay notification nếu hệ thống tiết kiệm pin mạnh |

## Roadmap gợi ý (v2)

- [ ] Spaced repetition thông minh (ưu tiên câu hay quên)
- [ ] Dịch nghĩa câu (có thể dùng GPT API)
- [ ] Widget màn hình chính Android
- [ ] Đồng bộ cloud (Firebase / backend Java của bạn)
- [ ] Thống kê tiến độ học

## License

Private project — dùng cho mục đích học tập cá nhân.
