function BackupDatabase {
    Write-Host "Backing up database..."

    $databases = $config.databases

    foreach ($database in $databases) {
        $databaseUrl = $database.host
        $databaseUser = $database.user
        $databasePassword = $database.password
        $databaseNames = $database.names
        $databaseBackupPath = $database.backupPath

        foreach ($db in $databaseNames) {
            $ACTUAL_DATE = Get-Date -Format "dd-MM-yyyy hh.mm.ss"

            $dbFolderPath = Join-Path -Path $databaseBackupPath -ChildPath $db

            if (-not (Test-Path -Path $dbFolderPath)) {
                New-Item -Path $dbFolderPath -ItemType Directory
            }

            $FILE_BACKUP_DBNAME = Join-Path -Path $dbFolderPath -ChildPath $db

            $file = "$($FILE_BACKUP_DBNAME)-$($ACTUAL_DATE).sql"

            mysqldump.exe -h $databaseUrl -u $databaseUser --password=$databasePassword $db --column-statistics=0 > "$($FILE_BACKUP_DBNAME)-$($ACTUAL_DATE).sql"
        }
    }
}

function BackupWorlds {

    $ProgressPreference = 'SilentlyContinue'

    $panelUrl = $config.panel.url

    $serverId = $config.panel.serverId

    $apiKey = $config.panel.key

    $Headers = @{
        'Accept' = 'application/json'
        'Content-Type' = 'application/json'
        'Authorization' = "Bearer $apiKey"
    }

    foreach ($id in $serverId) {

        Write-Output "Backing up server $id..."
        
        $backupInfo = Invoke-RestMethod -Uri "$panelUrl/api/client/servers/$id/backups" -Headers $Headers -Method GET
        
        $serverInfo =  Invoke-RestMethod -Uri "$panelUrl/api/client/servers/$id" -Headers $Headers -Method GET
        
        $downloadUUIDs = $backupInfo.data | Select-Object -ExpandProperty attributes | Select-Object -ExpandProperty uuid
        
        $serverName = $serverInfo | Select-Object -ExpandProperty attributes | Select-Object -ExpandProperty name
        
        foreach ($uuid in $downloadUUIDs) {

            $backupDetails = Invoke-RestMethod -Uri "$panelUrl/api/client/servers/$id/backups/$uuid" -Headers $Headers -Method GET

            $dateString = $backupDetails | Select-Object -ExpandProperty attributes | Select-Object -ExpandProperty completed_at

            $date = Get-Date $dateString -Format "dd-MM-yyyy hh.mm.ss"

            $backupURL = Invoke-RestMethod -Uri "$panelUrl/api/client/servers/$id/backups/$uuid/download" -Headers $Headers -Method GET

            $url = $backupURL | Select-Object -ExpandProperty attributes | Select-Object -ExpandProperty url

            $backupFolderPath = Join-Path -Path $config.panel.backupPath -ChildPath $serverName
          
            $backupFilePath = Join-Path -Path $backupFolderPath -ChildPath "$serverName-$date.tar.gz"

            # Create the server-specific backup folder if it doesn't exist
            if (-not (Test-Path -Path $backupFolderPath)) {
                New-Item -Path $backupFolderPath -ItemType Directory
            }

            Invoke-WebRequest -Uri $url -OutFile $backupFilePath

        }
    }
}

function DeleteOldItems {
    Write-Host "Deleting old backups..."

    $databases = $config.databases

    foreach ($database in $databases) {
        $databaseBackupPath = $database.backupPath

        $days = $database.retention

        $now = Get-Date
        
        $cutoffDate = $now.AddDays(-$days)

        Get-ChildItem -Path $databaseBackupPath -Recurse | Where-Object {
            $_.LastWriteTime -lt $cutoffDate
        } | ForEach-Object {
    
            Write-Output "Deleting $($_.FullName)"

            Remove-Item $_.FullName -Force
        }
    }
}

$config = Get-Content -Raw -Path config.json | ConvertFrom-Json

if ($args -contains "-db") {    
    DeleteOldItems
    
    BackupDatabase
}

elseif ($args -contains "-w") {
    DeleteOldItems
    
    BackupWorlds
}
else {
    Write-Host "Usage: backup.ps1 [-db] [-w]"
}