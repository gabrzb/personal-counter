# Draw the geometric launcher mark directly; no image dependencies.
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path $PSScriptRoot -Parent
function Write-MetasIcon([string] $target, [int] $size) {
    $bitmap = New-Object System.Drawing.Bitmap $size, $size
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#C92A3E'))
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), ($size * 0.065)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $graphics.DrawLine($pen, ($size * 0.29), ($size * 0.73), ($size * 0.29), ($size * 0.27))
    $points = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($size * 0.29, $size * 0.29),
        [System.Drawing.PointF]::new($size * 0.54, $size * 0.29),
        [System.Drawing.PointF]::new($size * 0.58, $size * 0.36),
        [System.Drawing.PointF]::new($size * 0.74, $size * 0.36),
        [System.Drawing.PointF]::new($size * 0.74, $size * 0.56),
        [System.Drawing.PointF]::new($size * 0.50, $size * 0.56),
        [System.Drawing.PointF]::new($size * 0.46, $size * 0.49),
        [System.Drawing.PointF]::new($size * 0.29, $size * 0.49)
    )
    $graphics.DrawLines($pen, $points)
    $bitmap.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
    $pen.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}
$androidSizes = @{ 'mdpi' = 48; 'hdpi' = 72; 'xhdpi' = 96; 'xxhdpi' = 144; 'xxxhdpi' = 192 }
foreach ($density in $androidSizes.Keys) {
    Write-MetasIcon (Join-Path $projectRoot "android/app/src/main/res/mipmap-$density/ic_launcher.png") $androidSizes[$density]
}
$iosDirectory = Join-Path $projectRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
$manifest = Get-Content (Join-Path $iosDirectory 'Contents.json') -Raw | ConvertFrom-Json
foreach ($entry in $manifest.images) {
    if ($entry.filename) {
        $dimension = [double]($entry.size.Split('x')[0]) * [double]($entry.scale.TrimEnd('x'))
        Write-MetasIcon (Join-Path $iosDirectory $entry.filename) ([int]$dimension)
    }
}
