# ===========================================================================
#  ISSM Toolkit - folder settings
#
#  Change the paths below to move where the toolkit saves records and looks
#  for update files. Every script reads this file (keep it in the same folder
#  as the scripts). Edit only the text inside the quotes.
#
#  A path given on the command line (e.g. -Root 'E:\Records') still overrides
#  this file for that one run.
#
#  This is a data-only file: the scripts read it with Import-PowerShellDataFile,
#  which only accepts plain values and never runs commands.
# ===========================================================================
# Start of the settings table (each line inside is: Name = 'value').
@{
    # Where all weekly records are saved: <RecordsRoot>\<Year>\<MM_Month>\WeekN_dd-dd\
    RecordsRoot = 'C:\ISSM_Records'

    # Where you put Defender update files (mpam-fe.exe, UpdatePlatform*.exe) before installing
    AVStaging   = 'C:\ISSM_Staging\AV'

    # Where you put Windows update files (.msu / .cab) before installing
    OSStaging   = 'C:\ISSM_Staging\OS'
}
# End of the settings table.
