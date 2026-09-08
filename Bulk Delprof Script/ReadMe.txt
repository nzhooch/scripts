The powershell script "Bulk_Delprof2.ps1" is designed to filter through a list of given device asset numbers and will test if the device is online before running Delprof2 to delete unused profiles.

How to use:
 1 - Edit the "Asets.txt" file and save a list of asset numbers to run Delprof2 on.
    Note: Please make sure the first part of each line is the asset number, the script will ignore anything after the first space.
    Note: Please limit the "Assets.txt" file to 30 assets as it might struggle processing more.

 2 - Right click "Bulk_Delprof2.ps1" and select "Run with Powershell".
    Note: Please make sure you are running Powershell version 5.1 as other versions may cause the script to error.

 3 - Wait for the script to finnish running. A new window will open for each device that runs Delprof2.
    Note: There will be a user prompt at the end of each window once the relevant script finishes.

 4 - You can then check the created log file to see which devices were offline, and which ones attempted to run Delprof2.
    Note: The logs are saved using the date and time the script was run.



The powershell script "Diskspace_Check.ps1" is designed to filter through a list of given device asset numbers and will test if the device is online before attempting to retreive the device's free disk space and write it to a log file.

How to use:
 1 - Edit the "Asets.txt" file and save a list of asset numbers to check.
    Note: Please make sure the first part of each line is the asset number, the script will ignore anything after the first space.

 2 - Right click "Diskspace_Check.ps1" and select "Run with Powershell".
    Note: Please make sure you are running Powershell version 5.1 as other versions may cause the script to error.

 3 - Wait for the script to finnish running.
    Note: There will be a user prompt at the end once the script finishes.

 4 - You can then check the created log file to see the results.
    Note: The logs are saved using the date and time the script was run.
