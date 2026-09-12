$ErrorActionPreference = 'Stop'

$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$out = Join-Path $PSScriptRoot 'out'
New-Item -ItemType Directory -Force -Path $out | Out-Null

# 16:9 4K master, 42 seconds, 60 fps.
npx remotion render AlMufradun-4K "$out\almufradun-promo-4k-60fps.mp4" `
  --codec=h264 --crf=15 --x264-preset=slow --concurrency=4 `
  --browser-executable $chrome

# 9:16 vertical 4K master for Reels, Shorts, and TikTok.
npx remotion render AlMufradun-Vertical-4K "$out\almufradun-promo-vertical-4k-60fps.mp4" `
  --codec=h264 --crf=15 --x264-preset=slow --concurrency=4 `
  --browser-executable $chrome
