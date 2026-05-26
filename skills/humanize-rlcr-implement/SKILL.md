---
name: humanize-rlcr-implement
description: 按 RLCR（Ralph-Loop with Codex Review）方法论执行 docs/plan.md：实现 → 独立审查 → 迭代直到收敛。每一轮产物落到 .humanize/rlcr/round-N/{summary.md,review.md}。仅在用户显式说"跑 RLCR / humanize-rlcr-implement"时触发。
---

# humanize-rlcr-implement

## 触发条件
- 用户给出 plan 路径（默认 `docs/plan.md`）并要求按 RLCR 实施。
- 不要主动用于普通编码请求。

## 工作流（必须严格分阶段）

### Phase 0 — Preflight
1. 检查 `git status`：必须工作区干净；若不是 git 仓库或有未提交改动，**先报告偏差**，由用户决定是否仍继续（演练场景可跳过，生产场景必须修复）。
2. 读取 `docs/plan.md`，提取所有 AC 编号。
3. 创建 `.humanize/rlcr/round-1/`。

### Phase 1 — Implementation（每轮）
1. 按 plan 的 Step-by-Step 顺序实现，**只动 plan 列出的文件**。
2. 写 `.humanize/rlcr/round-N/summary.md`：
   - Changed files（含行数）
   - 实现要点
   - 自测计划（每条 AC 对应一个可执行命令）

### Phase 2 — Independent Review（每轮）
**关键：以独立审查者视角，不复用本轮实现的假设。**

#### 审查者选择（按优先级）
1. **方案 B（首选，若可用）**：本机装有 `codex` CLI 时，调用
   ```bash
   codex exec --model gpt-5.5:high "<review prompt>"
   ```
   把结果落到 `.humanize/rlcr/round-N/codex-review.txt`。这等价于原项目的 `ask-codex.sh`。
2. **方案 A（默认回退）**：用 Trae 内置 **Task tool**，`subagent_type=general_purpose_task` 派一个**全新上下文**的子 agent 做审查。子 agent 没有主对话历史，只能看到你显式传入的 plan + 改动文件清单，从而获得最大化的"独立性"。**禁止复用本轮 Phase 1 的对话上下文做审查。**
3. **降级方案 C**：若以上都不可用（极少见），明确告知用户当前是"自审模式 / self-review"，质量会下降。

#### 审查流程（无论用哪种审查者）
1. 对每条 AC 实际跑一次命令，记录 stdout/stderr 与判定。
2. 读源码寻找：
   - 与 plan/AC 不一致的地方
   - 边界条件、错误路径
   - 安全 / 资源 / 兼容性问题
3. 写 `.humanize/rlcr/round-N/review.md`，每个发现按以下格式：
   ```
   [SEVERITY] R<N>-<id>: <title>
   位置: path:line
   现象: ...
   建议: ...
   ```
   严重度：`BLOCKER` / `MAJOR` / `MINOR` / `NIT`。
4. review.md 文件头必须标注本轮审查者类型：`Reviewer: codex-cli | trae-subagent | self-review`。

### Phase 3 — Decision
- 无 BLOCKER / MAJOR 且全部 AC 通过 → **收敛，结束**。
- 否则 → Round N+1，回 Phase 1。
- 达到 `.humanize/config.json` 的 `max_rounds`（默认 5）仍未收敛 → 停下，向用户报告。

## 强约束
- **每轮都要写 summary.md 和 review.md**，不能合并到一个文件。
- review.md 必须有"实测命令 + 实际输出"，不能只写"应该可行"。
- 不要在 review 阶段顺手修代码——发现问题写进 review，下一轮再改。

## 产物结构
```
.humanize/rlcr/
├── round-1/
│   ├── summary.md
│   └── review.md
├── round-2/
│   ├── summary.md
│   └── review.md
└── ...
```

## 收尾
最后一轮 review.md 末尾追加 `## Verdict\n✅ 收敛（共 N 轮）` 或 `❌ 未收敛`。
