Function Import-RegistryTemplates
{
    [CmdletBinding()]
    Param ()

    Begin
    {
        Get-ChildItem -Path (Join-Path -Path $AdditionalPath -ChildPath RegistryTemplates) -Filter *_Offline.reg -Recurse | Purge
        Get-ChildItem -Path (Join-Path -Path $AdditionalPath -ChildPath RegistryTemplates) -Filter *.reg -Recurse | ForEach-Object -Process {
            $REGContent = Get-Content -Path $($_.FullName)
            $REGContent = $REGContent -replace 'HKEY_LOCAL_MACHINE\\SOFTWARE', 'HKEY_LOCAL_MACHINE\WIM_HKLM_SOFTWARE'
            $REGContent = $REGContent -replace 'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet', 'HKEY_LOCAL_MACHINE\WIM_HKLM_SYSTEM\ControlSet001'
            $REGContent = $REGContent -replace 'HKEY_LOCAL_MACHINE\\SYSTEM', 'HKEY_LOCAL_MACHINE\WIM_HKLM_SYSTEM'
            $REGContent = $REGContent -replace 'HKEY_CLASSES_ROOT', 'HKEY_LOCAL_MACHINE\WIM_HKLM_SOFTWARE\Classes'
            $REGContent = $REGContent -replace 'HKEY_CURRENT_USER', 'HKEY_LOCAL_MACHINE\WIM_HKCU'
            $REGContent = $REGContent -replace 'HKEY_USERS\\.DEFAULT', 'HKEY_LOCAL_MACHINE\WIM_HKU_DEFAULT'
            $REGContent | Set-Content -Path "$($_.FullName.Replace('.reg', '_Offline.reg'))" -Encoding Unicode -Force
        }
        $Templates = Get-ChildItem -Path (Join-Path -Path $AdditionalPath -ChildPath RegistryTemplates) -Filter *_Offline.reg -Recurse | Select-Object -Property Name, BaseName, Extension, Directory, FullName
        $RegLog = Join-Path -Path $LogDirectory -ChildPath Registry-Optimizations.log
        RegHives -Load
    }
    Process
    {
        ForEach ($Template In $Templates)
        {
            Write-Output ('Importing Registry Template: "{0}"' -f $($Template.BaseName.Replace('_Offline', $null))) >> $RegLog
            $RET = RunExe $REGEDIT -Arguments ('/S "{0}"' -f $Template.FullName)
            If ($RET -ne 0) { Log -Error ('Failed to Import Registry Template: "{0}"' -f $($Template.BaseName.Replace('_Offline', $null))) }
            $Template.FullName | Purge
        }
    }
    End
    {
        RegHives -Unload
    }
}