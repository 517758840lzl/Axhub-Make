# 贷款计算器 · Flutter（iOS / Android）

与 Make 原型 `src/prototypes/loan-calculator` 及 PRD `src/resources/prd/prd-01-loan-calculator.md` 对齐的 **原生壳**，Revolut 浅色视觉与四 Tab 流程一致。

## 平台

- **仅 iOS、Android**（`flutter create --platforms=ios,android`；`main.dart` 会拒绝 Web/桌面）
- 无 Web 目录

## 运行

```bash
cd loan_calculator_flutter
flutter pub get
flutter devices          # 确认有 Android / iOS 设备
flutter run -d <deviceId>
```

### 一直卡在 `Launching lib/main.dart…`

常见原因是 **Gradle 首次下载**失败（SSL / 网络），Debug Console 里可能只有一行黄字、没有后续日志。

1. 在终端执行（能看到完整报错）：
   ```bash
   cd loan_calculator_flutter
   flutter run -v
   ```
2. 本项目已在 `android/` 配置 **Gradle 腾讯云 + Maven 阿里云** 镜像；改完后建议：
   ```bash
   flutter clean && flutter pub get && flutter run
   ```
3. 用 **Android Studio** 打开 `loan_calculator_flutter/android` 做一次 Gradle Sync。
4. Cursor/VS Code 请 **打开文件夹** `loan_calculator_flutter`（不是 `loan-calculator-html`），选底部设备为 **sdk gphone64 arm64** 或真机，不要用 Chrome/Web。
5. Problems 里若只有 `use_null_aware_elements` 的 **info**，不会阻止运行；若是红色 **error**，把完整文案发出来。

## 数据

- 本地 `shared_preferences`，键前缀 `loan-calc:`（与浏览器原型 schema 一致，便于对照）
- 导出 JSON 通过系统分享面板

## 结构

| 目录 | 说明 |
|------|------|
| `lib/data/` | 模型、计算、货币、标签、存储 |
| `lib/state/app_state.dart` | 状态与路由 |
| `lib/widgets/` | 与原型 CSS 对应的 UI 组件 |
| `lib/screens/loan_screens.dart` | 全部页面 |

## 品牌

- **桌面图标**：`assets/branding/app_icon.png`（紫蓝渐变 fintech 风格）；`dart run flutter_launcher_icons` 可重新生成 Android/iOS 图标
- **启动页**：原生闪屏底色 `#F4F4F8` + Flutter **启动动画**（环形 Logo 生长、弹性缩放、标语淡入，约 1.6～2.2s 后进入主界面）

## 说明

Flutter 与 Web 原型在字体渲染、Lucide 图标版本上可能有 **亚像素级** 差异；布局尺寸、色值、文案与交互路径按原型实现。若需像素级截图对比，请在同一设备宽度（430pt）下验收。
