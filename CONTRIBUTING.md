# 贡献指南

感谢你对 Miru 的兴趣！本文说明如何参与开发与提交贡献。

> 本项目基于上游 [miru-app](https://github.com/miru-project/miru-app) 二次开发，遵循 **GPL-3.0** 协议。提交贡献即表示你同意以相同协议授权你的代码。

---

## 开始之前

- 先搜索已有的 [Issues](../../issues) 与 Pull Request，避免重复。
- **较大改动请先开 Issue 讨论**，确认方向后再动手，以免白做。
- 修复 Bug 时，尽量附上可复现步骤、平台、版本号与日志。

## 开发环境

- Flutter `>= 3.2`，Dart SDK `^3.13`
- 平台依赖：
  - Windows / Linux 需要 QuickJS 原生库（`quickjs_c_bridge.dll` / `libquickjs`）
  - Android 扩展图床常为明文 HTTP，已在 `AndroidManifest.xml` 开启 `usesCleartextTraffic`
  - 详见 [README](README.md) 的「支持的平台」

```bash
# 获取依赖
flutter pub get

# 运行（以 Windows 为例）
flutter run -d windows
```

## 分支与提交

- 从 `master` 切出功能分支，命名建议：`feat/xxx`、`fix/xxx`、`docs/xxx`。
- 提交信息用**中文祈使句**，主题简洁（尽量 ≤ 50 字），说明「做了什么」；需要时在正文分点写「为什么」。
  - 示例：`修复扩展安装/卸载并发与 JS 运行时释放竞态`
- 一个 PR 只做一件事，避免把无关改动混在一起。

## 代码风格

- 遵循 `flutter_lints`（见 `analysis_options.yaml`），提交前 **`flutter analyze` 必须 0 告警**。
- 缩进 2 空格；命名与目录遵循现有 `lib/features/*` 分层（`data` / `domain` / `presentation`）。
- 优先复用现有组件与工具（如 `AppConstants`、`openExternalUrl`、`showAppSnackBar`），保持风格一致。

## 测试

```bash
# 单元/组件测试（host 运行，无需设备）
flutter test

# 端到端扩展链路测试（需要真机/桌面设备 + 网络）
flutter test integration_test -d windows
```

- 新增或修改逻辑时，请补充对应测试；纯检测/解析逻辑应可在 host 上单测（可注入 `http.Client`）。
- 扩展链路测试会自动发现 `integration_test/fixtures/` 下的 `.js` 脚本，详见 README「运行与集成测试」。

## 扩展开发

扩展是可在 QuickJS 中执行的 JavaScript 脚本，需实现标准的**列表 / 搜索 / 详情 / 播放**接口，并带 `==MiruExtension==` 元数据头（`@package`、`@name`、`@webSite` 等）。契约细节见 README「扩展开发契约」与 `template.js`。

## 提交 Pull Request

1. 确保 `flutter analyze` 与 `flutter test` 通过。
2. PR 描述写清楚：**改了什么、为什么、如何验证**（附截图/日志更佳）。
3. 关联相关 Issue（如 `Closes #123`）。
4. 推送 tag 会触发 CI 自动构建各平台产物，正常 PR 无需自行打包。

---

## Contributing (English)

- Search existing issues/PRs first; **open an issue before large changes**.
- Branch off `master` (`feat/...`, `fix/...`); one concern per PR.
- Commit messages are written in Chinese, imperative and concise.
- Follow `flutter_lints`; **`flutter analyze` must be clean** and `flutter test` must pass before submitting.
- This project is licensed under **GPL-3.0** — by contributing you agree to license your work under the same terms.
