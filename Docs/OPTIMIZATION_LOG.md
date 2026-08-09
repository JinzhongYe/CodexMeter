# CodexMeter 优化记录

更新日期：2026-08-09

补充更新：已生成并接入自定义 macOS 应用图标，并完成可运行 `.app` 的 Release 构建。

玻璃效果二次调整：在 macOS 26 及以上使用系统原生 `glassEffect(.clear)` 和
`GlassEffectContainer`，窗口容器改为透明背景；macOS 15–25 使用
`ultraThinMaterial` 兼容。减少了有色叠层、描边与阴影，让桌面内容更明显地透过窗口。

## 本次目标与完成情况

1. 菜单栏详情窗口改为玻璃质感：已完成。
2. 展示具体 Token 消耗趋势和 Token 总数：已完成。
3. 留下可供后续对话续接的实现记录：本文档。

## 用户可见变化

- 菜单栏详情宽度由 330 pt 调整为 390 pt，以容纳图表和更清晰的信息层级。
- 窗口使用 `ultraThinMaterial`、淡色渐变和 `thinMaterial` 卡片组成玻璃背景。
- 周额度、Token 用量和菜单栏设置拆分为独立玻璃卡片。
- 新增“累计消耗 Token”，显示带千位分隔符的精确总数。
- 新增“近 7 天消耗趋势”柱状图，柱顶显示缩写后的每日数值。
- 保留周额度百分比、进度条、重置时间、更新时间、手动/自动刷新和退出功能。
- 新增蓝色玻璃仪表盘应用图标；提供 1024 px PNG 源文件和多尺寸 ICNS 成品。

## 数据实现

- 新增 `TokenUsageScanner`，只读扫描 `~/.codex/sessions/**/*.jsonl`。
- 只解析 `event_msg` 中类型为 `token_count` 的记录，不读取或展示对话正文。
- 优先累计 `last_token_usage.total_tokens`，这是每次模型调用的 Token 增量。
- 兼容缺少 `last_token_usage` 的旧记录：使用相邻
  `total_token_usage.total_tokens` 的差值。
- 总数覆盖本机当前保留的所有会话日志；趋势按本地时区聚合最近 7 个自然日。
- 如果会话目录不存在或没有可解析的 Token 事件，界面显示“暂无 Token 消耗记录”；Token 统计失败不会影响原有额度读取。

## 主要改动文件

- `Sources/CodexMeter/Views/UsageView.swift`
  - 玻璃界面、累计 Token、Swift Charts 柱状图。
- `Sources/CodexMeter/Models/UsageSnapshot.swift`
  - 新增 `DailyTokenUsage`、`TokenUsageSummary` 以及快照中的 Token 数据。
- `Sources/CodexMeter/Services/TokenUsageScanner.swift`
  - 本机会话日志扫描与每日聚合。
- `Sources/CodexMeter/Services/CodexUsageService.swift`
  - 在额度读取成功后附加本地 Token 统计。
- `Tests/CLI/ParserTestRunner.swift`、`Scripts/test.sh`
  - 新增 Token 增量累计和跨日聚合测试。
- `CodexMeter.xcodeproj/project.pbxproj`
  - 将新服务文件加入 Xcode target。
- `README.md`
  - 补充新功能、数据来源和隐私说明。
- `Resources/AppIcon.png`、`Resources/AppIcon.icns`、`Resources/Info.plist`
  - 图标源文件、macOS 多尺寸图标和 Bundle 图标声明。
- `Scripts/build-app.sh`
  - 使用项目内模块缓存完成 Release 构建，并把图标复制进 `.app`。

## 验证记录

- `./Scripts/test.sh`：通过，6 项解析与用量测试。
- `swift build --disable-sandbox`：通过，macOS 15 target 编译成功。
- `plutil -lint CodexMeter.xcodeproj/project.pbxproj`：通过。
- `git diff --check`：通过。
- `./Scripts/build-app.sh`：通过，输出 `build/CodexMeter.app` 并完成 ad-hoc 签名。

## 已知边界

- Token 总数代表 `~/.codex/sessions` 中仍保留的本机 Codex 会话记录，不是服务端账单数字；日志被删除或迁移后，总数会相应变化。
- 图表固定显示最近 7 个自然日，当前没有日期范围切换控件。
- 每次五分钟刷新会重新扫描本机会话日志；若未来日志规模明显增大，可增加按文件修改时间缓存的增量索引。

## 下次对话建议

可以直接告诉 Codex：

> 请先阅读 `Docs/OPTIMIZATION_LOG.md`，在当前 Token 趋势功能基础上继续优化。先检查现有改动和测试，不要覆盖未提交的用户修改。

适合继续做的方向：图表悬停详情、7/30 天范围切换、输入/输出/缓存 Token 分类、增量扫描缓存、菜单栏直接显示今日 Token。
