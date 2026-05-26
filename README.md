# humanize-trae-template

将 [PolyArch/humanize](https://github.com/PolyArch/humanize) 的 RLCR（Ralph-Loop with Codex Review）方法论移植到 [Trae](https://trae.ai) 编辑器的脚手架模板。

## 是什么

humanize 原本是 Claude Code 插件，依赖 marketplace / commands / hooks 等专属协议。本仓库把其中**可移植的方法论部分**封装成 Trae 的 Skill 资产 + 项目脚手架，使你能在任意新项目里一键启用同一套工作流。

## 三层架构

```
全局层（用户机器一次性安装）：~/.trae/skills/humanize-*/
  ├── humanize-gen-plan/        — 把 idea 转成 plan.md
  ├── humanize-rlcr-implement/  — 按 RLCR 实施 + 独立审查 + 迭代
  └── humanize-shared/          — 共享模板与脚本

模板仓（本仓库）：humanize-trae-template/
  ├── install-global.sh         — 全局 skill 安装器
  ├── init.sh                   — 在新项目里初始化 .humanize/
  ├── skills/                   — 全局 skill 源
  ├── shared/                   — 共享资产源（templates、scripts）
  └── presets/{generic,python,nodejs,go}/  — 按语言的 .gitignore 等

项目层（每个新项目）：<your-project>/.humanize/
  ├── config.json               — 项目级配置（preset、轮次上限等）
  ├── ideas/                    — humanize-gen-idea 产物
  └── rlcr/round-N/             — humanize-rlcr-implement 产物
```

## 快速开始

### 1) 一次性：全局安装 skill

```bash
git clone git@github.com:<your-user>/humanize-trae-template.git
cd humanize-trae-template
bash install-global.sh
```

完成后 `~/.trae/skills/` 下出现 `humanize-gen-plan/`、`humanize-rlcr-implement/`、`humanize-shared/`。重启 Trae 即可在对话中触发。

### 2) 每个新项目：初始化工作区

```bash
cd /path/to/new-project
bash /path/to/humanize-trae-template/init.sh . python   # preset 可选 generic/python/nodejs/go
```

完成后项目根目录出现 `.humanize/`、`docs/plan.template.md` 以及对应 preset 的辅助文件。

### 3) 在 Trae 对话中

```
用 humanize-gen-plan 把 .humanize/ideas/foo.md 转成 docs/plan.md
用 humanize-rlcr-implement 跑 docs/plan.md
```

外部终端实时监控：

```bash
source ~/.trae/skills/humanize-shared/scripts/humanize.sh
humanize monitor rlcr
```

## 与 PolyArch/humanize 的对应

| humanize（Claude Code） | 本模板 | 备注 |
|---|---|---|
| `commands/gen-plan.md` | `skills/humanize-gen-plan/SKILL.md` | 改写为 Trae Skill frontmatter |
| `commands/rlcr-implement.md` | `skills/humanize-rlcr-implement/SKILL.md` | 同上 |
| `marketplace.json` | 无 | Trae 不需要 |
| `hooks/` | 无 | Trae 用 Skill 触发条件代替 |
| `scripts/humanize.sh` | `shared/scripts/humanize.sh` | 直接复用 |
| `templates/plan.md` | `shared/templates/plan.md` | 直接复用 |

## License

MIT
