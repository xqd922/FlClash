param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$checks = @(
    @{
        Path = 'android/app/src/main/AndroidManifest.xml'
        Pattern = 'android\.permission\.QUERY_ALL_PACKAGES'
        Message = 'release manifest must not request QUERY_ALL_PACKAGES'
    },
    @{
        Path = 'android/app/src/main/AndroidManifest.xml'
        Pattern = 'android\.permission\.CHANGE_NETWORK_STATE'
        Message = 'release manifest must not request unused CHANGE_NETWORK_STATE'
    },
    @{
        Path = 'android/app/src/main/AndroidManifest.xml'
        Pattern = '\$\{applicationId\}\.action\.(START|STOP|TOGGLE)'
        Message = 'release manifest must not expose quick action intent filters'
    },
    @{
        Path = 'android/app/src/main/kotlin/com/follow/clash/plugins/AppPlugin.kt'
        Pattern = 'DexBackedDexFile|publicSourceDir|ZipFile'
        Message = 'AppPlugin must not inspect installed APK files or parse other apps dex files'
    },
    @{
        Path = 'android/app/build.gradle.kts'
        Pattern = 'smali\.dexlib2|smali-dexlib2'
        Message = 'app module must not depend on dexlib2 after removing APK dex scanning'
    },
    @{
        Path = 'android/gradle/libs.versions.toml'
        Pattern = 'smaliDexlib2|smali-dexlib2'
        Message = 'version catalog must not keep unused dexlib2 coordinates'
    }
)

$failures = @()
foreach ($check in $checks) {
    $path = Join-Path $Root $check.Path
    if (-not (Test-Path $path)) {
        $failures += "Missing file: $($check.Path)"
        continue
    }

    $matches = Select-String -Path $path -Pattern $check.Pattern -AllMatches
    if ($matches) {
        $locations = $matches | ForEach-Object { "$($_.Path):$($_.LineNumber)" }
        $failures += "$($check.Message): $($locations -join ', ')"
    }
}

$manifestPath = Join-Path $Root 'android/app/src/main/AndroidManifest.xml'
if (Test-Path $manifestPath) {
    [xml]$manifest = Get-Content -Raw $manifestPath
    $androidNs = 'http://schemas.android.com/apk/res/android'
    $application = $manifest.manifest.application

    $broadcastReceiver = @($application.receiver) | Where-Object {
        $_.GetAttribute('name', $androidNs) -eq '.BroadcastReceiver'
    } | Select-Object -First 1
    if ($broadcastReceiver -and $broadcastReceiver.GetAttribute('exported', $androidNs) -ne 'false') {
        $failures += 'BroadcastReceiver must not be exported; service broadcasts are in-app only'
    }

    $releaseLabel = $application.GetAttribute('label', $androidNs)
    if ($releaseLabel -eq 'FlClash') {
        $failures += 'Android release label must be distinct from upstream FlClash to reduce impersonation false positives'
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output 'Android static risk checks passed.'
