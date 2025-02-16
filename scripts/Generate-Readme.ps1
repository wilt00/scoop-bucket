@"
# Scoop Bucket

A personal, unofficial [scoop](https://scoop.sh) bucket of miscellaneous Windows applications.

## Usage

``````powershell
scoop bucket add wilt00 https://github.com/wilt00/scoop-bucket
scoop install wilt00/<app_name>
``````

## Apps

| Name | Description | Version |
|------|-------------|---------|
"@ | Out-File -FilePath .\Readme.md

Get-ChildItem ./bucket | ForEach-Object {
    $manifest = Get-Content $_ | ConvertFrom-Json -AsHashtable
    $manifest.name = $_.Name.TrimEnd(".json")
    $manifest
} | ForEach-Object {
    "|[{0}]({1})|{2}|{3}" -f $_.name, $_.homepage, $_.version, $_.description
} | Out-File -FilePath .\Readme.md -Append
