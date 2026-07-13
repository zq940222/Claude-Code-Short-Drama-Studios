# clean-refimg.ps1 — 设定图水印清理脚本
# Gemini（Nano Banana）生成的图片右下角带可见水印；设定图作为 multimodal2video 参考图时，
# 水印会被 Seedance 复刻进视频。设定图入库（03-design/）前必须先用本脚本清理。
#
# 两种模式：
#   delogo（默认）：用 ffmpeg delogo 修复右下角水印区域，保留完整画面（角落是背景时效果最好）
#   crop：直接裁掉底部条带（画面底部无关键内容时用，如场景图天空/地面留白多）
#
# 用法：
#   .\tools\clean-refimg.ps1 -In raw.png -Out "03-design\characters\林晚-front.png"
#   .\tools\clean-refimg.ps1 -In raw.png -Out clean.png -Mode crop
#   .\tools\clean-refimg.ps1 -In raw.png -Out clean.png -WidthPct 0.25 -HeightPct 0.10   # 水印偏大时扩大区域
param(
    [Parameter(Mandatory = $true)][string]$In,
    [Parameter(Mandatory = $true)][string]$Out,
    [ValidateSet("delogo", "crop")][string]$Mode = "delogo",
    [double]$WidthPct = 0.20,    # 水印区域宽度占比（右下角）
    [double]$HeightPct = 0.08    # 水印区域/裁剪条带高度占比
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path $In)) { throw "输入文件不存在: $In" }

# 取图片尺寸（注意：PowerShell 变量名不区分大小写，图片尺寸与区域尺寸必须用不同名字）
$dim = & ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 $In
$imgW = [int]($dim -split ",")[0]
$imgH = [int]($dim -split ",")[1]

if ($Mode -eq "delogo") {
    # delogo 区域必须完整落在画面内部（不能贴边），四周留 2px
    $regW = [Math]::Min([int]($imgW * $WidthPct), $imgW - 4)
    $regH = [Math]::Min([int]($imgH * $HeightPct), $imgH - 4)
    $x = $imgW - $regW - 2
    $y = $imgH - $regH - 2
    $vf = "delogo=x=${x}:y=${y}:w=${regW}:h=${regH}"
} else {
    $strip = [int]($imgH * $HeightPct)
    $vf = "crop=${imgW}:$($imgH - $strip):0:0"
}

$outDir = Split-Path -Parent $Out
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
& ffmpeg -y -hide_banner -loglevel error -i $In -vf $vf -frames:v 1 -update 1 $Out
if ($LASTEXITCODE -ne 0) { throw "水印清理失败: $In" }
Write-Host "完成($Mode): $Out（${imgW}x${imgH}，处理区域 ${vf}）"
Write-Host "提醒：清理后务必肉眼检查右下角，水印残留时扩大 -WidthPct/-HeightPct 重跑"
