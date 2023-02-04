$time_offset = (Get-Date).AddDays(-7)
$do_deletion = $false

$gradle_jar_home = "${Home}\.gradle\caches\jars-9"
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
Log("Path       : $gradle_jar_home`n")
Log("")
Log("Files      : ")

$files_to_delete = @()


##########
#  Filter
##########

Get-ChildItem -Attributes !Directory -Recurse  $gradle_jar_home |
# Select-Object Name, LastAccessTime, CreationTime, Length, Directory |
ForEach-Object {
    $item_name = $_.Name.ToString()
    
    $output_lines = 
    "  - FileName       : " + $_.FullName.Remove(0, $gradle_jar_home.Length) + "`n" +
    "  - LastAccessTime : " + $_.LastAccessTime.ToString("u") + "`n" + 
    "  - CreationTime   : " + $_.CreationTime.ToString("u") + "`n" +
    "  - File Size      : " + $_.Length.ToString()

    # true if this file is key files
    $filter_condition_key_files = (
        $item_name.EndsWith("jar")
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

Log("Directory to be deleted:`n")
$files_to_delete | ForEach-Object {
    
    if ($_ -is [System.IO.FileInfo]) {
        $_hd = [System.IO.DirectoryInfo]$_.Directory # hash directory
        $regex = [System.Text.RegularExpressions.Regex]::new("(o_)?[0-9abcdefABCDEF]{10,}")
        if ($regex.Match($_hd.Name)) {
            $dir_to_delete += $_hd
            Log("* " + $_.FullName.Remove(0, $gradle_jar_home.Length))
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
