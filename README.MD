# PowerShell Backup Script Documentation

## Overview

The PowerShell script is designed for automating the backup process of databases and server worlds. It utilizes configuration settings from a JSON file to specify details such as database connection information, server details, API credentials, and backup paths.

## Configuration

The script relies on a configuration file (`config.json`) for various settings. This file includes the following sections:

- **Databases Configuration**
  - Database connection details (host, user, password)
  - Database names
  - Backup path
  - Retention period in days

- **Panel Configuration**
  - Panel URL
  - Server IDs
  - API key
  - Backup path

## Functions

### 1. `BackupDatabase`

- **Purpose:** Perform backups of specified databases using `mysqldump`.
- **Steps:**
  1. Iterate through configured databases.
  2. For each database, create a timestamped backup file.
  3. Check if the backup folder exists; if not, create it.
  4. Execute `mysqldump` command to create a SQL backup file.

### 2. `BackupWorlds`

- **Purpose:** Backup server worlds using an API provided by a panel.
- **Steps:**
  1. Iterate through configured server IDs.
  2. Retrieve backup information using panel API.
  3. Download each backup and save it to a specified folder.
  4. Create server-specific backup folders if they don't exist.

### 3. `DeleteOldItems`

- **Purpose:** Delete old backup files based on the specified retention period.
- **Steps:**
  1. Iterate through configured databases.
  2. For each database, determine the cutoff date based on the retention period.
  3. Delete backup files older than the cutoff date.

### 4. Main Script Logic

- **Usage:** The script can be executed with command-line arguments to specify the type of backup to perform.
  - `-db`: Execute database backups.
  - `-w`: Execute server world backups.
  - If no argument is provided, display usage information.

## Usage

- Execute the script from the command line with the desired arguments:

  ```powershell
  .\backup.ps1 -db   # Perform database backups
  .\backup.ps1 -w    # Perform server world backups
  ```

- The script will automatically read the `config.json` file and perform the specified backup tasks.