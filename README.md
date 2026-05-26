# humanize-trae-template

> 将 [PolyArch/humanize](https://github.com/PolyArch/humanize) 的 **RLCR**（Ralph-Loop with Codex Review）方法论移植到 [Trae](https://trae.ai) 编辑器的脚手架模板。

[![GitHub](https://img.shields.io/badge/github-stupidyhc33%2Fhumanize--trae--template-blue?logo=github)](https://github.com/stupidyhc33/humanize-trae-template)

---

## 目录

- [是什么](#是什么)
- [三层架构](#三层架构)
- [安装](#安装)
- [用法](#用法)
  - [1. 在新项目里启用工作流](#1-在新项目里启用工作流)
  - [2. 在 Trae 对话中触发](#2-在-trae-对话中触发)
  - [3. 外部终端实时监控](#3-外部终端实时监控)
- [完整端到端示例](#完整端到端示例)
- [目录结构](#目录结构)
- [配置项](#配置项)
- [升级与卸载](#升级与卸载)
- [与-polyarchhumanize-的对应](#与-polyarchhumanize-的对应)
- [常见问题](#常见问题)
- [License](#license)

---

## 是什么

humanize 原本是 Claude Code 插件，依赖 marketplace / commands / hooks 等专属协议。本仓库把其中**可移植的方法论部分**封装成 Trae 的 Skill 资产 + 项目脚手架，使你能在任意新项目里一键启用同一套工作流：

> idea → plan → 实现 → 独立审查 → 迭代直至收敛

## 三层架构

```
┌─────────────────────────────────────────────────────────────┐
│ 全局层（用户机器一次性安装）：~/.trae/skills/                │
│   humanize-gen-plan/        idea → docs/plan.md             │
│   humanize-rlcr-implement/  按 RLCR 实施 + 独立审查 + 迭代  │
│   humanize-shared/          共享模板 (plan.md) + 监控脚本    │
└─────────────────────────────────────────────────────────────┘
              ▲ install-global.sh 一次性同步
              │
┌─────────────────────────────────────────────────────────────┐
│ 模板仓（本仓库）：humanize-trae-template/                    │
│   install-global.sh   全局 skill 安装器                      │
│   init.sh             在新项目里初始化 .humanize/            │
│   skills/             humanize-gen-plan, humanize-rlcr-...   │
│   shared/             templates/ + scripts/                  │
│   presets/            generic | python | nodejs | go         │
└─────────────────────────────────────────────────────────────┘
              ▲ init.sh <new-project> <preset> 拉起
              │
┌─────────────────────────────────────────────────────────────┐
│ 项目层（每个新项目）：<your-project>/                        │
│   .humanize/config.json     项目级配置                       │
│   .humanize/ideas/*.md      brainstorming 产物              │
│   .humanize/rlcr/round-N/   每轮 summary.md + review.md      │
│   docs/plan.template.md     plan 模板（按需重命名为 plan.md）│
└─────────────────────────────────────────────────────────────┘
```

---

## 安装

**前置条件**：macOS / Linux，已安装 `git`、`bash`，以及 [Trae 编辑器](https://trae.ai)（海外版或 CN 版均可）。

```bash
# 1. 克隆模板仓
git clone https://github.com/stupidyhc33/humanize-trae-template.git
cd humanize-trae-template

# 2. 一次性把 humanize-* skill 装到全局
bash install-global.sh
```

脚本会**自动探测** skill 目录：

| 优先级 | 目录 | 适用 |
|---|---|---|
| 1 | `$TRAE_SKILLS_DIR`（环境变量） | 自定义 |
| 2 | `~/.trae-cn/skills/` | Trae CN 国内版 |
| 3 | `~/.trae/skills/` | Trae 海外版 |

成功示例输出：

```
📍 检测到 Trae skill 目录：/Users/<you>/.trae-cn/skills
✅ 全局 Humanize Skill 已安装至 /Users/<you>/.trae-cn/skills
   - skills: humanize-gen-plan humanize-rlcr-implement
   - shared: /Users/<you>/.trae-cn/skills/humanize-shared
```

**重启 Trae 编辑器**，让它重新加载 skill 目录，之后即可在对话中触发。

> 💡 自定义路径：`TRAE_SKILLS_DIR=/your/path bash install-global.sh`

---

## 用法

### 1. 在新项目里启用工作流

```bash
cd /path/to/your-new-project

# 用法：init.sh <project_dir> <preset>
# preset 可选：generic | python | nodejs | go
bash /path/to/humanize-trae-template/init.sh . python
```

执行后项目根目录出现：

```
your-new-project/
├── .humanize/
│   ├── config.json          # {"preset":"python","max_rounds":5,...}
│   ├── ideas/               # 放 idea/需求笔记
│   ├── rlcr/                # RLCR 每轮产物
│   └── README.md            # 工作流速查
├── docs/
│   └── plan.template.md     # plan 模板
└── .gitignore               # python preset 自带
```

> 💡 **小技巧**：如果你想让 `init.sh` 全局可调用，加一行别名：
> ```bash
> echo "alias humanize-init='bash $HOME/path/to/humanize-trae-template/init.sh'" >> ~/.zshrc
> ```
> 之后任意目录下 `humanize-init . python` 即可。

### 2. 在 Trae 对话中触发

打开 Trae，进入项目根目录的对话窗口，**用自然语言显式调用 skill 名**：

```text
请用 humanize-gen-plan 把 .humanize/ideas/foo.md 转成 docs/plan.md
```

Skill 会按契约产出含 Goal / Acceptance Criteria / Architecture / Step-by-Step Plan / Risks 的 plan.md。

确认 plan 后，启动 RLCR 实施：

```text
用 humanize-rlcr-implement 跑 docs/plan.md
```

它会按以下阶段循环，直到收敛或达到 `max_rounds`：

| 阶段 | 动作 | 产物 |
|---|---|---|
| Phase 0 | 检查 git 干净度、读取 plan、建 round-N 目录 | — |
| Phase 1 | 实现 plan 中的 Step-by-Step | `round-N/summary.md` |
| Phase 2 | 独立视角审查 + 跑通每条 AC | `round-N/review.md` |
| Phase 3 | 决策：收敛 / 进入 round-N+1 | review.md 末尾 Verdict |

### 3. 外部终端实时监控

在另一个终端：

```bash
source ~/.trae/skills/humanize-shared/scripts/humanize.sh
humanize monitor rlcr   # 每 3 秒刷新最近 4 个 summary/review
humanize status         # 查看本项目 .humanize/config.json
humanize help
```

---

## 完整端到端示例

```bash
# ── 准备 ─────────────────────────────────────────────
git clone https://github.com/stupidyhc33/humanize-trae-template.git ~/code/humanize-trae-template
bash ~/code/humanize-trae-template/install-global.sh

mkdir -p ~/code/my-cli && cd ~/code/my-cli
git init
bash ~/code/humanize-trae-template/init.sh . python

# ── 写一个 idea ──────────────────────────────────────
cat > .humanize/ideas/greet.md <<'EOF'
做一个 greet.py 命令行工具：输入名字，输出双语问候。
EOF
```

打开 Trae（cwd 指向 `~/code/my-cli`），在对话里依次说：

```text
1) 用 humanize-gen-plan --input .humanize/ideas/greet.md 生成 docs/plan.md
2) 用 humanize-rlcr-implement docs/plan.md 跑一轮 RLCR
```

期望产物：

```
my-cli/
├── docs/plan.md
├── greet.py
└── .humanize/rlcr/
    ├── round-1/{summary.md,review.md}   # 若发现 BLOCKER 进入下一轮
    └── round-2/{summary.md,review.md}   # ✅ 收敛（2 轮）
```

> 上面这个例子在本仓库的 commit 历史里跑通过：发现 PEP 604 联合类型 `list[str] | None` 在旧 Python 不兼容（BLOCKER R1-001），第 2 轮加 `from __future__ import annotations` 收敛。

---

## 目录结构

```
humanize-trae-template/
├── README.md
├── install-global.sh        # 同步 skills/ 与 shared/ 到 ~/.trae/skills/
├── init.sh                  # 项目级初始化器
├── skills/
│   ├── humanize-gen-plan/SKILL.md
│   └── humanize-rlcr-implement/SKILL.md
├── shared/
│   ├── templates/plan.md    # plan 文档模板
│   └── scripts/humanize.sh  # monitor / status CLI
├── presets/
│   ├── generic/             # 占位
│   ├── python/.gitignore
│   ├── nodejs/.gitignore
│   └── go/.gitignore
└── .trae/skills/            # 17 个通用工程方法论 skill（与 humanize 解耦）
```

---

## 配置项

`init.sh` 生成的 `.humanize/config.json`：

```json
{
  "preset": "python",
  "review_model": "gpt-5.5",
  "alternative_plan_language": "zh-CN",
  "max_rounds": 5
}
```

| 字段 | 含义 | 默认 |
|---|---|---|
| `preset` | 语言/框架预设，影响 init 时拷哪些资产 | `generic` |
| `review_model` | RLCR Phase 2 审查阶段使用的模型标记（提示用） | `gpt-5.5` |
| `alternative_plan_language` | 写作语言偏好 | `zh-CN` |
| `max_rounds` | 单次 RLCR 最大轮次 | `5` |

---

## 升级与卸载

```bash
# 升级：在模板仓拉新 + 重跑 install-global.sh
cd ~/code/humanize-trae-template
git pull
bash install-global.sh

# 卸载全局 skill
rm -rf ~/.trae/skills/humanize-gen-plan \
       ~/.trae/skills/humanize-rlcr-implement \
       ~/.trae/skills/humanize-shared

# 卸载项目工作区
rm -rf .humanize docs/plan.template.md
```

---

## 与 PolyArch/humanize 的对应

| humanize（Claude Code） | 本模板 | 备注 |
|---|---|---|
| `skills/humanize-gen-plan` | `skills/humanize-gen-plan` | ✅ 已移植，改写为 Trae Skill frontmatter |
| `skills/humanize-refine-plan` | `skills/humanize-refine-plan` | ✅ 已移植，剥离 Claude 专属 hooks，保留 CMT/QA 核心契约 |
| `skills/humanize-rlcr` | `skills/humanize-rlcr-implement` | ✅ 已移植，合并了 `commands/start-rlcr-loop` |
| `skills/humanize` | — | 入口引导，Trae 用 SKILL frontmatter 描述代替 |
| `skills/ask-codex` | 内嵌于 `humanize-rlcr-implement` Phase 2 方案 B | 仅在本机装了 `codex` CLI 时启用 |
| `skills/ask-gemini` | — | 暂未移植，可在 Phase 2 加方案 D |
| `commands/*.md` | — | Trae 不需要 slash 命令，靠 Skill description 触发 |
| `agents/*.md` | 由 Trae 内置 `Task tool` + `subagent_type` 替代 | 无需移植 |
| `hooks/` | — | Trae 用 Skill description 中的"触发条件"代替 |
| `scripts/humanize.sh` | `shared/scripts/humanize.sh` | 直接复用 |
| `templates/plan.md` | `shared/templates/plan.md` | 直接复用 |

## 独立审查（RLCR 的灵魂）

> ⚠️ **请认真读这一节。** RLCR 的核心是"实现者 ≠ 审查者"，否则就退化成了 self-review。

| 审查方案 | 异构模型 | 上下文隔离 | 启用条件 | 何时使用 |
|---|---|---|---|---|
| **B（首选）** Codex CLI | ✅ Codex GPT-5.5 vs Trae | ✅ 跨进程 | 本机装 `codex` 并 `codex auth login` | 想最贴近原项目 |
| **A（默认回退）** Trae Task tool 子 agent | ❌ 同模型 | ✅ 全新上下文 | 零依赖 | 大多数场景 |
| **C（降级）** Self-review | ❌ | ❌ | 前两者都不可用 | 不推荐，仅做兜底 |

`humanize-rlcr-implement` 在 Phase 2 会自动按 B → A → C 的优先级选择审查者，并在 `review.md` 头部标注 `Reviewer: codex-cli | trae-subagent | self-review`。

---

## 常见问题

**Q1：装完重启 Trae，对话里触发不了 skill。**
- 先确认你装的是 CN 版还是海外版：CN 版目录是 `~/.trae-cn/skills/`，海外版是 `~/.trae/skills/`，本脚本已自动探测。
- 检查对应目录下 `humanize-rlcr-implement/SKILL.md` 是否存在，且 frontmatter `name`、`description` 完整。
- Trae 是按 description 语义匹配的，建议在指令里**显式带上 skill 名**触发。

**Q2：`init.sh` 提示"全局共享资产缺失"。**
说明你跳过了第一步。它会自动尝试调 `install-global.sh` 修复，如失败请检查 `~/.trae/` 是否有写权限。

**Q3：RLCR 第一阶段就报 "not a git repo"。**
RLCR 强约束工作区是干净的 git 仓库。在项目目录先 `git init && git add . && git commit -m "baseline"`。

**Q4：能在 Windows 上用吗？**
脚本是 bash，建议 WSL2 或 Git Bash。原生 PowerShell 暂不支持。

**Q5：如何只更新某一个 skill 而不动其它？**
直接编辑 `skills/<name>/SKILL.md`，再跑 `bash install-global.sh`（它整目录覆盖，不会删别的 skill 目录）。

---

## License

MIT
