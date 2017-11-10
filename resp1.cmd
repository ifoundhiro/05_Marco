@echo off 

REM Set variables.
SET prog=UPDATE_RESPONSE_TABLE.py
REM Obtain date and time (24-hour format).
REM Refer to https://stackoverflow.com/questions/203090.
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
For /f "tokens=1-3 delims=/:" %%a in ("%TIME%") do (set mytime=%%a%%b%%c)
REM Replace empty spaces with zeros. 
REM Refer to http://stackoverflow.com/a/23558738/1879699,
set mytime=%mytime: =0%
REM Extract hours, minutes, and seconds.
set mytime=%mytime:~0,6%
REM Set directory path where log files are to be kept.
set logpath="%cd%\Log"
REM Generate folder if not exist, otherwise redirect warning.
mkdir %logpath% > nul 2> nul
REM Set log file path.
set logfilepath=%logpath%\%prog%_%mydate%_%mytime%.log
REM Execute specified program.
REM Make sure path to executable set in environmental variable.
python %prog% 1> %logfilepath% 2>&1

