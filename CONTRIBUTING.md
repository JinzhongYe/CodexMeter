# Contributing to CodexMeter

[English](#english) | [简体中文](#简体中文)

## English

Thanks for helping improve CodexMeter.

## Development setup

You need macOS 15 or later, Xcode 16 or later, and an installed Codex CLI. The
app has no third-party dependencies.

1. Fork and clone the repository.
2. Create a focused branch from `main`.
3. Open `CodexMeter.xcodeproj`, or build with Swift Package Manager.
4. Make the smallest change that solves the problem.
5. Run the checks below before opening a pull request.

```sh
swift build
./Scripts/test.sh
```

For changes to the CLI integration, also run this optional test while signed
in to Codex:

```sh
./Scripts/smoke-usage.sh
```

## Pull requests

- Explain the user-visible behavior and why the change is needed.
- Add or update parser tests when changing usage parsing.
- Keep the app dependency-free unless a dependency has a compelling benefit.
- Do not commit credentials, Codex account data, build products, or Xcode user
  settings.

By contributing, you agree that your contribution will be licensed under the
MIT License.

---

## 简体中文

感谢你帮助改进 CodexMeter。

### 开发环境

你需要 macOS 15 或更高版本、Xcode 16 或更高版本，以及已安装的 Codex
CLI。应用不使用第三方依赖。

1. Fork 并克隆仓库。
2. 从 `main` 创建一个目标明确的分支。
3. 打开 `CodexMeter.xcodeproj`，或使用 Swift Package Manager 构建。
4. 使用尽可能小的改动解决问题。
5. 打开 Pull Request 前运行以下检查。

```sh
swift build
./Scripts/test.sh
```

如果修改了 CLI 集成，请在已经登录 Codex 的环境中额外运行以下可选测试：

```sh
./Scripts/smoke-usage.sh
```

### Pull Request

- 说明用户可见的行为，以及为什么需要这项改动。
- 修改用量解析逻辑时，请添加或更新解析测试。
- 除非依赖有明确且必要的收益，否则请保持应用无第三方依赖。
- 不要提交凭据、Codex 账户数据、构建产物或 Xcode 用户设置。

提交贡献即表示你同意使用 MIT License 许可你的贡献。
