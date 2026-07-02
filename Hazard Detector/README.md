# ESP32 Fire Alarm — Flutter App

Industrial-aesthetic companion app for the ESP32 fire alarm system.  
Connects via WiFi + WebSocket for real-time sensor data.

## Architecture

```
ESP32 WebSocket Server (:81)
        │ JSON every 4s
        ▼
WebSocketService (singleton, auto-reconnect)
        │ Stream<FireAlarmState>
        ▼
Riverpod StreamProvider
        │
        ├── DashboardScreen   ← sensor cards + sparkline charts
        ├── AlarmScreen       ← auto-redirected on alarm (pulsing red)
        ├── HistoryScreen     ← persisted alarm log
        └── SettingsScreen    ← configure WS URI
```

## Project Structure

```
lib/
├── main.dart
├── router.dart                  # GoRouter with alarm redirect
├── models/
│   └── fire_alarm_state.dart    # FireAlarmState, AlarmFlags, AlarmEvent
├── providers/
│   └── providers.dart           # All Riverpod providers
├── services/
│   ├── websocket_service.dart   # WS connection + auto-reconnect
│   └── notification_service.dart
├── screens/
│   ├── dashboard_screen.dart
│   ├── alarm_screen.dart
│   ├── history_screen.dart
│   └── settings_screen.dart
├── widgets/
│   ├── status_header.dart
│   ├── sensor_card.dart
│   └── connection_badge.dart
└── theme/
    └── app_theme.dart
```

## Setup

### 1. ESP32 Firmware

1. Open `esp32_websocket_server.ino` in Arduino IDE
2. Install libraries via Library Manager:
   - **WebSockets** by Markus Sattler
   - **ArduinoJson** by Benoit Blanchon
   - **DHT sensor library** by Adafruit
3. Set your WiFi credentials:
   ```cpp
   const char* WIFI_SSID = "YOUR_SSID";
   const char* WIFI_PASS = "YOUR_PASSWORD";
   ```
4. Flash to ESP32. Serial monitor will print the IP address:
   ```
   Connected! IP: 192.168.1.100
   WebSocket server: ws://192.168.1.100:81
   ```

### 2. Flutter App

```bash
flutter pub get
flutter run
```

First launch: go to **Settings** and set the WebSocket URI to match your ESP32's IP:
```
ws://192.168.1.100:81
```

### 3. Android Permissions (AndroidManifest.xml)

Add inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

Add inside `<application>`:
```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
```

### 4. iOS (Info.plist)

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Required to connect to the ESP32 fire alarm system on your local network.</string>
```

## Key Design Decisions

| Decision | Choice | Reason |
|---|---|---|
| State management | Riverpod | Type-safe, testable, no BuildContext needed |
| WS reconnect | 5s timer | Survives router restarts and ESP32 reboots |
| Alarm notification | Onset-only | Fires once when alarm starts, cancels when safe |
| Alarm routing | GoRouter redirect | Automatic, works from any screen |
| History persistence | SharedPreferences | Lightweight, survives app restarts |
| Chart points | Last 30 readings | ~2 minutes of live trend data |

## Extending

**Add BLE support**: Swap `WebSocketService` for a `BleService` implementing the same `Stream<FireAlarmState>` interface — no other code changes needed.

**Add sound alerts**: In `NotificationService.showAlarmNotification()`, set a custom sound file.

**Add remote access**: Put the ESP32 behind a WebSocket proxy (e.g. nginx) and change the URI to `wss://your-domain.com/alarm`.
