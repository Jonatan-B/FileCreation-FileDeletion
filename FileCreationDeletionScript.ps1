# Global Variables
$folderPath = "C:\temp" # This variable needs to be the path where the files will be created.
$createFiles = $true # This variable is used to instantiation. Do not change.

while($true) # continuous whileloop 
{
    if(!(Test-Path $folderPath -ErrorAction SilentlyContinue )) # Make sure that the folder path is a valid folder. 
    {
        # Throw an error if the folder does not exist. 
        Write-Error -Message "The folder path cannot be found." -Category InvalidData 
        # Break out of the loop
        break;
    } # endif
    
    Write-Verbose "Number of Files in Folder: $((Get-ChildItem -Path $folderPath).Length)"

    # This is the script block that will be used to create the files
    # 25 files every 10 seconds
    # 1 file every .4 seconds
    $createFile_scriptBlock = {
        param ($path) # Parameter of where the files will be removed from.
        $index = 0 # This index is used to keep track of the files that are being created, so that they will not all be created in the first second. 
        while($true) # continuous loop
        {
            # Create a new GUID
            $fileGUI = [System.Guid]::NewGuid().Guid 
            # Create the file name with the GUID
            $fileName = "file__$fileGUI.txt"

            if($index -ge 25) # If the index is over 24 then we break, this ensures that only 25 files are created per 10 seconds. 
            {
                break;
            } # endif

            # Create the file
            New-Item -Name $fileName -Path $path -ItemType File 
            # Rest for .4 seconds before creating a new file. 
            Start-Sleep -Seconds .4
            # Add to the Index
            $index++
        } # endloop
    } # endscriptblock

    # This is the script block that will be used to delete the files 
    # 10 files every 10 seconds. ( 1 file per second )
    $deleteFile_scriptBlock = {
        param ($path) # Parameter of where the files will be removed from.
        $index = 0 # This index is used to keep track of the files that are being created, so that they will not all be removed in the first second. 
        while($true) # continuous loop
        {
            if($index -ge 10) # If the index is over 9 then break, this ensures that only 10 files are removed per 10 seconds
            {
                break;
            } # endif

            # Get the items in the folder, select the first one and remove it.
            Get-ChildItem -Path $path | Select -First 1 | Remove-Item 
            # Rest for 1 second before deleting another file
            Start-Sleep -Seconds 1 
            # Add to the index
            $index++ 
        } # endloop
    } # endscriptblock

    if(((Get-ChildItem -Path $folderPath).length -gt 100) -and ($createFiles -eq $true)) # check the number of files in the folder path and the $createFiles variable
    {
        Write-Verbose "Too many files. Stopping until 20 files are left."
        # If there is more than 99 files then we will stop creating files.
        $createFiles = $false
    } # endif

    if(((Get-ChildItem -Path $folderPath).length -lt 20) -and ($createFiles -eq $false)) # check the number of files in the folder path and the $createFiles variable
    {
        Write-Verbose "File count has fallen to 20 or under. Starting to create files again."
        # If there is less than 21 files then we'll start creating files again.
        $createFiles = $true
    } # endif

    if($createFiles) # Check if we should create more files.
    {
        Write-Verbose "Creating 25 files in 10 seconds."
        # Start a job to create 10 files on the given folder
        Start-Job -ScriptBlock $createFile_scriptBlock -ArgumentList $folderPath -Name "CreateFile" | Out-null
    } # endif
    
    Write-Verbose "Deleting 10 files in 10 seconds."
    # Start a job to delete 10 files from the given folder
    Start-job -ScriptBlock $deleteFile_scriptBlock -ArgumentList $folderPath -Name "DeleteFile"  | Out-null
    
    # Cleans out the jobs created.
    Write-Verbose "Cleaning out completed jobs."
    Get-Job | ? State -eq Completed | Remove-Job

    # Wait 10 seconds before looping.
    Start-Sleep -Seconds 10
} # endloop
