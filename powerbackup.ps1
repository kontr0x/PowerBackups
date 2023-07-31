<#
.SYNOPSIS
    This script automates the process of backing up files from folders.

.DESCRIPTION
    The script uses robocopy to copy files from one place to another.
    All settings have to be specified in the script.
    If run multiple times, the script will only copy newer files to the destination.

.AUTHOR
    Kontr0x

.VERSION
    1.0

.LASTUPDATED
    2023-07-31
#>

$ErrorActionPreference = "Stop"

Function Is-Drive-Present{

    param(
        [String]$path
    )

    $driveLetter = $path[0]
    if (-Not (Test-Path $driveLetter -IsValid)) {
        throw "Cannot find drive. A drive with the name '$driveLetter' does not exist."
    }
}

Class DirToBackup{

    [String]$fullPath
    [String]$path
    DirToBackup([String]$sourcePath) {
        Is-Drive-Present -path $sourcePath
        if (-Not (Test-Path $sourcePath)) {
            throw "The provided path '$sourcePath' does not exist."
            }
        $this.fullPath = $sourcePath
        $this.path = $sourcePath -replace ':',''
    }
}

################################################################
#
# Change the following variables to suit your needs:
#

$dirsToBackup = @(
    New-Object DirToBackup "C:\Example\Path"
)

$backupPath = "X:\Example\Backup\Path"

# Excluded files
$defaultListOfExcludedFileNames = @(
    "exampleFileName"
)

# Excluded file extensions
$defaultListOfExcludedFileExtensions = @(
    ".exampleFileExtension"
)

# Excluded folders
$defaultListOfExcludedFolders = @(
    "exampleFolder"
)

#
#
################################################################

# Check if backup drive is available
Is-Drive-Present -path $backupPath

# Create file exclude list
$defaultFileExcludeList = @()
$defaultFileExcludeList += $defaultListOfExcludedFileNames.ForEach({"$_.*"}) 
$defaultFileExcludeList += $defaultListOfExcludedFileExtensions.ForEach({"*$_"})

# Specify backup and logging destination paths
$pathToBackup = Join-Path -Path $backupPath -ChildPath $("Backup" + "\")
$pathToLogs = Join-Path -Path $backupPath -ChildPath $("Logs" + "\")

# Setup up logging
mkdir -Path $($pathToLogs) -Force
$logFilename = "CopyLog"
$currentTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "${logFilename}_${currentTimestamp}.txt"

# Progress bar initialization
$progressParams = @{
    Activity = "Copying directories"
    Status   = "Initializing"
}
Write-Progress @progressParams
$totalItems = $dirsToBackup.Count
$copiedItems = 0

# Backup loop
$dirsToBackup | ForEach-Object {
    clear

    # Write progress status
    $percentComplete = ($copiedItems / $totalItems) * 100
    $progressParams.Status = "Progress: $percentComplete% ($copiedItems/$totalItems)"
    Write-Progress @progressParams

    # Backup files
    mkdir -Path $($pathToBackup + $_.path) -Force
    robocopy $($_.fullPath) $($pathToBackup + $_.path) /E /Z /R:0 /W:0 /TEE /LOG+:$($pathToLogs + $logFile) /XO /XD $defaultListOfExcludedFolders /XF $defaultFileExcludeList | ForEach-Object {
        if(-not ($_.Contains("%")) ){
            Write-Host $_
        }
    }

    $copiedItems++
}

# Finalize the progress bar
$progressParams.PercentComplete = 100
$progressParams.Status = "Copy completed"
Write-Progress @progressParams

Write-Host "Logs written to" $($pathToLogs + $logFile)