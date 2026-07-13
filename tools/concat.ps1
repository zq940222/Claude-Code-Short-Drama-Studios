# concat.ps1 — 短剧工作台镜头粗剪拼接脚本
# 先把所有片段统一转码为相同规格（H.264/yuv420p/30fps/统一分辨率 + AAC 48kHz 立体声），再无损 concat。
# 即梦生成的视频自带声音（台词/音效），音轨全程保留；无音轨的片段自动补静音，保证 concat 不错位。
#
# 用法：
#   .\tools\concat.ps1 -InputDir "projects\剧名\04-footage\ep01" -Output "projects\剧名\05-final\剧名-ep01-粗剪.mp4" -Ratio 9:16
#   .\tools\concat.ps1 -InputDir ... -Output ... -Ratio 16:9 -FileList sh02.mp4,sh01.mp4   # 自定义顺序
param(
    [Parameter(Mandatory = $true)][string]$InputDir,
    [Parameter(Mandatory = $true)][string]$Output,
    [ValidateSet("9:16", "16:9")][string]$Ratio = "9:16",
    [string[]]$FileList = @(),   # 留空则取 InputDir 下全部 sh*.mp4 按名称排序
    [int]$Fps = 30,
    [int]$Crf = 18
)

$ErrorActionPreference = "Stop"

if ($Ratio -eq "9:16") { $W = 1080; $H = 1920 } else { $W = 1920; $H = 1080 }

# 1. 收集片段
if ($FileList.Count -gt 0) {
    $clips = $FileList | ForEach-Object { Join-Path $InputDir $_ }
} else {
    $clips = Get-ChildItem -Path $InputDir -Filter "sh*.mp4" | Sort-Object Name | ForEach-Object { $_.FullName }
}
if ($clips.Count -eq 0) { throw "InputDir 下没有找到镜头片段（sh*.mp4）" }
foreach ($c in $clips) { if (-not (Test-Path $c)) { throw "片段不存在: $c" } }
Write-Host "待拼接 $($clips.Count) 个片段（$W x $H @ ${Fps}fps，保留音轨）"

# 2. 统一转码到 _work 目录（视频统一规格；音频统一 AAC 48kHz 立体声，无音轨补静音）
$work = Join-Path $InputDir "_work"
New-Item -ItemType Directory -Force -Path $work | Out-Null
$normalized = @()
$i = 0
foreach ($clip in $clips) {
    $i++
    $out = Join-Path $work (("{0:d3}_" -f $i) + [IO.Path]::GetFileName($clip))
    $vf = "scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=$Fps"
    $hasAudio = & ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 $clip
    Write-Host "[$i/$($clips.Count)] 转码 $([IO.Path]::GetFileName($clip)) $(if (-not $hasAudio) {'(无音轨，补静音)'}) ..."
    if ($hasAudio) {
        & ffmpeg -y -hide_banner -loglevel error -i $clip -vf $vf `
            -c:v libx264 -pix_fmt yuv420p -crf $Crf -preset medium `
            -c:a aac -ar 48000 -ac 2 -b:a 192k $out
    } else {
        & ffmpeg -y -hide_banner -loglevel error -i $clip -f lavfi -i "anullsrc=r=48000:cl=stereo" `
            -map 0:v -map 1:a -shortest -vf $vf `
            -c:v libx264 -pix_fmt yuv420p -crf $Crf -preset medium `
            -c:a aac -ar 48000 -ac 2 -b:a 192k $out
    }
    if ($LASTEXITCODE -ne 0) { throw "转码失败: $clip" }
    $normalized += $out
}

# 3. 生成 concat 清单（ffmpeg concat 协议要求正斜杠与单引号转义）
$listFile = Join-Path $work "concat_list.txt"
$lines = $normalized | ForEach-Object { "file '" + ($_ -replace "\\", "/") + "'" }
[IO.File]::WriteAllLines($listFile, $lines)   # 无 BOM，ffmpeg 才能正确读取

# 4. 拼接
$outDir = Split-Path -Parent $Output
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
& ffmpeg -y -hide_banner -loglevel error -f concat -safe 0 -i $listFile -c copy $Output
if ($LASTEXITCODE -ne 0) { throw "拼接失败" }

# 5. 校验
$probe = & ffprobe -v error -show_entries format=duration -of csv=p=0 $Output
Write-Host "完成: $Output（时长 ${probe}s，含音轨）"
