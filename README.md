# miru

[English](README.en.md) | **中文**

一个基于 Flutter 的跨平台影视聚合播放器。通过加载 JavaScript 扩展脚本，解析第三方影视站的列表、详情与播放源，并提供本地收藏、播放器与多主题界面。

## 功能特性

- **扩展机制**：以 JavaScript 脚本为插件，运行时通过 QuickJS 解析，支持列表 / 搜索 / 详情 / 播放四个阶段的数据提取
- **收藏夹**：本地收藏你的影视条目（基于 `shared_preferences` 持久化）
- **内置播放器**：基于 `media_kit`（libmpv/MSVPw 后端），支持进度记忆与进度条拖动
- **搜索**：展示各扩展的搜索结果
- **设置页**：管理已安装扩展、浏览扩展仓库、安装本地扩展

## 支持的平台

| 平台 | 支持 | 说明 |
| --- | --- | --- |
| Windows | ✅ | 已验证（QuickJS 原生桥 `quickjs_c_bridge.dll`） |
| macOS | ✅ | 通过 |
| Linux | ✅ | 需要 QuickJS 原生库 |
| Android | ✅ | 扩展图床多为明文 HTTP，需在 `AndroidManifest.xml` 开启 `usesCleartextTraffic` |
| iOS | ⚠️ | 可通过 `--no-codesign` 构建，正式分发需 Apple 签名 |

> **Web 不支持**：扩展运行时依赖 QuickJS 原生 FFI（`flutter_js`），纯 Web 环境无法运行，故已移除 Web 平台。

## 快速开始

```bash
# 1. 安装 Flutter（>= 3.2，Dart SDK ^3.13）
# 2. 获取依赖
flutter pub get

# 3. 运行（以 Windows 为例）
flutter run -d windows

# 4. 构建发布包
flutter build windows --release        # Windows
flutter build apk --release            # Android
flutter build macos --release          # macOS
flutter build linux --release          # Linux
flutter build ios --release --no-codesign  # iOS（未签名）
```

## 发布到 GitHub

仓库已配置 GitHub Actions 流水线（`.github/workflows/release.yml`）。打 tag 后自动为全平台构建并上传到 GitHub Release：

```bash
git tag v0.0.5
git push main v0.0.5
```

每个平台作业产出：

- Windows：`miru-windows-x64.zip`
- Android：`miru-android.apk`
- macOS：`miru-macos.zip`
- Linux：`miru-linux-x64.tar.gz`
- iOS：`miru-ios.zip`（未签名）

在 GitHub 仓库的 **Actions** 页面可查看构建日志，**Releases** 页面可下载产物。

## 运行与集成测试

### 运行应用

```bash
flutter run -d windows   # 或其他已启用平台
```

### 通用扩展链路测试工具

测试会自动发现 `integration_test/fixtures/` 目录下的所有 `.js` 扩展脚本，逐个跑完整链路：**latest → detail → watch → MediaDetailService 契约转换**，并在开始前自动删除已缓存的扩展、结束后清理，保证从干净状态开始。

```bash
# 一键测试全部 fixtures（Windows 桌面设备）
flutter test integration_test -d windows
```

#### 使用方法说明

1. **放脚本**：把要测试的扩展脚本复制到 `integration_test/fixtures/` 下，文件名随意（如 `my_site.js`），脚本头部需带 `==MiruExtension==` 元数据注释（`@package`、`@name`、`@webSite` 等）。
2. **跑测试**：执行上面的命令，自动发现并逐个测试所有 `.js` 文件。
3. **看结果**：每个扩展会打印 `[通过] 包名 (名称)` 或失败明细；任一步（列表为空、详情无剧集、播放地址为空、契约字段缺失）都会给出具体失败行。
4. **契约校验**：每条链路对样本（默认前 5 部）做详情转换断言：episodes 非空、首个分集有播放链接、演员名非空；`director / area / writer / pubdate` 只要样本中任一部命中即通过，全部缺失时仅打印提示（契约允许空）。

底层工具在 `integration_test/extension_test_tool.dart`：
- `runExtensionPipeline(...)`：单扩展全链路测试入口（清缓存 → runtime 直连 → 管理器契约转换 → 清理）；
- `discoverExtensionFixtures(...)`：扫描 fixtures 目录；
- `ExtensionTestReport`：结果与失败明细。

> 注意：QuickJS 多引擎在同一个 isolate 内并发会触发 `JSValue released`，因此所有 fixture 在单个 `test()` 内**严格顺序**执行，每个引擎用完即弃并留沉降时间；新增 fixture 时无需修改任何测试代码。

> 提示：测试需要联网抓取真实扩展数据；若走了代理或扩展站点不可达会导致失败，通常不是脚本本身问题（图床/站点图片不显示多为代理未关，见下文 FAQ）。

## 扩展开发契约

扩展是一个可在 QuickJS 中执行的 JavaScript 脚本（示例：`assets/js/` 或 `integration_test/fixtures/360zy.com.js`）。脚本导出标准的列表 / 搜索 / 详情 / 播放接口，核心契约如下：

- **列表 / 搜索**：返回可提取的条目数组（标题、封面、链接）
- **Detail**：可解析 `type`、`director`、`writer`、`area`、`lang`、`year`、`pubdate`、`remarks`、`total`、`score`、`actors`、简介与分集列表
- **播放**：返回播放源链接，由内置播放器渲染

脚本可通过以下任一方式加载：

- 扩展仓库（在线安装，见 `extension_repo_service.dart`）
- 本地安装（`install_extension_screen.dart`）

> 字段名与解析细节以 `template.js` 及 `extension_models.dart` 中定义的契约为准。

## 项目结构

```
lib/
├── app/
│   ├── app.dart               # 应用入口与路由
│   └── theme/app_theme.dart   # 主题（deepPurple seed）
├── core/
│   └── constants/             # 全局常量
└── features/
    ├── extension/             # 扩展：运行时、管理器、仓库、安装与详情页
    ├── home/                  # 首页（推荐列表 + 我的收藏）
    ├── search/                # 搜索
    ├── media_detail/          # 详情页与详情数据解析
    ├── player/                # 播放器
    ├── favorite/              # 收藏数据服务
    ├── settings/              # 设置
    └── main_navigation/       # 底部主导航
assets/
├── js/                        # 内置扩展脚本与加密工具（md5 / CryptoJS / jsencrypt）
└── icon/                      # 应用图标
android/ ios/ linux/ macos/ windows/   # 各平台工程
integration_test/              # 端到端集成测试
```

## 常见问题

- **图片不显示**：多为本地代理未关闭；另外扩展图床常为明文 HTTP（带端口），Android 9+ 默认禁止明文流量，需在 `AndroidManifest.xml` 的 `application` 上开启 `android:usesCleartextTraffic="true"`。
- **Android 构建报 Kotlin target 校验错误**：`android/gradle.properties` 需保留 `kotlin.jvm.target.validation.mode=warning`。
- **iOS 包无法直接安装**：CI 产出为未签名 `.ipa` 对应的源码包，正式分发请接入签名证书。