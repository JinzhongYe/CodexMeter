import AppKit
import Charts
import SwiftUI

struct UsageView: View {
    @ObservedObject var viewModel: UsageViewModel
    @AppStorage("menuBarPrefix") private var menuBarPrefix = "Codex"

    var body: some View {
        liquidGlassContent
            .padding(18)
            .frame(width: 390)
            .background {
                LinearGradient(
                    colors: [
                        .blue.opacity(0.055),
                        .clear,
                        .purple.opacity(0.035)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            .containerBackground(.clear, for: .window)
            .onAppear { viewModel.start() }
    }

    @ViewBuilder
    private var liquidGlassContent: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: 12) {
                content
            }
        } else {
            content
        }
    }

    private var content: some View {
        VStack(spacing: 14) {
            header

            if let usage = viewModel.usage {
                usageContent(usage)
            } else if viewModel.isLoading {
                loadingContent
            } else {
                emptyContent
            }

            if let errorMessage = viewModel.errorMessage {
                errorContent(errorMessage)
            }

            menuBarTextSetting
            footer
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "gauge.with.dots.needle.50percent")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 34, height: 34)
                .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 2) {
                Text("CodexMeter")
                    .font(.headline)
                Text("Codex CLI 用量概览")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await viewModel.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 28, height: 28)
                    .liquidGlassControl()
                    .rotationEffect(viewModel.isLoading ? .degrees(360) : .zero)
                    .animation(
                        viewModel.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                        value: viewModel.isLoading
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
            .help("立即刷新")
        }
    }

    private func usageContent(_ usage: UsageSnapshot) -> some View {
        VStack(spacing: 12) {
            quotaPanel(usage)

            if let tokenUsage = usage.tokenUsage {
                tokenUsagePanel(tokenUsage)
            } else {
                tokenUsageUnavailablePanel
            }
        }
    }

    private func quotaPanel(_ usage: UsageSnapshot) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("当前额度剩余")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(usage.weeklyRemainingPercentage)%")
                        .font(.system(size: 38, weight: .semibold, design: .rounded))
                        .contentTransition(.numericText())
                }
                Spacer()
                Image(systemName: "chart.pie.fill")
                    .font(.title2)
                    .foregroundStyle(progressColor(for: usage.weeklyRemainingPercentage))
            }

            ProgressView(value: Double(usage.weeklyRemainingPercentage), total: 100)
                .tint(progressColor(for: usage.weeklyRemainingPercentage))

            Divider().opacity(0.6)

            VStack(spacing: 9) {
                detailRow(title: "周额度剩余", value: "\(usage.weeklyRemainingPercentage)%", icon: "calendar")
                detailRow(title: "重置时间", value: resetText(for: usage), icon: "clock.arrow.circlepath")
            }

            Text("更新于 \(usage.fetchedAt.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .glassPanel()
    }

    private func tokenUsagePanel(_ summary: TokenUsageSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("累计消耗 Token")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(summary.totalTokens.formatted(.number.grouping(.automatic)))
                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                Spacer()
                Text("本机记录")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .liquidGlassBadge()
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("近 7 天消耗趋势")
                    .font(.subheadline.weight(.medium))

                Chart(summary.dailyUsage) { item in
                    BarMark(
                        x: .value("日期", item.date, unit: .day),
                        y: .value("Token", item.tokenCount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.85), .purple.opacity(0.65)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(4)
                    .annotation(position: .top, spacing: 2) {
                        if item.tokenCount > 0 {
                            Text(abbreviatedTokenCount(item.tokenCount))
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                            .foregroundStyle(.secondary)
                        AxisTick().foregroundStyle(.secondary.opacity(0.35))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                        AxisGridLine().foregroundStyle(.secondary.opacity(0.16))
                        AxisValueLabel {
                            if let tokenCount = value.as(Int64.self) {
                                Text(abbreviatedTokenCount(tokenCount))
                            }
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 118)
                .accessibilityLabel("近 7 天 Token 消耗柱状图")
            }

            Text("统计自 \(summary.sourceFileCount) 个本机会话记录")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .glassPanel()
    }

    private var tokenUsageUnavailablePanel: some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("暂无 Token 消耗记录")
                    .font(.subheadline.weight(.medium))
                Text("未找到 ~/.codex/sessions 中的本机会话日志")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .glassPanel()
    }

    private var loadingContent: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("正在读取 Codex 用量…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .glassPanel()
    }

    private var emptyContent: some View {
        ContentUnavailableView(
            "暂无用量数据",
            systemImage: "chart.bar.xaxis",
            description: Text("点击刷新以读取 Codex CLI 用量")
        )
        .frame(minHeight: 150)
        .glassPanel()
    }

    private func errorContent(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.orange.opacity(0.15), lineWidth: 0.5)
        }
    }

    private var menuBarTextSetting: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("菜单栏文字")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("例如 Codex", text: $menuBarPrefix)
                .textFieldStyle(.roundedBorder)
            Text("额度数字会自动显示在文字后面；留空则只显示数字。")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .glassPanel()
    }

    private var footer: some View {
        HStack {
            Text("每 5 分钟自动刷新")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 2)
    }

    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func resetText(for usage: UsageSnapshot) -> String {
        if let resetAt = usage.resetAt {
            return resetAt.formatted(date: .abbreviated, time: .shortened)
        }
        return usage.resetDescription ?? "未知"
    }

    private func progressColor(for remaining: Int) -> Color {
        switch remaining {
        case 50...: return .green
        case 20..<50: return .orange
        default: return .red
        }
    }

    private func abbreviatedTokenCount(_ value: Int64) -> String {
        switch value {
        case 1_000_000...:
            return String(format: "%.1fM", Double(value) / 1_000_000)
        case 1_000...:
            return String(format: "%.0fK", Double(value) / 1_000)
        default:
            return "\(value)"
        }
    }
}

private extension View {
    @ViewBuilder
    func glassPanel() -> some View {
        if #available(macOS 26.0, *) {
            padding(13)
                .glassEffect(
                    .clear.tint(.white.opacity(0.025)).interactive(),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        } else {
            padding(13)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 0.55)
                }
        }
    }

    @ViewBuilder
    func liquidGlassControl() -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(.clear.interactive(), in: Circle())
        } else {
            background(.primary.opacity(0.045), in: Circle())
        }
    }

    @ViewBuilder
    func liquidGlassBadge() -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(.clear.tint(.blue.opacity(0.035)), in: Capsule())
        } else {
            background(.primary.opacity(0.045), in: Capsule())
        }
    }
}
