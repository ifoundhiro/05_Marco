@echo off 
REM User: Hirotaka Miura (B1HXM10).               
REM	Position: Research Analytics Associate.         
REM	Organization: Federal Reserve Bank of New York.
REM 09/18/2017: Modified.
REM	09/11/2017: Previously modified.
REM	09/11/2017: Created.
REM	Description: 
REM		- Windows batch file to execute specified program.REM	Modifications:
REM		09/11/2017:
REM			- Duplicated from etl.py.cmd.
REM		09/18/2017:
REM			- Program filename changed from 'update_response_database.py.cmd' 
REM				to 'UPDATE_RESPONSE_TABLE.py.cmd.'
REM			- Update python program filename.

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

