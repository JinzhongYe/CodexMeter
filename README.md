# CodexMeter

[English](#english) | [简体中文](#简体中文)

## English

A lightweight macOS menu bar app that shows the remaining weekly Codex CLI
quota at a glance.

> CodexMeter is an unofficial community project and is not affiliated with or
> endorsed by OpenAI.

## Features

- Shows the remaining quota directly in the menu bar, for example `Codex 40%`
- Supports a custom menu bar label, or a percentage-only display
- Opens a compact detail window with the weekly quota and reset time
- Shows the total locally recorded token usage and a seven-day bar chart
- Uses native Liquid Glass on macOS 26+ with a translucent compatibility style on macOS 15–25
- Includes a custom macOS app icon designed around a usage gauge and token bars
- Refreshes automatically every five minutes and supports manual refresh
- Works with Homebrew, npm, and common standalone Codex CLI locations
- Uses Swift, SwiftUI, MVVM, and no third-party libraries
- Requires no API key and does not store Codex credentials

## Requirements

- macOS 15 or later
- Xcode 16 or later for Xcode development, or Apple Command Line Tools for the
  command-line build
- Codex CLI installed and signed in

Run `codex` once in Terminal and complete the normal ChatGPT sign-in before
starting CodexMeter.

## Build and run

### Xcode

1. Open `CodexMeter.xcodeproj`.
2. Select the `CodexMeter` scheme and `My Mac`.
3. Press `Command-R`.
4. Click the quota text in the menu bar to open the detail window.

The app is an `LSUIElement`, so it does not appear in the Dock. App Sandbox is
disabled because CodexMeter needs to launch the local `codex` executable.

### Command line

```sh
./Scripts/build-app.sh
open build/CodexMeter.app
```

This creates an ad-hoc signed app at `build/CodexMeter.app`. The executable is
built for the current Mac architecture.

## Tests

Run dependency-free parser tests with Apple Command Line Tools:

```sh
./Scripts/test.sh
```

With a complete Xcode installation, run the Xcode unit tests:

```sh
xcodebuild -project CodexMeter.xcodeproj -scheme CodexMeter test
```

An optional smoke test queries the currently signed-in Codex account:

```sh
./Scripts/smoke-usage.sh
```

The smoke test reads the current quota but does not print or store credentials.

## How it works

CodexMeter first launches the local `codex app-server` and requests
`account/rateLimits/read`. It chooses the longest returned rate-limit window as
the weekly quota. For older or incompatible CLI versions, it falls back to
parsing the `Weekly limit` and `Reset` text produced by `codex /usage`.

The app adds common Homebrew and system directories to the child process
`PATH`. This is needed because macOS menu bar apps do not inherit the user's
interactive shell environment.

No separate analytics service, backend, or third-party dependency is used.
Token totals and the seven-day trend are calculated locally from `token_count`
events in `~/.codex/sessions`; conversation content is never uploaded or shown.

## Project structure

```text
Sources/CodexMeter/
├── Models/       Usage data and errors
├── Services/     Codex process integration and parsers
├── ViewModels/   Refresh state and scheduling
└── Views/        SwiftUI menu bar detail window

Tests/
├── CodexMeterTests/  Xcode unit tests
└── CLI/              Command-line test runners
```

The original bilingual V1 specification is available in
[`Docs/PROJECT_SPEC.md`](Docs/PROJECT_SPEC.md).
The latest implementation handoff is in
[`Docs/OPTIMIZATION_LOG.md`](Docs/OPTIMIZATION_LOG.md).

## Contributing

Contributions are welcome. See [`CONTRIBUTING.md`](CONTRIBUTING.md) and
[`SECURITY.md`](SECURITY.md) before opening an issue or pull request.

## License

CodexMeter is available under the [MIT License](LICENSE).

---

## 简体中文

一个轻量的 macOS 菜单栏应用，让你随时查看 Codex CLI 周额度剩余情况。

> CodexMeter 是非官方社区项目，与 OpenAI 无隶属关系，也未获得 OpenAI
> 官方背书。

### 功能

- 在菜单栏直接显示剩余额度，例如 `Codex 40%`
- 支持自定义菜单栏文字，也可以只显示百分比
- 点击菜单栏文字，显示周额度和重置时间详情
- 显示本机已记录的 Token 消耗总数与近 7 天柱状趋势
- macOS 26 及以上使用原生 Liquid Glass，macOS 15–25 使用通透兼容样式
- 配备以用量仪表盘和 Token 柱为主题的自定义 macOS 应用图标
- 每 5 分钟自动刷新，并支持手动刷新
- 支持通过 Homebrew、npm 和常见独立安装方式安装的 Codex CLI
- 使用 Swift、SwiftUI 和 MVVM，不依赖第三方库
- 不需要 API Key，也不会存储 Codex 登录凭据

### 环境要求

- macOS 15 或更高版本
- 使用 Xcode 开发时需要 Xcode 16 或更高版本；命令行构建也可以只安装
  Apple Command Line Tools
- 已安装并登录 Codex CLI

启动 CodexMeter 前，请先在终端运行一次 `codex`，并完成正常的 ChatGPT
登录流程。

### 构建和运行

#### 使用 Xcode

1. 打开 `CodexMeter.xcodeproj`。
2. 选择 `CodexMeter` scheme 和 `My Mac`。
3. 按 `Command-R`。
4. 点击菜单栏中的额度文字，打开详情窗口。

应用使用 `LSUIElement`，因此不会显示在 Dock 中。由于需要启动本机的
`codex` 可执行文件，工程关闭了 App Sandbox。

#### 使用命令行

```sh
./Scripts/build-app.sh
open build/CodexMeter.app
```

脚本会在 `build/CodexMeter.app` 生成使用本机 ad-hoc 签名的应用。可执行文件
将针对当前 Mac 的处理器架构构建。

### 测试

仅安装 Apple Command Line Tools 时，可以运行无第三方依赖的解析测试：

```sh
./Scripts/test.sh
```

安装完整 Xcode 后，可以运行 Xcode 单元测试：

```sh
xcodebuild -project CodexMeter.xcodeproj -scheme CodexMeter test
```

下面的可选冒烟测试会查询当前已登录的 Codex 账户：

```sh
./Scripts/smoke-usage.sh
```

冒烟测试会读取当前额度，但不会打印或存储登录凭据。

### 工作原理

CodexMeter 首先启动本机 `codex app-server`，并请求
`account/rateLimits/read`。应用会选择返回结果中时长最长的额度窗口作为周
额度。对于较旧或不兼容的 CLI 版本，应用会回退到解析 `codex /usage`
输出中的 `Weekly limit` 和 `Reset` 文本。

应用会为子进程的 `PATH` 补充常见的 Homebrew 和系统目录，因为 macOS
菜单栏应用不会继承用户的交互式 shell 环境。

项目不使用独立分析服务、后端或第三方依赖。
Token 总数和近 7 天趋势在本机从 `~/.codex/sessions` 内的
`token_count` 事件计算，不会上传或展示对话内容。

### 项目结构

```text
Sources/CodexMeter/
├── Models/       用量数据和错误定义
├── Services/     Codex 进程调用与解析器
├── ViewModels/   刷新状态和定时任务
└── Views/        SwiftUI 菜单栏详情窗口

Tests/
├── CodexMeterTests/  Xcode 单元测试
└── CLI/              命令行测试运行器
```

原始 V1 双语需求说明位于
[`Docs/PROJECT_SPEC.md`](Docs/PROJECT_SPEC.md)。
最新的实现交接记录位于
[`Docs/OPTIMIZATION_LOG.md`](Docs/OPTIMIZATION_LOG.md)。

### 参与贡献

欢迎参与贡献。提交 Issue 或 Pull Request 前，请阅读
[`CONTRIBUTING.md`](CONTRIBUTING.md)和[`SECURITY.md`](SECURITY.md)。

### 许可证

CodexMeter 使用 [MIT License](LICENSE) 开源。
