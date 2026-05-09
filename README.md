# Doc Scanner

一个离线优先的 Flutter 扫描器，目标体验接近「万能扫描王」。

## 已实现

- 拍照扫描文件
- 手动裁边确认
- 4 种滤镜：原始 / 增强 / 黑白 / 灰度
- 多页扫描
- 导出 PDF
- 本地历史记录（SQLite）
- 分享 PDF 或图片

## 技术栈

- Flutter + Material 3
- `camera`
- `image`
- `pdf` + `printing`
- `sqflite`
- `provider`
- `share_plus`
- `permission_handler`
- `file_picker`

## 运行方式

> 当前仓库已经包含 Flutter 代码和 Android 配置。
> 如果你本地还没有 Flutter 项目，可以先执行一次 `flutter create .` 或者新建项目后把这些文件覆盖进去。

```bash
flutter pub get
flutter run
```

## 构建 APK

```bash
flutter build apk --release
```

输出：

```bash
build/app/outputs/flutter-apk/app-release.apk
```

## iOS

如果你也要 iOS 工程，先在本仓库根目录执行：

```bash
flutter create .
```

然后再运行：

```bash
flutter pub get
flutter run
```

## 当前代码结构

```text
lib/
├── main.dart
├── models/scan_document.dart
├── providers/scan_provider.dart
├── screens/
│   ├── home_screen.dart
│   ├── camera_screen.dart
│   ├── crop_screen.dart
│   ├── edit_screen.dart
│   └── history_screen.dart
└── services/
    ├── database_service.dart
    ├── image_processor.dart
    └── pdf_service.dart
```

## 下一步

- V2：自动识别纸张边缘
- V2：透视矫正
- V2：OCR
- V2：更强的历史管理和文件夹分类
