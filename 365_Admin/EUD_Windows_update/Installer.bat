@echo off
setlocal

:: Define paths and URLs
set "scriptUrl=https://raw.githubusercontent.com/DigitalSafety/Powershell/refs/heads/main/365_Admin/EUD_Windows_update/CourseCleanUp.ps1"
set "iconUrl=https://raw.githubusercontent.com/DigitalSafety/Powershell/refs/heads/main/365_Admin/EUD_Windows_update/Uiconstock-Flat-Halloween-Halloween-Broom-Brush.ico"
set "programsFolder=C:\Program Files\CourseCleanup"
set "scriptPath=%programsFolder%\CourseCleanUp.ps1"
set "iconPath=%programsFolder%\CourseCleanUp.ico"
set "desktopShortcut=%userprofile%\Desktop\CourseCleanUp.lnk"

:: Create the Programs folder if it doesn't exist
if not exist "%programsFolder%" (
    mkdir "%programsFolder%"
)

:: Download the PowerShell script
echo Downloading PowerShell script...
powershell -Command "Invoke-WebRequest -Uri '%scriptUrl%' -OutFile '%scriptPath%'"
if %ERRORLEVEL% neq 0 (
    echo Failed to download PowerShell script.
    exit /b 1
)

:: Download the icon file
echo Downloading icon file...
powershell -Command "Invoke-WebRequest -Uri '%iconUrl%' -OutFile '%iconPath%'"
if %ERRORLEVEL% neq 0 (
    echo Failed to download icon file.
    exit /b 1
)

:: Create a desktop shortcut to the script
echo Creating desktop shortcut...
powershell -Command "$WScriptShell = New-Object -ComObject WScript.Shell; $Shortcut = $WScriptShell.CreateShortcut('%desktopShortcut%'); $Shortcut.TargetPath = 'powershell.exe'; $Shortcut.Arguments = '-ExecutionPolicy Bypass -File \"%scriptPath%\"'; $Shortcut.IconLocation = '%iconPath%'; $Shortcut.Save()"
if %ERRORLEVEL% neq 0 (
    echo Failed to create desktop shortcut.
    exit /b 1
)

echo Script completed successfully.
exit /b 0
