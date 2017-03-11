$ErrorActionPreference = "Stop"
# functions:

function IsNugetVersion3OrAbove($theNugetExe) {
    try {
        $nugetText = . $theNugetExe | Out-String
    } catch {
        return false
    }
    [regex]$regex = '^NuGet Version: (\d)\.(\d).*\n'
    $match = $regex.Match($nugetText)
    $version = $match.Groups[1].Value
    Write-Host "Nuget major version is $version"
    return [System.Convert]::ToInt32($version) -ge 3
}

function Get-Nuget {
    if (gcm nuget -ErrorAction SilentlyContinue) {
        if (IsNugetVersion3OrAbove 'nuget') {
            Write-Host "Nuget is nuget"
            $nugetExe = 'nuget'
        } else {
            Download-Nuget
            Write-Host "Nuget is localNuget 1: $localNuget"
            $nugetExe = $localNuget
        }
    } else {
        Download-Nuget
        Write-Host "Nuget is localNuget 2"
        $nugetExe = $localNuget
    }
}

function Download-Nuget {
    $tempNuget = "$env:TEMP\codecracker\nuget.exe"
    if (!(Test-Path "$env:TEMP\codecracker\")) {
        md "$env:TEMP\codecracker\" | Out-Null
    }
    echo 1
    if (Test-Path $localNuget) {
        echo 2
        if (IsNugetVersion3OrAbove($localNuget)) { return }
    }
    echo 3
    if (Test-Path $tempNuget) {
        echo 4
        if (IsNugetVersion3OrAbove($tempNuget)) {
            echo 5
            cp $tempNuget $localNuget
            echo 6
            echo $tempNuget
            return
        }
    }
    wget "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $tempNuget
    cp $tempNuget $localNuget
}

function Import-Psake {
    $psakeModule = "$PSScriptRoot\packages\psake.4.5.0\tools\psake.psm1"
    if ((Test-Path $psakeModule) -ne $true) {
        Write-Host "Restoring $PSScriptRoot\.nuget with $nugetExe"
        . "$nugetExe" restore $PSScriptRoot\.nuget\packages.config -SolutionDirectory $PSScriptRoot
    }
    Import-Module $psakeModule -force
}

# statements:

$localNuget = "$PSScriptRoot\.nuget\nuget.exe"
$nugetExe = ""
Get-Nuget
Import-Psake
if ($MyInvocation.UnboundArguments.Count -ne 0) {
    . $PSScriptRoot\psake.ps1 -taskList ($MyInvocation.UnboundArguments -join " ")
}
else {
    . $PSScriptRoot\build.ps1 Build
}

exit !($psake.build_success)