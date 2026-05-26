---
name: humanize-gen-plan
description: 将一段需求/想法（idea 文档或一句话）转换为 docs/plan.md，包含 Goal、Acceptance Criteria（可机测）、Architecture、Step-by-Step Plan、Risks/Open Questions。仅在用户显式说"生成 plan / 写一份 plan / humanize-gen-plan"时触发。
---

# humanize-gen-plan

## 何时使用
- 用户已有一份 idea / 需求 / brainstorm 文档（可能在 `.humanize/ideas/*.md`），希望沉淀为可执行的 plan。
- 用户给出一句话目标，要求你产出 plan.md。
- 不要在简单问答、bug 修复、单文件编辑场景触发。

## 输入
- `--input <path>`：可选，idea/需求文档路径。
- `--output <path>`：可选，默认 `docs/plan.md`。
- 若两者都缺失，从最近一条用户消息提取目标。

## 输出契约
生成的 plan.md 必须包含以下章节：

```markdown
# <Plan Title>

## Goal
<一段话，为什么做、做成什么样>

## Acceptance Criteria
- AC1: <可执行/可机测的判定>
- AC2: ...
- AC3: ...
- AC4: ...

## Architecture
<模块划分、关键数据流，必要时附 ASCII/mermaid 图>

## Step-by-Step Plan
1. <步骤，颗粒度：一个 PR 可完成>
2. ...

## Risks / Open Questions
- <已知风险或待澄清项>
```

## 强约束
- AC 必须是"可机测"的：能转成命令/断言。禁止"代码质量良好"这类模糊项。
- AC 数量 ≥ 3，不要硬凑。
- 不要在 plan.md 里写代码实现，只描述边界与契约。
- 如果输入信息不足以填满任一章节，**先用 AskUserQuestion 澄清**，不要编。

## 与其它 skill 的衔接
- 上游：`humanize-gen-idea`（产出 idea）、`brainstorming`。
- 下游：`humanize-refine-plan`（精化）、`humanize-rlcr-implement`（实施）。

## 完成后
告诉用户 plan.md 路径，并提示下一步：
> 下一步可以运行 `humanize-rlcr-implement docs/plan.md` 进入 Ralph-Loop with Codex Review 实施环节。
