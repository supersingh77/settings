$ErrorActionPreference = 'Stop'
$extensions = @(
    '.md',
    '.mp4', '.mkv', '.avi', '.mov', '.m4v', '.wmv', '.mpg', '.mpeg', '.ts', '.m2ts',
    '.mp3', '.m4a', '.flac', '.wav', '.aac', '.ogg', '.opus', '.wma', '.ac3'
)
$declaredProgIds = @('MarkdownText', 'Markdown Document', 'Text Document')
$declaredApplications = @('GenOffice.exe', 'PotPlayerMini64.exe', 'notepad.exe')

function Get-DefaultValue {
    param([string]$Key)
    (Get-ItemProperty -LiteralPath $Key -ErrorAction SilentlyContinue).'(default)'
}

$extRows = foreach ($extension in $extensions) {
    $key = "Registry::HKEY_CLASSES_ROOT\$extension"
    $openWithKey = "$key\OpenWithProgids"
    $progIds = @()
    if (Test-Path -LiteralPath $openWithKey) {
        $progIds = @((Get-Item -LiteralPath $openWithKey).GetValueNames() | Where-Object { $_ })
    }
    $listKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$extension\OpenWithList"
    $exe = $null
    if (Test-Path -LiteralPath $listKey) {
        $exe = (Get-ItemProperty -LiteralPath $listKey -ErrorAction SilentlyContinue).'a'
    }
    [pscustomobject]@{
        ext = $extension
        progid = Get-DefaultValue $key
        openWithProgids = @($progIds)
        openWithExe = $exe
    }
}

$progIdNames = @($declaredProgIds) + @($extRows | ForEach-Object { $_.progid })
$progIdRows = foreach ($name in ($progIdNames | Where-Object { $_ } | Sort-Object -Unique)) {
    $key = "Registry::HKEY_CLASSES_ROOT\$name"
    [pscustomobject]@{
        progid = $name
        description = Get-DefaultValue $key
        command = Get-DefaultValue "$key\shell\open\command"
    }
}

$appRows = foreach ($exe in $declaredApplications) {
    $key = "Registry::HKEY_CLASSES_ROOT\Applications\$exe"
    $friendly = $null
    $command = $null
    if (Test-Path -LiteralPath $key) {
        $friendly = (Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue).FriendlyAppName
        $command = Get-DefaultValue "$key\shell\open\command"
    }
    [pscustomobject]@{
        exe = $exe
        friendly = $friendly
        command = $command
    }
}

ConvertTo-Json -Compress -Depth 5 -InputObject ([pscustomobject]@{
    extensions = @($extRows)
    progids = @($progIdRows)
    applications = @($appRows)
})
