# 短剧工作台（Short Drama Studio）设计文档

日期：2026-07-10
状态：已确认

## 目标

在 Claude Code 中搭建一个短剧创作工作台：通过预设的影视专业 agent 团队和分阶段 slash 命令，
完成从创意到成片的全流程——剧本 → 分镜 → 角色/场景设定 → 视频生成 → 质检 → 剪辑成片。

## 决策记录

| 决策点 | 结论 |
|---|---|
| 交付范围 | 成片级：完整短剧集（ffmpeg 拼接，配音配乐留给专业软件） |
| 引擎分工 | 按任务类型：设定图走 Gemini 网页端 Nano Banana（省即梦积分），视频走即梦 Seedance |
| Agent 团队 | 全室 8 人：制片人、编剧、导演、美术指导、摄影指导、视频生成师、剪辑师、审片人 |
| 流程推进 | 阶段门禁：剧本定稿①、设定图定稿②、视频生成前积分确认③ 三处人工确认，其余自动 |
| 默认规格 | 不设默认，建项时选画幅（9:16 / 16:9）与时长 |
| 架构 | Claude Code 原生扩展（agents + skills + CLAUDE.md + 目录规范），仅附带 ffmpeg 拼接脚本 |

## 环境依赖

- `dreamina` CLI（即梦官方 AIGC CLI）：已登录，OAuth 设备流；生成消耗积分
- Gemini 网页端：通过 `agent-browser` 浏览器自动化操作 gemini.google.com（图像生成）
- `ffmpeg` 8.x：本地剪辑合成
- `seedance-prompt-en` 技能：Seedance 2.0 提示词专业指南

## 目录结构

```
CLAUDE.md                        # 工作台总规范
.claude/agents/                  # 8 个专业 subagent
.claude/skills/                  # 8 个阶段 slash 命令
tools/concat.ps1                 # ffmpeg 拼接脚本
projects/<剧名>/
├── project.json                 # 项目档案与阶段状态
├── 01-script/                   # 大纲、人物小传、分集剧本
├── 02-storyboard/               # 分镜表
├── 03-design/                   # 角色/场景设定图
├── 04-footage/ep{NN}/           # 镜头片段 + shotlist.json（生成任务清单兼日志）
└── 05-final/                    # 成片
```

## Agent 团队

| Agent | 职责 | 核心工具 |
|---|---|---|
| producer 制片人 | 建项、进度、积分预算、阶段门禁把关、调度 | project.json、`dreamina user_credit` |
| screenwriter 编剧 | 大纲、人物小传、分集剧本、台词；短剧节奏法则 | 文生文 |
| director 导演 | 剧本→分镜表：镜号/景别/运镜/时长/画面/台词/情绪 | 文生文 |
| art-director 美术指导 | 角色三视图、场景设定图；全剧视觉一致性圣经 | agent-browser → Gemini 网页端；降级 `dreamina text2image` |
| cinematographer 摄影指导 | 分镜→Seedance 2.0 提示词与 shotlist.json | seedance-prompt-en 技能 |
| video-generator 视频生成师 | 按 shotlist 提交/轮询/下载/重试，更新状态 | `dreamina` 各视频子命令 |
| editor 剪辑师 | 统一编码、排序拼接、输出成片 | ffmpeg、tools/concat.ps1 |
| reviewer 审片人 | 抽帧质检：瑕疵、一致性、连贯性；出回炉清单 | ffmpeg 抽帧 + 视觉判断 |

## 关键接口

**project.json**：`title / format{ratio, episode_duration_sec, episodes} / genre / status{script, storyboard, design, footage, final}`，
状态值 `pending | in_progress | approved | done`。

**shotlist.json**（摄影指导 → 视频生成师的交接件，兼生成日志）：每镜头
`id / mode(text2video|image2video|multimodal2video|frames2video) / prompt / images[] / duration / model / status / submit_id / file`。

## 引擎路由规则

- 纯场景空镜 → `text2video`
- 含角色镜头 → `multimodal2video`（@引用角色设定图，image≤9）
- 精确首尾画面 → `frames2video`
- 设定图 → Gemini 网页端；网页端不可用时降级 `dreamina text2image` 并告知用户

## 流水线与门禁

```
/new-drama → /script →【① 剧本定稿】→ /storyboard → /design →【② 设定图定稿】
→ /shoot →【③ 积分报价确认】→ 生成/轮询/下载 → /review（不合格回炉）→ /edit → 成片
/studio-status 随时查看进度与积分
```

## 错误处理

- 生成任务异步：submit_id 记入 shotlist.json，`query_result` 轮询；失败自动重试 1 次，再失败列入报告
- 积分：`/shoot` 前查 `user_credit`；首次生成后用实际消耗校准单价预估（不硬编码价格）
- `AigcComplianceConfirmationRequired`：提示用户去即梦 Web 端完成授权后重试
- Gemini 登录态失效：降级即梦 text2image 并提示

## 测试/验收

- 建项 → 各命令可独立触发对应 agent
- 用一个 2-3 镜头的迷你项目跑通全流程（消耗少量积分）验证
