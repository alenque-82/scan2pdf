# Doc Scanner - 功能类似万能扫描王

## 功能

- ✅ 拍照扫描文件
- ✅ 手动裁边确认（v1）
- ✅ 自动边缘检测 + 透视矫正（v2）
- ✅ 4种滤镜：原始/增强/黑白/灰度
- ✅ 多页扫描
- ✅ 导出 PDF / 图片
- ✅ 本地历史记录（SQLite）
- ✅ 分享到微信、邮件、网盘等

## 技术栈

| 模块 | 技术 |
|------|------|
| 拍照 | `camera` (CameraX) |
| 边缘检测 | `image` (v1手动/v2接入OpenCV) |
| PDF导出 | `pdf` + `printing` |
| 本地存储 | `sqflite` |
| 状态管理 | `provider` |
| 分享 | `share_plus` |

## 快速开始

### 1. 创建项目（在自己机器上）

```bash
flutter create --org com.scanapp --project-name doc_scanner doc_scanner
cd doc_scanner
```

### 2. 替换文件

把本目录的 `lib/` 和 `android/` 覆盖过去，再把 `pubspec.yaml` 复制进去。

### 3. 安装依赖

```bash
flutter pub get
```

### 4. 运行

```bash
flutter run
```

## 开发路线

### v1（当前）
- 拍照 → 手动确认 → 滤镜 → 多页 → PDF导出 → 分享

### v2（计划）
- [ ] 自动边缘检测（OpenCV）
- [ ] 透视矫正
- [ ] OCR文字识别（ML Kit）
- [ ] 云端备份
- [ ] 文件夹管理

## 目录结构

```
lib/
├── main.dart
├── models/
│   └── scan_document.dart
├── providers/
│   └── scan_provider.dart
├── screens/
│   ├── home_screen.dart
│   ├── camera_screen.dart
│   ├── edit_screen.dart
│   └── history_screen.dart
└── services/
    ├── database_service.dart
    ├── image_processor.dart
    └── pdf_service.dart
```

## 构建 APK

```bash
flutter build apk --release
```

APK 输出在 `build/app/outputs/flutter-apk/`
