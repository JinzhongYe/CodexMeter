# Security Policy

[English](#english) | [简体中文](#简体中文)

## English

## Reporting a vulnerability

Please do not open a public issue for a vulnerability that could expose Codex
credentials or local user data. Use GitHub's private vulnerability reporting
feature for this repository instead. Include reproduction steps, affected
versions, and the expected impact when possible.

CodexMeter never asks for an API key and does not store Codex authentication
tokens. It invokes the user's existing local Codex CLI process and reads the
rate-limit response from that process.

---

## 简体中文

### 报告安全漏洞

如果漏洞可能导致 Codex 凭据或本地用户数据泄露，请不要创建公开 Issue。
请使用本仓库的 GitHub 私密漏洞报告功能。请尽可能提供复现步骤、受影响版本
和预期影响。

CodexMeter 不会请求 API Key，也不会存储 Codex 身份验证令牌。应用只会调用
用户现有的本地 Codex CLI 进程，并从该进程读取额度响应。
