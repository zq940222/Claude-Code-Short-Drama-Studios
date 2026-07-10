# 短剧工作台（Short Drama Studio）

这是一个 AI 短剧创作工作台。通过 9 个影视专业 agent 和分阶段 slash 命令，完成从创意到粗剪交付的全流程；最终精剪（配乐混音、字幕、调色）在剪映/PR 中完成。

## 创作流水线

```
/new-drama 建项 → /script 剧本 →【门禁① 剧本定稿】→ /storyboard 分镜 → /design 设定图
→【门禁② 设定图定稿】→ /shoot 视频生成 →【门禁③ 积分报价确认】→ /review 审片 → /edit 粗剪交付
                                    /music 配乐（剧本定稿后即可并行，Suno 生成 BGM）
```

- 三个门禁必须得到用户明确确认才能通过，其余阶段自动推进。
- `/studio-status` 随时查看所有项目进度和即梦积分余额。
- 用户可以随时单独调用某个 agent 做局部修改（如"让编剧改第 3 集台词"），不必走完整流水线。

## Agent 团队（.claude/agents/）

| Agent | 角色 | 职责 |
|---|---|---|
| producer | 制片人 | 建项、进度跟踪、积分预算、门禁把关 |
| screenwriter | 编剧 | 大纲、人物小传、分集剧本、台词 |
| director | 导演 | 分镜表：景别、运镜、时长、节奏 |
| art-director | 美术指导 | 角色/场景设定图（Gemini 网页端），视觉一致性 |
| cinematographer | 摄影指导 | 分镜 → Seedance 2.0 提示词 → shotlist.json |
| video-generator | 视频生成师 | 按 shotlist 调 dreamina CLI 生成、轮询、下载 |
| composer | 配乐师 | Suno 网页端生成 BGM + 对位说明 |
| editor | 剪辑师 | ffmpeg 统一编码、粗剪拼接（保留原声）、精剪交付包 |
| reviewer | 审片人 | 抽帧质检、一致性检查、回炉清单 |

## 生成引擎分工（按任务类型）

- **设定图**（角色三视图、场景概念图）→ Gemini 网页端 Nano Banana（`agent-browser` 浏览器自动化，省即梦积分）；不可用时降级 `dreamina text2image` 并告知用户
- **视频片段** → 即梦 `dreamina` CLI（Seedance 2.0 家族），**生成的视频自带声音（台词/音效），全流程必须保留音轨**：
  - 纯场景空镜 → `text2video`
  - 含角色镜头 → `multimodal2video`（引用角色设定图保证一致性，image≤9）
  - 精确控制首尾画面 → `frames2video`
- **背景音乐** → Suno 网页端（`agent-browser` 浏览器自动化）；BGM 是精剪素材，不混入粗剪
- **文生文**（剧本/分镜/提示词）→ Claude 本体
- Seedance 提示词写作规范见 `seedance-prompt-en` 技能

## 项目目录规范

```
projects/<剧名>/
├── project.json           # 项目档案：画幅、时长、集数、各阶段状态
├── 01-script/             # outline.md, characters.md, ep01.md ...
├── 02-storyboard/         # ep01-storyboard.md ...
├── 03-design/             # characters/<角色>-*.png, scenes/<场景>-*.png, style-bible.md
├── 04-footage/ep01/       # shotlist.json + sh01.mp4 ... + bgm/（Suno BGM + bgm-notes.md 对位说明）
└── 05-final/              # <剧名>-ep01-粗剪.mp4 + delivery-ep01.md（精剪交付包清单）
```

- 镜头命名：`ep{两位集号}` / `sh{两位镜号}`，如 `04-footage/ep01/sh03.mp4`
- `project.json.status` 各阶段取值：`pending | in_progress | approved | done`
- `shotlist.json` 是摄影指导与视频生成师之间的交接件，也是生成日志（记录 submit_id、状态、产物路径），生成过程中必须实时更新

## 硬性安全规则

1. **未经门禁③确认，绝不提交任何消耗积分的视频生成任务。**
2. 每次提交生成任务后立即把 submit_id 写入 shotlist.json，防止任务丢失。
3. 生成失败自动重试仅 1 次，再失败停下报告，不得无限重试烧积分。
4. `/shoot` 前必须 `dreamina user_credit` 检查余额；首次生成后记录实际消耗，校准后续报价（积分单价不得凭空假设）。
5. 遇到 `AigcComplianceConfirmationRequired` 错误：停下，提示用户去即梦 Web 端完成内容安全授权后重试。

## 交付边界

- 工作台交付：**粗剪预览**（顺序硬切拼接，保留即梦原声，无字幕）+ 原始镜头 + Suno BGM + 台词本
- 精剪在剪映/PR 完成：配乐混音、字幕、转场、调色

## 环境

- `dreamina` CLI 已登录（OAuth 设备流），`dreamina <子命令> -h` 查参数
- Gemini 网页端（设定图）与 Suno 网页端（BGM）需要浏览器已登录对应账号
- `ffmpeg` 8.x 在 PATH 中；拼接用 `tools/concat.ps1`
- Windows + PowerShell 环境，路径注意反斜杠与空格引号
