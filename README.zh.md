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
- ✅ 获取当前实际用于播放的音频输出设备
- ✅ 获取所有可用的音频输出设备列表（iOS）
- ✅ 强制设置音频输出到耳机（解决多设备连接时的路由问题）
- ✅ 便捷方法：自动检查当前输出是否是耳机并确保使用（`ensureUsingHeadphonesIfAvailable()`）

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

### 获取当前音频输出设备

当耳机同时连接到多个设备时（例如 AirPods 同时连接到 iPhone 和 Mac），你可能需要检查当前实际用于播放音频的设备：

```dart
// 获取当前实际用于播放的音频输出设备
HeadphonesInfo? currentOutput = await HeadphonesDetection.getCurrentAudioOutputDevice();

if (currentOutput != null) {
  print('当前音频输出: ${currentOutput.name}');
} else {
  print('音频正在通过扬声器播放');
}
```

### 获取所有可用的音频输出设备

获取当前所有可用的音频输出设备列表，每个设备都标记了是否是耳机：

```dart
// 获取所有可用的音频输出设备
List<AudioOutputDevice> devices = await HeadphonesDetection.getAvailableAudioOutputDevices();

// 打印所有设备
for (var device in devices) {
  print('设备: ${device.name}');
  print('  类型: ${device.type}');
  print('  是否是耳机: ${device.isHeadphones}');
  print('  是否当前输出: ${device.isCurrentOutput}');
}

// 找出所有耳机设备
List<AudioOutputDevice> headphones = devices.where((d) => d.isHeadphones).toList();

// 找出当前使用的输出设备
AudioOutputDevice? currentDevice = devices.firstWhere(
  (d) => d.isCurrentOutput,
  orElse: () => null,
);

// 如果有耳机可用，尝试使用耳机播放
if (headphones.isNotEmpty) {
  bool success = await HeadphonesDetection.setAudioOutputToHeadphones();
  if (success) {
    print('已成功设置音频输出到耳机');
  }
}
```

### 强制使用耳机播放

如果检测到耳机已连接，但音频没有路由到耳机（例如 AirPods 连接到了 Mac），可以尝试强制设置音频输出到耳机：

```dart
// 方法1: 使用便捷方法（推荐）
// 自动检查当前输出是否是耳机，如果是就确保使用它们
bool success = await HeadphonesDetection.ensureUsingHeadphonesIfAvailable();

if (success) {
  print('音频正在通过耳机播放');
  playAudio(); // 播放音频
} else {
  print('无法使用耳机（可能耳机未连接或不可用）');
  showError('请连接耳机');
}

// 方法2: 手动检查和控制
// 检查当前实际用于播放的设备
HeadphonesInfo? currentOutput = await HeadphonesDetection.getCurrentAudioOutputDevice();

if (currentOutput != null) {
  // 当前输出是耳机，确保路由正确
  bool success = await HeadphonesDetection.setAudioOutputToHeadphones();
  if (success) {
    print('已确保音频通过耳机播放: ${currentOutput.name}');
  }
} else {
  // 当前输出不是耳机，检查是否有耳机可用
  HeadphonesInfo? connected = await HeadphonesDetection.isHeadphonesConnected();
  if (connected != null) {
    // 耳机已连接但音频没有路由到耳机，尝试强制设置
    bool success = await HeadphonesDetection.setAudioOutputToHeadphones();
    if (success) {
      print('已成功设置音频输出到耳机: ${connected.name}');
    }
  } else {
    print('未检测到耳机连接');
  }
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
- `getCurrentAudioOutputDevice()` 返回当前实际用于播放的音频输出设备
- `setAudioOutputToHeadphones()` 在 Android 12+ (API 31+) 使用 `setCommunicationDevice()`，在旧版本使用 Bluetooth SCO 或自动路由
- 对旧版 Android 回退到传统方法

### iOS
- 通过 `AVAudioSession.currentRoute.outputs` 检测耳机
- 检测蓝牙设备 (A2DP, HFP, LE)
- 通过 `AVAudioSession.routeChangeNotification` 实现实时音频路由变化通知
- 从 `AVAudioSessionPortDescription` 获取设备名称
- 在元数据中包含端口名称、端口类型和 UID
- `getCurrentAudioOutputDevice()` 返回当前实际用于播放的音频输出设备
- `getAvailableAudioOutputDevices()` 返回所有可用的音频输出设备列表，包括耳机、扬声器等，每个设备标记是否是耳机和是否是当前输出
- `setAudioOutputToHeadphones()` 通过激活音频会话和设置首选输入来强制路由音频到耳机
- 最低 iOS 版本: 13.0

## 权限

### Android
在你的 `android/app/src/main/AndroidManifest.xml` 中添加：

```xml
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<!-- 如果你需要在 Android 12+ (API 31+) 上获得更准确的蓝牙检测结果（解决华为等部分设备检测不到的问题），建议添加以下权限： -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

注意：`BLUETOOTH_CONNECT` 是运行时权限，你需要在代码中动态申请。如果未授予该权限，插件将回退到标准检测方法。

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

