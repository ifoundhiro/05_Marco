@echo off 

REM Obtain date and time (24-hour format).
REM Refer to https://stackoverflow.com/questions/203090.
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a%%b)

REM Replace empty spaces with zeros. 
REM Refer to http://stackoverflow.com/a/23558738/1879699,
set mytime=%mytime: =0%

REM Set destination path variable.
set dpath=Backup\%mydate%_%mytime%

REM Copies files, generating new directory if needed.
REM See https://technet.microsoft.com/en-us/library/bb491035.aspx
xcopy *.* %dpath% /i 