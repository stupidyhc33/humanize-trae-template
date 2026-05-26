---
name: humanize-refine-plan
description: 精化一份带评论标注的 plan：将形如 CMT:...ENDCMT 的评论块按"问题/变更请求/调研请求"分类，逐条解决后产出无评论的 refined plan 与 QA 账本。仅在用户显式说"精化 plan / refine plan / humanize-refine-plan"时触发。
---

# humanize-refine-plan

## 何时使用
- 用户对 `docs/plan.md` 进行了批注（在原文里插入 `CMT: ... ENDCMT` 块），希望把这些批注消化掉，得到一份"可以直接喂给 humanize-rlcr-implement"的干净 plan。
- 不要在生成 plan 阶段触发——那是 `humanize-gen-plan` 的职责。
- 不要在没有 CMT 块的纯 plan 上触发——直接进入 RLCR 即可。

## 输入
- `--input <path>`：必填，带 CMT 标注的 plan 路径，默认 `docs/plan.md`。
- `--output <path>`：可选，refined plan 输出路径；不传则**原地覆盖**。
- `--qa-dir <dir>`：可选，QA 账本目录，默认 `.humanize/plan_qa/`。
- `--mode discussion|direct`：可选，遇到模糊批注的处理策略：
  - `discussion`（默认）：用 AskUserQuestion 向用户确认。
  - `direct`：以"最小安全假设"自行决断，并在 QA 账本里如实记录。

## 评论块语法
精化器只处理形如下面的块，其它内容原样保留：

```
CMT: <批注内容，可多行>
ENDCMT
```

## 工作流

### Phase 0 — Preflight
1. 读取 `--input` 文件；若不存在或无 `CMT:` 块 → 立即报告并停下。
2. 用状态机扫描提取所有 CMT 块，编号 `CMT-1`、`CMT-2`、… 记录每块的：
   - 行号范围
   - 所在 plan 章节（最近的 `## ` 标题）
   - 原始正文

### Phase 1 — 分类
对每个 CMT 块判定**唯一主分类**，可选值：

| 分类 | 含义 | 处理方式 |
|---|---|---|
| `question` | 用户在问"为什么 / 是不是" | 用代码/上下文给出答案，写进 QA |
| `change_request` | 用户要求改 plan | 直接改 plan 对应位置 |
| `research_request` | 用户要求调研外部信息 | 用 WebSearch / SearchCodebase 等做最小调研 |

模糊时按 `--mode` 决定问用户还是自行决断。

### Phase 2 — 处理
按 CMT 编号顺序逐条处理：
1. **question**：在 QA 账本写答案；plan 文件中删除该 CMT 块。
2. **change_request**：在 plan 文件相应位置应用变更；删除 CMT 块；QA 账本记录"已应用"。
3. **research_request**：调研后把结论以**新条目**追加到 plan（一般加到 `## Risks / Open Questions` 或对应 step），删除 CMT 块；QA 账本记录调研要点与来源。

### Phase 3 — 一致性校验
完成所有 CMT 处理后再扫一遍 plan：
1. 不允许残留任何 `CMT:`/`ENDCMT` 标记。
2. 章节顺序与 `humanize-gen-plan` 契约保持一致：
   - `## Goal`
   - `## Acceptance Criteria`
   - `## Architecture`
   - `## Step-by-Step Plan`
   - `## Risks / Open Questions`
3. AC 编号连续、无重复。
4. Step-by-Step 引用的文件 / 模块名在文档其它地方有对应描述。

不通过 → 修复一次；仍不通过 → 报告 BLOCKING，停下。

### Phase 4 — 写出
1. 把 refined plan 原子写入 `--output`（默认覆盖原文件）。
2. 把 QA 账本写到 `<qa-dir>/refine-<YYYYMMDD-HHMMSS>.md`：

```markdown
# Plan Refinement QA — <timestamp>
- Source: <input path>
- Output: <output path>
- Mode: discussion|direct
- CMT blocks processed: N

## CMT-1 [classification]
**位置**: line X, 章节 `## ...`
**原文**:
> <CMT 原文>

**处理**: <answer / applied change / research finding>
**变更摘要**: <若改了 plan，简述改动>
**遗留决策**: <若有>

## CMT-2 ...
```

## 强约束
- **绝不**新增 plan 顶层章节；只在已有章节内增删改。
- **绝不**修改 AC 文本以外的"语义"——若 CMT 要求改 AC，必须先在 QA 中确认。
- 若 CMT 内含子问题 / 多个独立诉求，先在 QA 中拆成 `CMT-N.a / CMT-N.b`，再分别处理。
- 模糊批注禁止"硬编"成 question——`--mode discussion` 下必须问用户。

## 完成后
告诉用户：
1. refined plan 路径
2. QA 账本路径
3. 处理了多少 CMT、各类分布
4. 是否仍存在 `## Risks / Open Questions` 中未关闭的项

并提示：

> 下一步可运行 `humanize-rlcr-implement <plan path>` 进入 RLCR 实施。
