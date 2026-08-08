# Project: CodexMeter

[English](#english) | [简体中文](#简体中文)

## English

Build a macOS menu bar application for monitoring Codex CLI usage limits.

Technical requirements:

- Swift and SwiftUI
- macOS menu bar application
- macOS 15 or later
- Produce a runnable `.app`

V1 features:

1. Create a menu bar item.
2. Open a window when the item is clicked, showing:
   - Current Codex quota percentage
   - Weekly quota remaining
   - Reset time
3. Refresh automatically every five minutes.
4. Invoke the local `codex` command to retrieve usage information.

Attempt to run:

```sh
codex /usage
```

Parse output similar to:

```text
Weekly limit:
████████░░ 80% left

Reset:
xxxx
```

Display the parsed values in the UI.

Code requirements:

- Use MVVM architecture.
- Keep the code clear.
- Do not use third-party libraries.
- Create an Xcode project automatically.
- Provide run instructions.
- Test that the project compiles when complete.

---

## 简体中文

开发一个 macOS 菜单栏应用，用来监控 Codex CLI 使用额度。

技术要求：

- 使用 Swift 和 SwiftUI
- 类型为 macOS 菜单栏应用
- 支持 macOS 15 或更高版本
- 最终生成可运行的 `.app`

V1 功能：

1. 创建菜单栏项目。
2. 点击后显示窗口，包含：
   - Codex 当前额度百分比
   - 周额度剩余
   - 重置时间
3. 每 5 分钟自动刷新。
4. 调用本地 `codex` 命令获取用量信息。

尝试执行：

```sh
codex /usage
```

解析类似以下内容的输出：

```text
Weekly limit:
████████░░ 80% left

Reset:
xxxx
```

将解析结果显示到 UI。

代码要求：

- 使用 MVVM 架构。
- 保持代码清晰。
- 不使用第三方库。
- 自动创建 Xcode 工程。
- 提供运行步骤。
- 完成后测试编译。
