<#
	.SYNOPSIS
		Adds a method to refresh Windows objects without having to restart the Explorer process.

	.DESCRIPTION
		This method uses a Win32 API to notify the system of any events that affect the shell and then flushes the system event buffer.
		This method does not issue an Explorer process restart because the system event buffer is flushed in the running environment using the Win32 API.
		This method also refreshes system objects, like changed or modified registry keys, that normally require a system reboot.
		This method is useful for quickly refreshing the desktop, taskbar, icons, wallpaper, files, environmental variables and/or visual environment.

	.EXAMPLE
		PS C:\> .\Refresh-Explorer.ps1
#>

## Add the PowerShell C# wrapper script to the C:\Windows directory.
@"
Add-Type @'
    using System;
    using System.Runtime.InteropServices;

    namespace Win32API
    {
        public class Explorer
        {
            private static readonly IntPtr HWND_BROADCAST = new IntPtr(0xffff);
            private const int WM_SETTINGCHANGE = 0x1a;
            private const int SMTO_ABORTIFHUNG = 0x0002;
            [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
            static extern bool SendNotifyMessage(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam);
            [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
            private static extern IntPtr SendMessageTimeout(IntPtr hWnd, int Msg, IntPtr wParam, string lParam, int fuFlags, int uTimeout, IntPtr lpdwResult);
            [DllImport("shell32.dll", CharSet = CharSet.Auto, SetLastError = false)]
            private static extern int SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);
            public static void Refresh()
            {
                SHChangeNotify(0x8000000, 0x1000, IntPtr.Zero, IntPtr.Zero);
                SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, IntPtr.Zero, "Environment", SMTO_ABORTIFHUNG, 100, IntPtr.Zero);
                SendNotifyMessage(HWND_BROADCAST, WM_SETTINGCHANGE, IntPtr.Zero, "TraySettings");
            }
        }
    }
'@
[Win32API.Explorer]::Refresh()
"@ | Out-File -FilePath "$Env:SystemRoot\Refresh-Explorer.ps1" -Encoding UTF8 -Force

## Create the necessary registry keys and properties to add 'Refresh Explorer' to the context menu.
New-Item -Path "HKLM:\SOFTWARE\Classes\DesktopBackground\shell\Refresh Explorer" -ItemType Directory -Force
New-Item -Path "HKLM:\SOFTWARE\Classes\DesktopBackground\shell\Refresh Explorer\command" -ItemType Directory -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\DesktopBackground\shell\Refresh Explorer" -Name "Icon" -Value "Explorer.exe" -PropertyType String -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\DesktopBackground\shell\Refresh Explorer" -Name "Position" -Value "Bottom" -PropertyType String -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\DesktopBackground\shell\Refresh Explorer\command" -Name "(default)" -Value "PowerShell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$Env:SystemRoot\Refresh-Explorer.ps1`"" -PropertyType String -Force