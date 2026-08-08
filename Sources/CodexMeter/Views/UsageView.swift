import AppKit
import SwiftUI

struct UsageView: View {
    @ObservedObject var viewModel: UsageViewModel
    @AppStorage("menuBarPrefix") private var menuBarPrefix = "Codex"

    var body: some View {
        VStack(spacing: 16) {
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

            Divider()
            footer
        }
        .padding(18)
        .frame(width: 330)
        .background(.regularMaterial)
        .onAppear { viewModel.start() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "gauge.with.dots.needle.50percent")
                .font(.title2)
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text("CodexMeter")
                    .font(.headline)
                Text("Codex CLI 用量")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await viewModel.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
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
        VStack(spacing: 14) {
            VStack(spacing: 5) {
                Text("\(usage.weeklyRemainingPercentage)%")
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
                Text("当前额度剩余")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(usage.weeklyRemainingPercentage), total: 100)
                .tint(progressColor(for: usage.weeklyRemainingPercentage))

            VStack(spacing: 10) {
                detailRow(title: "周额度剩余", value: "\(usage.weeklyRemainingPercentage)%", icon: "calendar")
                detailRow(title: "重置时间", value: resetText(for: usage), icon: "clock.arrow.circlepath")
            }

            Text("更新于 \(usage.fetchedAt.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("正在读取 Codex 用量…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
    }

    private var emptyContent: some View {
        ContentUnavailableView(
            "暂无用量数据",
            systemImage: "chart.bar.xaxis",
            description: Text("点击刷新以读取 Codex CLI 用量")
        )
        .frame(minHeight: 150)
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
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
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
}
