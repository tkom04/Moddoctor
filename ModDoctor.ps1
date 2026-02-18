# Blade & Sorcery Mod Doctor
# Parses Player.log and identifies problematic mods
# Upload to Nexus Mods as a utility/tool for the community

param(
    [string]$LogPath = ""
)

# Auto-detect log path if not specified
if ([string]::IsNullOrEmpty($LogPath)) {
    $candidates = @(
        "$env:USERPROFILE\AppData\LocalLow\Warpfrog\BladeAndSorcery\Player.log",
        "$PSScriptRoot\Player.log",
        "$env:USERPROFILE\Documents\My Games\BladeAndSorcery\Player.log"
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            $LogPath = $candidate
            break
        }
    }
}

# Check if log exists
if ([string]::IsNullOrEmpty($LogPath) -or -not (Test-Path $LogPath)) {
    Write-Host "Error: Player.log not found." -ForegroundColor Red
    Write-Host "Searched: AppData\LocalLow\Warpfrog\BladeAndSorcery, script folder, Documents\My Games" -ForegroundColor Gray
    Write-Host "Make sure you've launched B&S at least once, or specify: -LogPath `"C:\path\to\Player.log`"" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n=== BLADE & SORCERY MOD DOCTOR ===" -ForegroundColor Cyan
Write-Host "Analyzing: $LogPath`n" -ForegroundColor Gray

# Read log file
$log = Get-Content $LogPath -Raw
$logLines = $log -split "`n"

# Build catalog ID -> Mod mapping from Overriding lines (for mod attribution)
$catalogIdToMod = @{}
$logLines | Where-Object { $_ -match "\[ModManager\]\[Catalog\]\[([^\]]+)\].*Overriding:.*\[[^\]]+\]\[[^\]]+\]\[([^\]]+)\]" } | ForEach-Object {
    if ($_ -match "\[ModManager\]\[Catalog\]\[([^\]]+)\].*Overriding:.*\[[^\]]+\]\[[^\]]+\]\[([^\]]+)\]") {
        $modName = $matches[1]
        $catalogId = $matches[2]
        $catalogIdToMod[$catalogId] = $modName
    }
}

# Infer mod from asset address patterns (when not in catalog)
function Get-ModForWarning {
    param($catalogId, $assetAddress)
    if ($catalogIdToMod.ContainsKey($catalogId)) { return $catalogIdToMod[$catalogId] }
    if ($assetAddress -match "Warp[12]") { return "SHRINE" }
    if ($assetAddress -match "earthbending") { return "EarthBending" }
    if ($assetAddress -match "CastleInvasion") { return "GalacticArena" }
    if ($catalogId -match "^(nhalberd|naxe|ndagger|nmace|nspear|nwh|npa|BardecheNew|FalchionNew|LongswordT4|nwh2|zweihander|ShortT4Sword|SorcerersSword|VikingAxe|WarAxe|DaneAxe|SpikedBattleAxe|TypeLDaneAxe|BuccklerShieldLarge|AmberDiamond|BlueDiamond|Ruby)") { return "Medieval MegaPack / TheMiddleAges" }
    if ($catalogId -match "^(Longsword3|Crossbow|naxe4)") { return "Medieval MegaPack / TheMiddleAges" }
    if ($catalogId -match "EarthBendingRockSpikes") { return "EarthBending" }
    return "Unknown"
}

# Initialize error counters
$outdatedMods = @{}
$brokenMods = @{}
$missingColliders = @()  # Array of @{ItemId, Mod}
$missingAssets = @{}     # Key: "asset|targetId", Value: @{Count, Mod}

# Parse for version incompatibility
$log -split "`n" | Where-Object { $_ -match "ModManager.*not compatible" } | ForEach-Object {
    if ($_ -match "Mod (.+?) for \((.+?)\) is not compatible") {
        $modName = $matches[1].Trim()
        $version = $matches[2]
        $outdatedMods[$modName] = $version
    }
}

# Parse for JSON errors (handles both / and \ in paths)
$log -split "`n" | Where-Object { $_ -match "Cannot read json file" } | ForEach-Object {
    if ($_ -match "Mods[/\\]([^/\\]+?)(?:[/\\]|$)") {
        $modName = $matches[1]
        if ($brokenMods.ContainsKey($modName)) {
            $brokenMods[$modName]++
        } else {
            $brokenMods[$modName] = 1
        }
    }
}

# Parse for missing collider groups (with mod attribution)
$logLines | Where-Object { $_ -match "ColliderGroupData not found" } | ForEach-Object {
    if ($_ -match "on item ([^\s]+)\s*$") {
        $itemId = $matches[1]
        $mod = if ($catalogIdToMod.ContainsKey($itemId)) { $catalogIdToMod[$itemId] } else { Get-ModForWarning $itemId $null }
        $missingColliders += [PSCustomObject]@{ ItemId = $itemId; Mod = $mod }
    }
}

# Parse for missing assets (with mod attribution)
$logLines | Where-Object { $_ -match "Address.*not found" } | ForEach-Object {
    if ($_ -match "Address \[(.+?)\].*not found for \[(.+?)\]") {
        $asset = $matches[1]
        $targetId = $matches[2]
        $lookupId = if ($targetId -match "^\s*(\S+)") { $targetId.Trim().Split(" ")[0] } else { $targetId }
        $mod = Get-ModForWarning $lookupId $asset
        $key = "$asset|$targetId"
        if ($missingAssets.ContainsKey($key)) {
            $missingAssets[$key].Count++
        } else {
            $missingAssets[$key] = [PSCustomObject]@{ Asset = $asset; TargetId = $targetId; Count = 1; Mod = $mod }
        }
    }
}

# Display results
$criticalCount = $outdatedMods.Count + $brokenMods.Count

if ($criticalCount -gt 0) {
    Write-Host "CRITICAL ISSUES ($criticalCount mods won't work):" -ForegroundColor Red
    Write-Host ""

    if ($outdatedMods.Count -gt 0) {
        Write-Host "  OUTDATED MODS (wrong version):" -ForegroundColor Yellow
        $outdatedMods.GetEnumerator() | Sort-Object Name | ForEach-Object {
            Write-Host "    X $($_.Key) (v$($_.Value), needs v1.0+)" -ForegroundColor Red
        }
        Write-Host ""
    }

    if ($brokenMods.Count -gt 0) {
        Write-Host "  BROKEN MODS (corrupted files):" -ForegroundColor Yellow
        $brokenMods.GetEnumerator() | Sort-Object Name | ForEach-Object {
            Write-Host "    X $($_.Key) ($($_.Value) JSON errors)" -ForegroundColor Red
        }
        Write-Host ""
    }
}

# Warnings
$warningCount = 0
if ($missingColliders.Count -gt 0) { $warningCount++ }
if ($missingAssets.Count -gt 0) { $warningCount++ }

if ($warningCount -gt 0) {
    Write-Host "WARNINGS (may cause issues):" -ForegroundColor Yellow
    Write-Host ""

    if ($missingColliders.Count -gt 0) {
        $uniqueItems = ($missingColliders | Select-Object -Property ItemId -Unique).Count
        Write-Host "  - Missing ColliderGroups: $uniqueItems items affected" -ForegroundColor Yellow
        $collidersByMod = $missingColliders | Group-Object -Property Mod | Sort-Object Count -Descending
        foreach ($group in $collidersByMod) {
            $itemList = ($group.Group | Select-Object -ExpandProperty ItemId -Unique) -join ", "
            if ($itemList.Length -gt 60) { $itemList = $itemList.Substring(0, 57) + "..." }
            Write-Host "    [$($group.Name)] $itemList" -ForegroundColor DarkYellow
        }
    }

    if ($missingAssets.Count -gt 0) {
        $assetsList = $missingAssets.Values
        $totalMissing = ($assetsList | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
        Write-Host "  - Missing Assets: $totalMissing warnings" -ForegroundColor Yellow
        $assetsByMod = $assetsList | Group-Object -Property Mod | Sort-Object { ($_.Group | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum } -Descending
        foreach ($group in $assetsByMod) {
            $totalForMod = ($group.Group | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
            Write-Host "    [$($group.Name)] $totalForMod warning(s):" -ForegroundColor DarkYellow
            $group.Group | Sort-Object Count -Descending | Select-Object -First 3 | ForEach-Object {
                Write-Host "      - $($_.Asset) (x$($_.Count))" -ForegroundColor Gray
            }
            if ($group.Group.Count -gt 3) {
                Write-Host "      ... and $($group.Group.Count - 3) more" -ForegroundColor DarkGray
            }
        }
    }
    Write-Host ""
}

# Summary
if ($criticalCount -eq 0 -and $warningCount -eq 0) {
    Write-Host "No critical issues found! All mods loaded successfully." -ForegroundColor Green
} else {
    Write-Host "SUMMARY:" -ForegroundColor Cyan
    if ($criticalCount -gt 0) {
        Write-Host "  - $criticalCount mod(s) need attention (won't work)" -ForegroundColor Red
    }
    if ($warningCount -gt 0) {
        Write-Host "  - $warningCount warning type(s) detected (may work)" -ForegroundColor Yellow
    }
}

Write-Host "`nRecommendation: Update or remove mods marked with X" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to exit"
