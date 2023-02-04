$time_offset = (Get-Date).AddDays(-24)
$do_deletion = $false

$gradle_package_home = "${Home}\.gradle\caches\modules-2\files-2.1"
$log_path = "$PSCommandPath.log.txt"


#######################################


function Log(
    [string]$msg,
    [string]$logfile = $log_path
) {
    $msg | Out-File -Append $logfile
}

#####################
# create & clear file
#####################

"" | Out-File $log_path

Log("Time Offset: $($time_offset.ToString())`n")
Log("Path       : $gradle_package_home`n")
Log("")
Log("Files      : ")

$files_to_delete = @()

##########
#  Filter
##########

Get-ChildItem -Attributes !Directory -Recurse  $gradle_package_home |
# Select-Object Name, LastAccessTime, CreationTime, Length, Directory |
ForEach-Object {
    $item_name = $_.Name.ToString()
    
    $output_lines = 
    "  - FileName       : " + $_.FullName.Remove(0, $gradle_package_home.Length) + "`n" +
    "  - LastAccessTime : " + $_.LastAccessTime.ToString("u") + "`n" + 
    "  - CreationTime   : " + $_.CreationTime.ToString("u") + "`n" +
    "  - File Size      : " + $_.Length.ToString()

    # true if this file is key files
    $filter_condition_key_files = (
        $item_name.EndsWith("aar") -or
        (
            $item_name.EndsWith("jar") -and
            -not $item_name.Contains("-sources.jar") -and
            -not $item_name.Contains("-javadoc.jar")            
        )
    )

    # process stale key files
    if ($filter_condition_key_files) {
        if ($_.LastAccessTime -lt $time_offset) {
            $files_to_delete += $_
            Log("~ DELETE :`n$output_lines")
        }
        else {
            Log("~ SKIP   : fresh file`n$output_lines")
        }
    }
    else {
        Log("~ IGNORE : misc file`n$output_lines")
    }
}


###############
# Actual delete
###############

$dir_to_delete = @()

Log("`nDirectory to be deleted:`n")
$files_to_delete | ForEach-Object {

    
    if ($_ -is [System.IO.FileInfo]) {
        $_hd = [System.IO.DirectoryInfo]$_.Directory  # 40 char length hash dir
        $regex = [System.Text.RegularExpressions.Regex]::new("[0-9abcdefABCDEF]{10,}")
        if ($regex.Match($_hd.Name)) {
            $_vd = [System.IO.DirectoryInfo]$_hd.Parent
            $dir_to_delete += $_vd
            Log("* " + $_vd.FullName.Remove(0, $gradle_package_home.Length))
        }
        else {
            Write-Warning "ERR: not a hash directory name:"
            Write-Warning $_hd.Name 
        }
    }
    else {
        Write-Warning "ERR: not a file "
    }
}

Log("`nDeleting... ")
$dir_to_delete | ForEach-Object {
    Log("Delete " + $_.FullName)
    if ($do_deletion) { $_.Delete($true) }
}

