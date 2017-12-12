@echo off
cd %~dp0
cls
if not exist "%~dp0NetCheck.bat" (
ren "%~f0" NetCheck.bat
timeout /nobreak /t 2 >nul
call "%~dp0NetCheck.bat"
)
mkdir NClogs > NUL

cls

set address=www.google.com
::set address=10.150.0.1


call :getTime
set logfile=LOG_%time:~0,2%%time:~3,2% %day% %month% %year%.txt

<nul set /p ".=NetCheck is loading.  Please wait"

:checkForFiles
if not exist invisible.vbs (
echo CreateObject^("Wscript.Shell"^).Run """" ^& WScript.Arguments^(0^) ^& """", 0, False > invisible.vbs
<nul set /p .=.
timeout /nobreak /t 1 >nul
)
REM Search for powershellBypass

if not exist powershellBypass.bat (
echo @echo off > powershellBypass.bat
echo cls >> powershellBypass.bat
echo ^:CheckPrivileges >> powershellBypass.bat
echo NET FILE 1^>NUL 2^>NUL >> powershellBypass.bat
echo if '%%errorlevel%%' == '0' ^( goto gotPrivileges ^) else ^( goto getPrivileges ^) >> powershellBypass.bat 
echo. >> powershellBypass.bat
echo ^:getPrivileges >> powershellBypass.bat 
echo if '%%1'=='ELEV' ^(shift ^& goto gotPrivileges^) >> powershellBypass.bat 
ECHO echo. >> powershellBypass.bat 
echo ECHO ************************************************************** >> powershellBypass.bat 
echo ECHO This program requires admin permission to enable popups >> powershellBypass.bat 
echo ECHO ************************************************************** >> powershellBypass.bat 
echo. >> powershellBypass.bat 
echo setlocal DisableDelayedExpansion >> powershellBypass.bat 
echo set "batchPath=%%~0" >> powershellBypass.bat 
echo setlocal EnableDelayedExpansion >> powershellBypass.bat 
echo ECHO Set UAC = CreateObject^("Shell.Application"^) ^> "%%temp%%\OEgetPrivileges.vbs" >> powershellBypass.bat 
echo ECHO UAC.ShellExecute "!batchPath!", "ELEV", "", "runas", 1 ^>^> "%%temp%%\OEgetPrivileges.vbs" >> powershellBypass.bat 
echo "%%temp%%\OEgetPrivileges.vbs" >> powershellBypass.bat 
echo exit /B >> powershellBypass.bat 
echo. >> powershellBypass.bat 
echo ^:gotPrivileges >> powershellBypass.bat 
echo ^:START >> powershellBypass.bat
echo setlocal ^& pushd . >> powershellBypass.bat
echo. >> powershellBypass.bat
echo powershell -command set-executionpolicy bypass >> powershellBypass.bat
<nul set /p .=.
timeout /nobreak /t 1 >nul

)
REM Check for start

if not exist start.bat (
echo @echo off > start.bat
echo if exist temp.ps1 del /f /q temp.ps1 >> start.bat
echo for /f "delims=" %%%%A in ^('powershell -command get-executionpolicy'^) do ^( >> start.bat
echo 	set "GECP=%%%%A">> start.bat
echo ^) >> start.bat
echo echo Your current execution policy is: %%GECP%% >> start.bat
echo if not "%%GECP%%"=="Bypass" ^( >> start.bat
echo 	call "powershellBypass.bat" >> start.bat
echo ^) >> start.bat
echo. >> start.bat
echo cls >> start.bat
echo cd %%~dp0 >> start.bat
echo cls >> start.bat
echo wscript.exe "invisible.vbs" "NetCheck.bat" >> start.bat
echo cls >> start.bat
echo exit >> start.bat
<nul set /p .=.
timeout /nobreak /t 1 >nul
start start.bat
exit
)



mode con:cols=40 lines=5
set /A change = 2
echo new log started: %dtg% >> "%~dp0\NClogs\%logfile%"
:main
cls


title monitoring Network Connectivity
timeout /nobreak /t 2>nul
del /Q "%~dp0invisible.vbs"
del /Q "%~dp0powershellBypass.bat"
del /Q "%~dp0start.bat"


REM CREATE Script to kill this process
rem Note: Session Name for privileged Administrative consoles is sometimes blank.
if not defined SESSIONNAME set SESSIONNAME=Console

setlocal

rem Instance Set
set instance=%DATE% %TIME% %RANDOM%
::echo Instance: "%instance%"
title %instance%

rem PID Find
for /f "usebackq tokens=2" %%a in (`tasklist /FO list /FI "SESSIONNAME eq %SESSIONNAME%" /FI "USERNAME eq %USERNAME%" /FI "WINDOWTITLE eq %instance%" ^| find /i "PID:"`) do set PID=%%a
if not defined PID for /f "usebackq tokens=2" %%a in (`tasklist /FO list /FI "SESSIONNAME eq %SESSIONNAME%" /FI "USERNAME eq %USERNAME%" /FI "WINDOWTITLE eq Administrator:  %instance%" ^| find /i "PID:"`) do set PID=%%a
if not defined PID echo !Error: Could not determine the Process ID of the current script.  Exiting.& exit /b 1

cd %~dp0
echo taskkill /pid %pid% > kill.bat
echo del "%%~f0" >> kill.bat
endlocal



:start
ping %address% -w 2000 -n 1 | FIND "TTL" > nul
IF NOT ERRORLEVEL 1 (
	if %change% == 2 (
REM verify it's up
timeout /nobreak /t 10 > nul
		ping %address% -w 5000 -n 1 | FIND "TTL" > nul
		IF NOT ERRORLEVEL 1 (
		set state=up
		set /a change = 1
		call :log
		call :message
		)
	)
cls
color 2
echo Ping Successful!
) else (
if %change% == 1 (
REM verify it's down
timeout /nobreak /t 10 > nul
	ping %address% -w 5000 -n 1 | FIND "TTL" > nul
	IF ERRORLEVEL 1 (
		set state=down
		set /a change = 2
		call :log
		call :message
		) else (

			timeout 2 > nul
			color
			goto start
		)
	
)
cls
color 4
echo Ping Failed!
)
timeout /nobreak /t 2 > nul
color
goto start

:message
echo [System.Reflection.Assembly]::LoadWithPartialName^("System.Windows.Forms"^) ^| out-null > "temp.ps1"
echo [System.Reflection.Assembly]::LoadWithPartialName^("System.Drawing"^) ^| out-null >> "temp.ps1"
echo $Balloon = new-object System.Windows.Forms.NotifyIcon >> "temp.ps1"
echo $Balloon.Icon = [System.Drawing.SystemIcons]::WinLogo >> "temp.ps1"
echo $Balloon.Visible = $true; >> "temp.ps1"
echo $Balloon.ShowBalloonTip^(1, "Network", "Network changed state to %state%", "None"^); >> "temp.ps1"
echo. >> "temp.ps1"
echo Unregister-Event -SourceIdentifier click_event -ErrorAction SilentlyContinue >> "temp.ps1"
echo Register-ObjectEvent $Balloon BalloonTipClicked -sourceIdentifier click_event -Action { >> "temp.ps1"
echo. >> "temp.ps1"

REM THIS NAVIGATES TO A WEBSITE ON CLICK
echo $ie = New-Object -com InternetExplorer.Application >> "temp.ps1"
echo #$ie.navigate2^("https://intranet.mydomain.com"^) >> "temp.ps1"

echo $ie.visible = $true >> "temp.ps1"
echo. >> "temp.ps1"
echo } ^| Out-Null >> "temp.ps1"
echo. >> "temp.ps1"
echo Wait-Event -timeout 5 -sourceIdentifier click_event > $null >> "temp.ps1"
echo Remove-Event click_event -ea SilentlyContinue >> "temp.ps1"
echo Unregister-Event -SourceIdentifier click_event -ErrorAction SilentlyContinue >> "temp.ps1"
echo $Balloon.Dispose^(^) >> "temp.ps1"

powershell -file temp.ps1 >nul
del temp.ps1 >nul
exit /b

:log
call :getTime
echo. >> "%~dp0\NClogs\%logfile%"
echo %address% %state%: %dtg% >> "%~dp0\NClogs\%logfile%"
exit /b

:getTime
set year=%date:~-4,4%
set month=%date:~-10,2%
set day=%date:~-7,2%
set clock=%time:~0,3%%time:~3,2%
if %day%==01 set day=1
if %day%==02 set day=2
if %day%==03 set day=3
if %day%==04 set day=4
if %day%==05 set day=5
if %day%==06 set day=6
if %day%==07 set day=7
if %day%==08 set day=8
if %day%==09 set day=9
if %month%==01 set month=Jan
if %month%==02 set month=Feb
if %month%==03 set month=March
if %month%==04 set month=April
if %month%==05 set month=May
if %month%==06 set month=June
if %month%==07 set month=July
if %month%==08 set month=Aug
if %month%==09 set month=Sep
if %month%==10 set month=Oct
if %month%==11 set month=Nov
if %month%==12 set month=Dec
set dtg=%clock% %day% %month% %year%
exit /b