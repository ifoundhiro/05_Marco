##### Import modules.
import getpass as gp			##### For username.
import os									##### For operating system functions.
import platform as plf		##### For hostname.
import sys								##### For system functions.
import time								##### For time functions.
import pandas as pd				##### For dataframes.
import sqlite3						##### For SQLite.
import win32com.client		##### For accessing excel.
import shutil							##### For renaming and moving files.
##########################################################################
##### Display system information.
##########################################################################
print('************************************************')
print('***** 2052a Validation Response Processing *****')
print('***************** Release 1.1 ******************')
print('************************************************')
print('\n******************************')
print('***** System Information *****')
print('******************************')
print('***** User:              '+gp.getuser().upper())
print('***** Python version:    '+sys.version)
print('***** Hostname:          '+plf.node())
print('***** Working directory: '+os.getcwd())
print('***** Program name:      '+os.path.basename(__file__))
print('***** Datetime:          '+time.strftime("%Y-%m-%d %H:%M:%S"))
##########################################################################
##### Initial setup.
##########################################################################
##### Set GSS config filename.
gssconfigname='gssconfig'
##### Read-in GSS config file.
gssconfig=pd.read_csv(gssconfigname+'.txt',index_col=False,delimiter='\t')
##### Set index of dataframe.
gssconfig=gssconfig.set_index('Parameter')
##### Get location of staging folder.
staging_folder=gssconfig.loc['stagingdir','Value']
##### Get all contents in staging folder. 
staging_contents=os.listdir(staging_folder)
##### Get all excel files in staging folder.
staged_files=[f for f in staging_contents if '.xls' in f.lower()]
##### Display prompt.
print('\n******************************')
print('***** Staged Excel Files *****')
print('******************************')
print('\n'.join(staged_files))
##### Define name for processed folder.
processed_folder='Processed'
##### Generate processed folder if not exist.
if not os.path.exists(processed_folder): os.makedirs(processed_folder)
##### Set SQLite database name.
sqlitefile='RESPONSE_DATABASE.sqlite'
##### Establish connection to SQLite file.
conn=sqlite3.connect(sqlitefile)
##### Get pointer to SQLite file cursor.
cur=conn.cursor()
##### Set table name containing wave composition data.
wave_tablename='WAVE'
##### Extract wave composition data from SQLite.
wavedf=pd.read_sql_query('SELECT * FROM '+wave_tablename+';',conn)
##### Invoke excel application instance.	
xlApp=win32com.client.Dispatch("Excel.Application")
##### Set table name used to hold response data.
resp_tablename='RESPONSE'
##### Set password to blank for all response file(s).
xlpswd=''
##########################################################################
##### Check existence and accessibility of response files.
##########################################################################
print('\n******************************************************')
print('***** Check Existence and Accessibility of Files *****')
print('******************************************************')
##### Loop through staged files.
for i,staged_file in enumerate(staged_files):
	##### Display prompt.	
	print('Check Initiated for File %s of %s: %s' % \
	(i+1,len(staged_files),staged_file))	
	##### Error handle failure in opening excel workbook.
	try:
		xlwb=xlApp.Workbooks.Open(os.getcwd()+os.path.sep+staging_folder+ \
		os.path.sep+staged_file,False,True,None,xlpswd)
	except:
		e=sys.exc_info()[0]
		print('\nException: %s' % str(e))
		print('Exception encountered when attempting to open file '+ \
		'%s' % (staged_file))
		print('Check if file password protected')
		print('Exiting program')
		xlApp.Quit(); del xlApp
		sys.exit(1)
	##### Obtain ticker symbol.  First look within excel then filename.
	##### Any exit will occur in following error handling procedure. 
	ws=xlwb.Worksheets(1)	
	StartRow=2; StartCol=1; EndRow=2; EndCol=1;
	content=ws.Range(ws.Cells(StartRow,StartCol), \
	ws.Cells(EndRow,EndCol)).Value
	try:
		ticker=content.split()[2]
	except IndexError:
		ticker=staged_file.split('_')[0]	
	##### Error handle failure in finding matching wave number.	
	try:
		wavedf.loc[wavedf['TICKER']==ticker]['WAVE'].values[0]
	except:
		e=sys.exc_info()[0]
		print('\nException: %s' % str(e))
		print('Exception encountered when attempting to find matching '+ \
		'wave number for ticker %s' % (ticker))
		print('Exiting program')	
		xlwb.Close(False); xlApp.Quit(); del xlApp
		sys.exit(1)
	##### Close excel workbook without saving.
	xlwb.Close(False)
	##### Display prompt.
	print('Check Completed for File %s of %s: %s' % \
	(i+1,len(staged_files),staged_file))		
##########################################################################
##### Generate backup of existing response database.
##########################################################################
##### Backup Response database if exists.
if os.path.isfile(sqlitefile):
	##### Get filename.
	sqlitefilename=sqlitefile.replace('.sqlite','')
	##### Generate backup folder if not exist.
	bkfldr='Backup/'+sqlitefilename
	if not os.path.exists(bkfldr): os.makedirs(bkfldr)	
	##### Define backup filename.
	bkfile=bkfldr+'/'+sqlitefilename+time.strftime('_%Y%m%d_%H%M%S')+ \
	'.sqlite'
	##### Backup database.
	shutil.copyfile(sqlitefile,bkfile)
	print('\n***** '+sqlitefile+' Backed Up *****')
	print('Backup location: '+bkfile)	
##########################################################################
##### Process response files.
##########################################################################	
print('\n*************************')
print('***** Process Files *****')
print('*************************')
##### Loop through staged files.
for i,staged_file in enumerate(staged_files):
	##### Display prompt.	
	print('Processing Initiated for File %s of %s: %s' % \
	(i+1,len(staged_files),staged_file))	
	##### Specify excel file to open.
	stgfile=os.getcwd()+os.path.sep+staging_folder+ \
	os.path.sep+staged_file;
	##### Open staged file.  For parameter definitions see https://msdn.microsoft.com/en-us/library/microsoft.office.interop.excel.workbooks.open.aspx
	xlwb=xlApp.Workbooks.Open(stgfile,False,True,None,xlpswd)
	##### Open first worksheet by index.  For reference see https://msdn.microsoft.com/en-us/vba/excel-vba/articles/worksheets-object-excel
	ws=xlwb.Worksheets(1)	
	##### Set extraction range for month year.  For reference see https://stackoverflow.com/questions/15285068/from-password-protected-excel-file-to-pandas-dataframe
	StartRow=2; StartCol=1; EndRow=2; EndCol=1;	
	##### Get data content of specified range.
	content=ws.Range(ws.Cells(StartRow,StartCol), \
	ws.Cells(EndRow,EndCol)).Value
	##### Get month and year.
	month=content.split()[0]; year=content.split()[1];
	##### Get ticker symbol.  First look within excel then filename.
	try:
		ticker=content.split()[2]
	except IndexError:
		ticker=staged_file.split('_')[0]		
	##### Set extraction range for response data.
	StartRow=3; StartCol=2; EndRow=5; EndCol=15;
	##### Get data content of specified range.
	content=ws.Range(ws.Cells(StartRow,StartCol), \
	ws.Cells(EndRow,EndCol)).Value
	##### Transfer content to pandas dataframe.
	respdf=pd.DataFrame(list(content))	
	##### Transpose dataframe.
	respdf=respdf.transpose()
	##### Name columns.
	respdf.columns=['RESULT','RESPONSE','NOTES']
	##### Get wave number.
	wave=wavedf.loc[wavedf['TICKER']==ticker]['WAVE'].values[0]
	##### Loop through rows of response dataframe.
	for index,row in respdf.iterrows():
		##### Set operation type.
		optype='CREATED'
		######################################################################
		##### Attempt insertion of new primary key.
		######################################################################
		try:
			##### Set first part of insert command.
			qryprt1='INSERT INTO '+resp_tablename+ \
			' (YEAR,MONTH,WAVE,TICKER,[CHECK],RESULT) VALUES (?,?,?,?,?,?)'
			##### Set second part of insert command.
			qryprt2=(str(year),month,str(wave),ticker,str(index+1),'')
			##### Execute SQL operation.
			cur.execute(qryprt1,qryprt2)
		##### Switch operation type to modify if record already exists.
		except sqlite3.IntegrityError:
			optype='MODIFIED'
		####################################################################
		##### Update record with values.
		####################################################################	
		##### Set first part of update command.
		qryprt1='UPDATE '+resp_tablename+' SET'+ \
		' RESULT=?,'+ \
		' RESPONSE=?,'+ \
		' NOTES=?,'+ \
		' '+optype+'_DT_GMT=?,'+ \
		' '+optype+'_ID=?'+ \
		' WHERE YEAR=? AND MONTH=? AND WAVE=? AND TICKER=? AND [CHECK]=?'
		##### Set second part of update command.
		qryprt2=( \
		respdf['RESULT'][index], \
		respdf['RESPONSE'][index], \
		respdf['NOTES'][index], \
		time.strftime("%Y-%m-%d %H:%M:%S",time.gmtime()), 
		gp.getuser().upper(), \
		str(year),month,str(wave),ticker,str(index+1))
		##### Execute SQL operation.
		cur.execute(qryprt1,qryprt2)		
	##### Close excel workbook without saving.
	xlwb.Close(False)
	##### Set processed filename.
	stgfile_split=staged_file.split('.')
	stgfile_split.insert(1,time.strftime('_%Y%m%d_%H%M%S.'))
	procfile=os.getcwd()+os.path.sep+processed_folder+ \
	os.path.sep+''.join(stgfile_split)
	##### Move file from staging to processed folder.
	shutil.move(stgfile,procfile)
	##### Display prompt.
	print('Processing Completed for File %s of %s: %s' % \
	(i+1,len(staged_files),staged_file))	
##########################################################################
##### Wrap-up and clean-up.
##########################################################################
##### Close out excel application instance.
xlApp.Quit()
##### End excel process.
del xlApp
##### Close cursor.
cur.close()
##### Commit changes.
conn.commit()
##### Close connection.
conn.close()
##### Display prompt.
printtxt='***** '+resp_tablename+' Table Update Completed *****'
print('\n'+len(printtxt)*"*"); print(printtxt); print(len(printtxt)*"*")
##########################################################################
##### Display system information.
##########################################################################
print('\n******************************')
print('***** System Information *****')
print('******************************')
print('***** User:              '+gp.getuser().upper())
print('***** Python version:    '+sys.version)
print('***** Hostname:          '+plf.node())
print('***** Working directory: '+os.getcwd())
print('***** Program name:      '+os.path.basename(__file__))
print('***** Datetime:          '+time.strftime("%Y-%m-%d %H:%M:%S"))
