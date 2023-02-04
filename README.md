## Poweshell Scripts to clean Gradle Cache

These are scripts to help you clean unused gradle cache by last file access time.

### Manifest


|              File               |                Desc                |
| :-----------------------------: | :--------------------------------: |
| `gradle_clean_dependencies.ps1` | Clean `\.gradle\caches\modules-2\` |
|     `gradle_clean_jar.ps1`      |   Clean `.gradle\caches\jars-9`    |

### Config

In each scripts, we have variables:

|   Variables    |                        Meaning                         |
| :------------: | :----------------------------------------------------: |
| `$do_deletion` |    `$false` if no intention to do actual deletion.     |
| `$time_offset` | files older than this time would be deleted by script. |
