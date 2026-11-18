$ErrorActionPreference = 'Stop'
$adb = Join-Path $env:LOCALAPPDATA 'Android/Sdk/platform-tools/adb.exe'
New-Item -ItemType Directory -Force 'build/qa' | Out-Null
try {
    & $adb shell settings put secure show_ime_with_hard_keyboard 1
    flutter test integration_test/app_test.dart -d emulator-5554 --dart-define=QA_CAPTURE=true --reporter expanded 2>&1 | ForEach-Object {
        $line = "$_"
        Write-Output $line
        if ($line -match 'QA_CAPTURE:(native-[a-z-]+)') {
            $captureName = $Matches[1]
            if ($captureName -eq 'native-android-large-font') {
                & $adb shell settings put system font_scale 1.6
                Start-Sleep -Seconds 1
            }
            & $adb shell screencap -p /sdcard/metas-qa.png
            & $adb pull /sdcard/metas-qa.png "build/qa/$captureName.png"
            if ($captureName -eq 'native-android-large-font') {
                & $adb shell settings put system font_scale 1.0
            }
        }
    }
    if ($LASTEXITCODE -ne 0) { throw 'Native UI test failed.' }
} finally {
    & $adb shell settings put system font_scale 1.0
}
