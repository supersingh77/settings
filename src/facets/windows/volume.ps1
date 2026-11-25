$ErrorActionPreference = 'Stop'
$rows = @([System.IO.DriveInfo]::GetDrives() | Where-Object IsReady | ForEach-Object {
    [pscustomobject]@{
        letter = $_.Name.TrimEnd('\')
        label = [string]$_.VolumeLabel
        type = $_.DriveType.ToString()
        totalGb = [math]::Round($_.TotalSize / 1GB, 1)
        freeGb = [math]::Round($_.TotalFreeSpace / 1GB, 1)
    }
})
ConvertTo-Json -InputObject $rows -Compress
