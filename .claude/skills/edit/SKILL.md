---
name: edit
description: 剪辑成片阶段。调度剪辑师 agent 用 ffmpeg 统一转码、按分镜顺序拼接镜头，输出成片到 05-final。用户说"剪辑"、"合成"、"出片"、"/edit"时使用。
---

# /edit 剪辑成片

## 前置检查

- shotlist.json 中本集全部镜头 status=success（或用户在 /review 明确放行）；有缺口先报告

## 流程

1. 调度 **editor** agent：
   - 按 shotlist 顺序统一转码 + 拼接（用 `tools/concat.ps1`）
   - 输出 `05-final/<剧名>-ep{NN}.mp4`
   - ffprobe 校验时长/规格，抽首中尾 3 帧确认画面
2. 向用户报告成片路径、时长、分辨率，展示抽帧
3. 更新 project.json：status.final → done
4. 收尾提示：配音、配乐、字幕建议在剪映/PR 中完成（本工作台不做 TTS）；
   若是多集项目，提示继续下一集（回到 /script 或 /storyboard，视剧本是否已含该集）
