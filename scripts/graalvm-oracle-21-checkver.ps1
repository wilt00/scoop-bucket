param([Parameter(Mandatory)][string]$Version)

$parts = $Version.Split('.')
$nextPatch = "$($parts[0]).$($parts[1]).$([int]$parts[2] + 1)"
$nextMinor = "$($parts[0]).$([int]$parts[1] + 1).0"
$latest = $Version
foreach ($c in @($nextPatch, $nextMinor)) {
    $u = "https://download.oracle.com/graalvm/21/archive/graalvm-jdk-${c}_windows-x64_bin.zip.sha256"
    try {
        $r = Invoke-WebRequest -Uri $u -Method Head -UserAgent 'Mozilla/5.0' -ErrorAction Stop
        if ($r.StatusCode -eq 200) { $latest = $c }
    } catch {}
}
"version: $latest"
