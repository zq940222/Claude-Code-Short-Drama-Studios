# Short Drama Studio（短剧工作台）

[中文](README.md) | **English**

![version](https://img.shields.io/badge/version-1.4.0-blue) ![platform](https://img.shields.io/badge/platform-Claude%20Code%20%7C%20Windows%20%7C%20macOS-lightgrey)

An AI studio for creating short vertical dramas end-to-end inside Claude Code: from a one-line idea to platform publishing — script → storyboard → character/scene design → video generation → music → QC review → rough cut → JianYing (CapCut CN) fine cut (auto-generated draft) → Douyin publishing.

Eleven film-industry agents collaborate through staged slash commands, with four human-confirmation gates built in (preventing accidental credit spending and accidental publishing).

> **Note**: This studio is built around the Chinese short-drama ecosystem — Jimeng/Dreamina (即梦) for video generation, JianYing (剪映, the Chinese CapCut) for editing, and Douyin (抖音) for publishing. A Dreamina account, JianYing desktop app, and Douyin creator account are required for the full pipeline.

## Installation (Claude Code plugin)

This repository is a standard Claude Code plugin with a self-hosted marketplace. Install from the command line in two steps:

```bash
claude plugin marketplace add zq940222/Claude-Code-Short-Drama-Studios
claude plugin install short-drama-studio@short-drama-studio
```

Or inside a Claude Code session:

```
/plugin marketplace add zq940222/Claude-Code-Short-Drama-Studios
/plugin install short-drama-studio@short-drama-studio
```

Restart your session after installing. The default scope is user-level (available in every directory); add `--scope project` to limit it to one project.

- **Update**: `claude plugin update short-drama-studio`
- **Uninstall**: `claude plugin uninstall short-drama-studio`
- **Pin a version**: `claude plugin marketplace add zq940222/Claude-Code-Short-Drama-Studios@v1.3.0`

After installing, run `/new-drama` in **any working directory**: the first run bootstraps the workspace (copies the studio conventions CLAUDE.md and helper scripts), then creates your project. With the plugin namespace the command is `/short-drama-studio:new-drama`; when there is no name clash, plain `/new-drama` works.

## Requirements

| Dependency | Purpose | How to verify |
|---|---|---|
| `dreamina` CLI | Official Jimeng/Dreamina AIGC CLI for video generation (Seedance 2.0) | `dreamina user_credit` returns a balance when logged in; otherwise run `dreamina login` |
| Google account (signed in via Chrome) | The art director drives the Gemini web app for design images (no Dreamina credits spent) | Browser can open gemini.google.com and chat |
| Suno account (signed in via browser) | The composer drives the Suno web app to generate background music | Browser can open suno.com/create and generate |
| JianYing (JianyingPro, Windows or macOS) | The fine-cut agent auto-generates JianYing drafts; 5.9 has the best draft compatibility, ≤6.8 supports auto-export (Windows only; export manually on macOS), newer versions encrypt drafts (limited support) | JianYing installed locally and can open drafts |
| Python 3.8+ with `pyJianYingDraft` | JianYing draft generation + cross-platform helper scripts (use `python` on Windows, `python3` on macOS) | `python -c "import pyJianYingDraft"` succeeds (`python -m pip install pyJianYingDraft`) |
| Douyin Creator Center (signed in via browser) | The operator agent publishes semi-automatically (user confirmation required before publishing) | Browser can open creator.douyin.com while logged in |
| `ffmpeg` / `ffprobe` | Local transcoding and concatenation (Windows: winget/scoop; macOS: `brew install ffmpeg`) | `ffmpeg -version` |
| `agent-browser` | Browser-automation CLI (used for Gemini design images / Suno music / Douyin publishing) | `agent-browser --help` |

> Some Dreamina video models may return `AigcComplianceConfirmationRequired` on first use — complete the one-time content-safety authorization on the Dreamina website, then retry.

## Quick Start

```
1. After installing the plugin, launch Claude Code in any working directory
2. /new-drama        # Bootstraps the workspace on first run, then creates the project: genre, aspect ratio, episode length, episode count
3. /script           # Script writing, iterate until satisfied → [Gate ① script approval]
4. /storyboard       # Break the script into a shot table (shot no. / framing / camera move / duration / action / dialogue)
5. /design           # Character turnarounds + scene concept art → [Gate ② design approval]
6. /shoot            # Credit estimate → [Gate ③ confirmation] → batch-generate video shots (Dreamina videos include sound)
7. /music            # Generate BGM with Suno (available once the script is approved; runs in parallel with 6/8)
8. /review           # Frame-by-frame QC; failed shots go back to /shoot for re-generation
9. /edit             # ffmpeg rough cut (original audio preserved) for a quick pacing preview
10. /finalcut        # Auto-generate a JianYing draft: transitions + BGM placement + dialogue subtitles + filters → fine-tune and export in JianYing
11. /publish         # Copywriting + cover → semi-automatic Douyin upload → [Gate ④ confirmation] → publish
```

Run `/studio-status` anytime to see project progress, credit balance, and to collect pending generation tasks.

**Tip**: For your first project, make a 2–3 shot mini episode to validate the pipeline and calibrate the credit cost per shot before committing to a full episode.

## Commands

| Command | Stage | Gate |
|---|---|---|
| `/new-drama` | Create a project with the standard layout and project.json | - |
| `/script` | Outline, character bios, episode scripts | ① Script approval |
| `/storyboard` | Shot table + duration accounting | - |
| `/design` | Character/scene design images (Gemini web first) | ② Design approval |
| `/shoot` | Prompts → credit quote → batch generation → download | ③ Quote confirmation (the only large credit spend) |
| `/music` | Suno BGM + placement notes | - |
| `/review` | Frame extraction QC, consistency checks, redo list | Redo passes Gate ③ again |
| `/edit` | Normalize, rough-cut concat (audio preserved), delivery package | - |
| `/finalcut` | Auto-generate JianYing draft via pyJianYingDraft (transitions/BGM/subtitles/filters) | - |
| `/publish` | Copy, cover image, semi-automatic publishing to Douyin etc. | ④ Pre-publish confirmation |
| `/studio-status` | All-project progress + credit overview | - |

## The Agent Team

| Agent | Role | Responsibilities |
|---|---|---|
| producer | Producer | Project setup, progress, credit budget, gatekeeping |
| screenwriter | Screenwriter | Outline, character bios, episode scripts (3-second hook, twist density, and other short-drama rules) |
| director | Director | Shot table: framing, camera moves, duration, pacing — mindful of AI-generation feasibility |
| art-director | Art Director | Design images and series-wide visual consistency (style bible) |
| cinematographer | Cinematographer | Storyboard → Seedance 2.0 prompts → shotlist.json |
| video-generator | Video Generator | Drives dreamina submit/poll/download/retry with real-time accounting |
| composer | Composer | Suno BGM + placement notes |
| editor | Editor | ffmpeg normalization, rough-cut concat (audio preserved), delivery package |
| finalcut | Fine-cut Editor | pyJianYingDraft JianYing drafts: transitions, BGM placement, subtitle track, filters |
| reviewer | Reviewer | Frame-level QC: artifacts, character consistency, continuity |
| operator | Operator | Publishing copy, cover images, semi-automatic publishing (Douyin/Kuaishou/WeChat Channels) |

Every agent can be called individually — no need to run the full pipeline:

- "Have the screenwriter make the episode-3 ending twist hit harder"
- "Have the reviewer re-check ep01 sh05"
- "Have the editor drop sh03 from the cut and re-concat"
- "Have the fine-cut editor enlarge the subtitles in ep01 and regenerate the draft"
- "Have the operator write 3 stronger titles"

## Generation Engine Routing

- **Design images** → Gemini web app, Nano Banana (browser automation, no credits); falls back to `dreamina text2image` with explicit notice when unavailable.
  Gemini images carry a visible watermark in the bottom-right corner — they are cleaned with `tools/clean_refimg.py` and visually re-checked before entering the library, so the watermark never gets replicated into videos by Seedance
- **Video** → Dreamina Seedance 2.0 (generated videos **include sound**: dialogue/SFX; the audio track is preserved through the whole pipeline):
  - Shots with characters → `multimodal2video` (references character design images for cross-shot consistency)
  - Empty scene/atmosphere shots → `text2video`
  - Exact first/last frames → `frames2video`
  - Default `seedance2.0fast` (value), key shots `seedance2.0` (quality)
- **Background music** → Suno web app (browser automation); BGM is delivered as separate material, not mixed into the rough cut
- **Fine cut** → `pyJianYingDraft` generates a JianYing draft project (transitions/BGM placement/subtitle track/filters); fine-tune and export in JianYing
- **Publishing** → Douyin Creator Center and other web consoles (browser automation, Gate ④ confirmation before publishing)
- **Text generation** (script/storyboard/prompts/copy) → Claude itself

## Project Layout

```
projects/<drama-title>/
├── project.json           # Project record: ratio, duration, episodes, stage statuses, credit spending
├── 01-script/             # outline.md, characters.md, ep01.md ...
├── 02-storyboard/         # ep01-storyboard.md ...
├── 03-design/             # style-bible.md, characters/, scenes/
├── 04-footage/ep01/       # shotlist.json (task list + generation log) + sh01.mp4 ... + ep01.srt + bgm/
├── 05-final/              # <title>-ep01-roughcut.mp4 + delivery-ep01.md + finalcut-ep01.md
└── 06-publish/ep01/       # copy.md + cover.png + publish-log.md
```

## Credit-Protection Mechanisms

1. No agent may submit credit-consuming generation tasks before Gate ③ is confirmed
2. No guessed credit prices: generate 1 calibration shot first, then quote from actual spending
3. Failed generations retry once automatically — never in a loop
4. Every submit_id is written to shotlist.json immediately; interrupted tasks can be collected later via `/studio-status`

## Scope (Delivery Boundary)

- ✅ Rough-cut preview (`/edit`): hard-cut concatenation with **original Dreamina audio (dialogue/SFX) preserved**, for quick pacing checks
- ✅ JianYing fine-cut draft (`/finalcut`): auto-assembled transitions, BGM placement, dialogue subtitle track, global filter —
  open JianYing to fine-tune (usual touch-ups: transitions, subtitle line breaks, BGM volume); **export is done by you in JianYing**
- ✅ Publishing materials and semi-automatic publishing (`/publish`): candidate titles, hashtags, cover image, upload and form filling — **publishing requires your confirmation**
- ❌ JianYing VIP assets and platform logins → always done by you personally

### The Four Gates

| Gate | Where | What it protects |
|---|---|---|
| ① Script approval | End of /script | Rework cost of all later stages |
| ② Design approval | End of /design | Character consistency in the final film |
| ③ Credit quote confirmation | Before generation in /shoot | Dreamina credits (the only large spend) |
| ④ Publish confirmation | Before clicking publish in /publish | Publishing is irreversible |

## Repository Layout

```
.claude-plugin/            # Plugin manifest + self-hosted marketplace
agents/                    # 11 professional agent definitions
skills/                    # 11 staged slash commands
templates/                 # Workspace convention template (copied as workspace CLAUDE.md by /new-drama)
tools/                     # concat.py (normalize + concat) and clean_refimg.py (watermark cleanup), cross-platform, copied into workspaces
VERSION / CHANGELOG.md     # Version number and changelog
requirements.txt           # Python dependency (pyJianYingDraft)
docs/superpowers/specs/    # Design docs (with revision history)
```

## Versioning

The studio follows [Semantic Versioning](https://semver.org/) (see [CHANGELOG.md](CHANGELOG.md)):
major = incompatible pipeline/layout changes; minor = new agents/commands/capabilities; patch = fixes and docs.
Every version has a git tag (`v1.0.0`, `v1.1.0`, …). Upgrade with `claude plugin update short-drama-studio`;
pin an older version with `claude plugin marketplace add <repo>@v<version>`.
