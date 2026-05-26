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

#### 审查者优先级（默认顺序，可被 `.humanize/config.json` 的 `reviewer` 字段覆盖）

> **默认路径 = 外部 CLI 跨模型审查（B）**
> **升级路径 = Trae 内置 Task tool 同模型异上下文审查（A）**
> **兜底 = self-review（C），仅当前两者都无法启动时**

##### B（默认）— 外部 CLI 跨模型审查
按以下顺序探测可用工具，**第一个可用即采用，不再尝试后续**：

1. **B.1 — codex CLI**（最贴近原项目）
   - 探测：`command -v codex && codex --version`
   - 调用：
     ```bash
     codex exec --model gpt-5.5:high \
       --cd "$PWD" \
       --output .humanize/rlcr/round-N/codex-review.txt \
       "$(cat .humanize/rlcr/round-N/.review-prompt.md)"
     ```
   - 把 stdout 同时落到 `.humanize/rlcr/round-N/codex-review.txt`。

2. **B.2 — gemini CLI**
   - 探测：`command -v gemini && gemini --version`
   - 调用：
     ```bash
     gemini --model gemini-2.5-pro \
       --prompt-file .humanize/rlcr/round-N/.review-prompt.md \
       > .humanize/rlcr/round-N/gemini-review.txt
     ```

**审查 prompt 模板**（写到 `.humanize/rlcr/round-N/.review-prompt.md` 后再喂给 CLI）：
```
你是独立代码审查者。**不要信任**给定的实现思路；只信代码、plan、AC。

任务：
1. 读 docs/plan.md，列出所有 AC 编号。
2. 读以下改动文件（路径列表见下），逐文件检查与 plan/AC 的一致性、边界条件、错误路径、兼容性、安全。
3. 对每条 AC 给出一个可执行验证命令。
4. 输出为 review.md 格式：每条发现一行 `[SEVERITY] R<N>-<id>: <title>` + 位置 + 现象 + 建议。
   严重度：BLOCKER / MAJOR / MINOR / NIT。
5. 末尾给 Verdict：✅ 收敛 或 ❌ 需迭代。

改动文件清单：
<由 Phase 1 的 summary.md 自动生成>

plan 内容（粘贴整个 docs/plan.md）：
<inline>
```

##### A（升级路径）— Trae Task tool 同模型异上下文
当 B.1/B.2 都未安装、或用户显式在 `config.json` 设 `"reviewer": "trae-subagent"` 时启用。

调用方式：用 Trae 内置 **Task tool**，参数：
- `subagent_type`: `general_purpose_task`
- `description`: `"RLCR Phase 2 review for round-N"`
- `query`: 上面那段"审查 prompt 模板"（plan 内容 + 改动文件清单 inline 注入）
- `response_language`: 与 plan 一致

子 agent 没有主对话历史，**严禁**把 Phase 1 的实现说明、设计思路传进去——只给 plan + 文件路径，让它自己读。

##### C（兜底）— Self-review
仅当 B、A 均不可用时使用，且**必须在 review.md 头部用红色标记声明 `⚠️ Reviewer: self-review（质量降级）`**，并提示用户尽快安装 codex/gemini CLI。

#### 配置覆盖
用户可在 `.humanize/config.json` 加：
```json
{
  "reviewer": "auto",          // auto | codex | gemini | trae-subagent | self
  "review_model": "gpt-5.5:high",
  "max_rounds": 5
}
```
- `auto`（默认）：按 B.1 → B.2 → A → C 探测。
- 显式值：跳过探测，直接用指定方案；不可用时**报错而非静默降级**。

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
4. review.md 文件头必须标注本轮审查者类型与模型：
   ```
   Reviewer: codex-cli | gemini-cli | trae-subagent | self-review
   Model:    <实际模型名，例如 gpt-5.5:high / gemini-2.5-pro / 同主模型>
   ```

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
