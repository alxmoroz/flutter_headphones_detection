# headphones_detection

一个用于在 Android 和 iOS 设备上检测耳机连接状态并获取设备信息的 Flutter 插件。

[English](README.md) | [中文文档](README.zh.md)

## 功能特性

- ✅ 检测有线耳机连接
- ✅ 检测蓝牙耳机连接 (A2DP, SCO, HFP, LE)
- ✅ 获取设备名称和连接类型
- ✅ 访问平台特定的设备元数据
- ✅ 跨平台支持 (Android & iOS)
- ✅ 流式支持，实时监控
- ✅ 周期性检查，可靠更新

## 安装

在你的 `pubspec.yaml` 文件中添加：

```yaml
dependencies:
  headphones_detection: ^1.0.2
```

## 使用方法

### 基本用法

```dart
import 'package:headphones_detection/headphones_detection.dart';

// 检查耳机是否连接并获取设备信息
HeadphonesInfo? headphonesInfo = await HeadphonesDetection.isHeadphonesConnected();

if (headphonesInfo != null) {
  print('耳机已连接: ${headphonesInfo.name}');
  print('连接类型: ${headphonesInfo.type}');
  // 类型: 'wired', 'bluetoothA2DP', 'bluetoothSCO', 'bluetoothHFP', 'bluetoothLE'
  
  // 访问元数据获取平台特定信息
  if (headphonesInfo.metadata != null) {
    print('元数据: ${headphonesInfo.metadata}');
  }
} else {
  print('未连接耳机');
}
```

### 流式用法

```dart
import 'package:headphones_detection/headphones_detection.dart';

// 监听耳机连接变化并获取设备信息
HeadphonesDetection.headphonesStream.listen((headphonesInfo) {
  if (headphonesInfo != null) {
    print('耳机已连接: ${headphonesInfo.name} (${headphonesInfo.type})');
  } else {
    print('耳机已断开');
  }
});

// 或使用周期性检查
HeadphonesDetection.getPeriodicStream(interval: Duration(seconds: 1))
  .listen((headphonesInfo) {
    if (headphonesInfo != null) {
      print('已连接: ${headphonesInfo.name}');
    } else {
      print('已断开');
    }
  });
```

### HeadphonesInfo 类

`HeadphonesInfo` 类提供已连接耳机的详细信息：

```dart
class HeadphonesInfo {
  final String name;        // 设备名称 (例如: "AirPods Pro", "有线耳机")
  final String type;        // 连接类型 (wired, bluetoothA2DP 等)
  final Map<String, dynamic>? metadata;  // 平台特定的元数据
}
```

### 错误处理

```dart
try {
  HeadphonesInfo? headphonesInfo = await HeadphonesDetection.isHeadphonesConnected();
  if (headphonesInfo != null) {
    print('已连接: ${headphonesInfo.name}');
  }
} on HeadphonesDetectionException catch (e) {
  print('错误: ${e.message}');
}
```

## 平台支持

### Android
- 通过 `AudioManager.isWiredHeadsetOn()` 检测有线耳机
- 通过 `AudioManager.isBluetoothA2dpOn()` 检测蓝牙 A2DP 设备
- 通过 `AudioManager.isBluetoothScoOn()` 检测蓝牙 SCO 设备
- 使用 `AudioDeviceInfo` API (Android 6.0+) 获取详细设备信息
- 在元数据中提供设备名称、产品名称、设备 ID 和地址
- 对旧版 Android 回退到传统方法

### iOS
- 通过 `AVAudioSession.currentRoute.outputs` 检测耳机
- 检测蓝牙设备 (A2DP, HFP, LE)
- 通过 `AVAudioSession.routeChangeNotification` 实现实时音频路由变化通知
- 从 `AVAudioSessionPortDescription` 获取设备名称
- 在元数据中包含端口名称、端口类型和 UID
- 最低 iOS 版本: 13.0

## 权限

### Android
在你的 `android/app/src/main/AndroidManifest.xml` 中添加：

```xml
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

### iOS
无需额外权限。

## 示例

查看 `example/` 目录获取完整的示例应用。

## 贡献

欢迎贡献！请随时提交 Pull Request。

## 许可证

本项目采用 MIT 许可证 - 详情请参阅 LICENSE 文件。
 
## 问题反馈

如果遇到任何问题，请在 [GitHub Issues](https://github.com/alxmoroz/headphones_detection_flutter/issues) 提交。

