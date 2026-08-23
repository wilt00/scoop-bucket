if (!$env:SCOOP_HOME) { $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop) }
. "$PSScriptRoot\test\Import-Bucket-Tests.ps1"
