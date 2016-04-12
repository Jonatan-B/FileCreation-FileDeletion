# Global Variables
$folderPath = "C:\temp" # This variable needs to be the path where the files will be created.
$createFiles = $true # This variable is used to instantiation. Do not change.

if(!(Test-Path $folderPath -ErrorAction SilentlyContinue )) # Make sure that the folder path is a valid folder. 
{
    # Throw an error if the folder does not exist. 
    Write-Error -Message "The folder path cannot be found." -Category InvalidData 
    # Break out of the loop
    break;
} # endif

# This is the script block that will be used to create the files
$createFile_scriptBlock = {
    param ($path, $createFiles) # Parameter of where the files will be removed from.
        while($true) # continuous loop
        {
            # Create a new GUID
            $fileGUI = [System.Guid]::NewGuid().Guid 
            # Create the file name with the GUID
            $fileName = "file__$fileGUI.txt"

            if((Get-ChildItem -Path $path).Length -gt 100) # If there is more than 100 files
            {
                # Set variable to false
                $createFiles = $false
            } # endif

            if((Get-ChildItem -Path $path).Length -lt 20) # If there is less than 20 files
            {
                # Set variable to True
                $createFiles = $true
            } # endif

            if($createFiles) # If the boolean is true then we proceed to create a file.
            {
                # Create the file
                New-Item -Name $fileName -Path $path -ItemType File 
            } # endif

            # Rest for 350 milliseconds
            <# 
            # The reason it is 350 milliseconds and not 400 its because the actual work takes about 50 milliseconds. 
            # If you rest for 400 milliseconds then you'll have 22 files per 10 seconds, and if you rest for 300 you'll have 28 files per 10 seconds.
            # This might need to be tweaked depending on where the script is runned from. (Load, drive read/write speed, and other factors might affect it)
            #>
            Start-Sleep -Milliseconds 350
        } # endloop
} # endscriptblock

# This is the script block that will be used to delete the files 
$deleteFile_scriptBlock = {
    param ($path) # Parameter of where the files will be removed from.
    while($true) # continuous loop
    {
        # Get the items in the folder, select the first one and remove it.
        Get-ChildItem -Path $path | Select -First 1 | Remove-Item 

        # Rest for 1 second before deleting another file
        <# 
        # The reason it is 950 milliseconds and not 1000 its because the actual work takes about 50 milliseconds. 
        # If you rest for 1000 milliseconds then you'll only delete 9 files per 10 seconds, and if you set it to 900 then you'll delete 11 files per 10 seconds.
        # This might need to be tweaked depending on where the script is runned from. (Load, drive read/write speed, and other factors might affect it)
        #>
        Start-Sleep -Milliseconds 950
    } # endloop
} # endscriptblock

# Start a thread to create files
Start-Job -Name "FileCreator" -ScriptBlock $createFile_scriptBlock -ArgumentList $folderPath, $createFiles 
# Start a thread to delete files
Start-Job -Name "FileDeleter" -ScriptBlock $deleteFile_scriptBlock -ArgumentList $folderPath
