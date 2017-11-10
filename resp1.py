##########################################################################
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
staged_files=[f for f in staging_contents if '.xls' in f]
##### Get response processing config filename.
rspconfigname=gssconfig.loc['rspconfigname','Value']
##### Set rspconfig filename.
rspconfigfilename=staging_folder+os.path.sep+rspconfigname+'.txt'
##### Get contents of response processing config file.
rspconfig=pd.read_csv(rspconfigfilename,index_col=False,delimiter='\t')
##### Define name for processed folder.
processed_folder='Processed'
##### Define column names of rspconfig file.
file_col='Filename'; pswd_col='Password'
##### Display prompt.
print('\n***** Configuration File Contents Excluding Notes *****')
print(rspconfig.loc[:,file_col:pswd_col],'\n')
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
##########################################################################
##### Check existence and accessibility of response files.
##########################################################################
print('******************************************************')
print('***** Check Existence and Accessibility of Files *****')
print('******************************************************')
##### Loop through rows of rspconfig file.
for i in range(len(rspconfig)):
	##### Display prompt.
	print('Check Initiated for File %s of %s' % \
	(i+1,len(rspconfig)))		
	##### Find file to open based on info provided in rspconfig file.
	staged_file=[f for f in staged_files if rspconfig.loc[i][file_col]==f]
	##### Error handle if no matching filename found.
	if len(staged_file)==0:
		xlApp.Quit(); del xlApp
		sys.exit('\nException: No file with name matching '+ \
		rspconfig.loc[i][file_col]+' found in Staging folder\nExiting program')	
	##### Error handle if more than one matching filename found.
	elif len(staged_file)>1:
		xlApp.Quit(); del xlApp
		sys.exit('\nException: More than one file with name matching '+ \
		rspconfig.loc[i][file_col]+' found in Staging folder\nExiting program')		
	##### Get current password.
	password=rspconfig.loc[i][pswd_col]
	##### Error handle failure in opening excel workbook.
	try:
		xlwb=xlApp.Workbooks.Open(os.getcwd()+os.path.sep+staging_folder+ \
		os.path.sep+staged_file[0],False,True,None,password)
	except:
		e=sys.exc_info()[0]
		print('\nException: %s' % str(e))
		print('Exception encountered when attempting to open file '+ \
		'%s using password %s' % (staged_file[0],password))
		print('Exiting program')
		xlApp.Quit(); del xlApp
		sys.exit(1)
	##### Error handle failure in finding matching wave number.
	ticker=staged_file[0].split('_')[0]	
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
	(i+1,len(rspconfig),staged_file[0]))		
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
##### Loop through rows of rspconfig file.
for i in range(len(rspconfig)):
	##### Find file to open based on info provided in rspconfig file.
	staged_file=[f for f in staged_files if rspconfig.loc[i][file_col]==f]	
	##### Display prompt.	
	print('Processing Initiated for File %s of %s: %s' % \
	(i+1,len(rspconfig),staged_file[0]))	
	##### Get current password.
	password=rspconfig.loc[i][pswd_col]
	##### Specify excel file to open.
	stgfile=os.getcwd()+os.path.sep+staging_folder+ \
	os.path.sep+staged_file[0];
	##### Open staged file.  For parameter definitions see https://msdn.microsoft.com/en-us/library/microsoft.office.interop.excel.workbooks.open.aspx
	xlwb=xlApp.Workbooks.Open(stgfile,False,True,None,password)
	##### Open first worksheet by index.  For reference see https://msdn.microsoft.com/en-us/vba/excel-vba/articles/worksheets-object-excel
	ws=xlwb.Worksheets(1)	
	##### Set extraction range for month year.  For reference see https://stackoverflow.com/questions/15285068/from-password-protected-excel-file-to-pandas-dataframe
	StartRow=2; StartCol=1; EndRow=2; EndCol=1;	
	##### Get data content of specified range.
	content=ws.Range(ws.Cells(StartRow,StartCol), \
	ws.Cells(EndRow,EndCol)).Value
	##### Get month and year.
	month=content.split()[0]; year=content.split()[1];
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
	##### Get ticker symbol.
	ticker=staged_file[0].split('_')[0]
	##### Get wave number.
	wave=wavedf.loc[wavedf['TICKER']==ticker]['WAVE'].values[0]
	##### Loop through rows of response dataframe.
	for index,row in respdf.iterrows():
		##### Try inserting new primary key.
		try:
			##### Set SQL command to insert new primary key.
			cmd2exec='INSERT INTO '+resp_tablename+ \
			' (YEAR,MONTH,WAVE,TICKER,[CHECK],RESULT) VALUES ('+str(year)+',\''+ \
			month+'\','+str(wave)+',\''+ticker+'\','+str(index+1)+',\' \''+')'
			##### Execute SQL command to insert new primary key.
			cur.execute(cmd2exec)
			##### Set SQL command to store new record.
			cmd2exec='UPDATE '+resp_tablename+ \
			' SET RESULT=\''+respdf['RESULT'][index]+'\', RESPONSE=\''+ \
			str(respdf['RESPONSE'][index] or '')+'\', NOTES=\''+ \
			str(respdf['NOTES'][index] or '')+ \
			'\', CREATED_DT_GMT=CURRENT_TIMESTAMP, CREATED_ID=\''+ \
			gp.getuser().upper()+'\' WHERE YEAR='+str(year)+' AND MONTH=\''+ \
			month+'\' AND WAVE='+str(wave)+' AND TICKER=\''+ticker+ \
			'\' AND [CHECK]='+str(index+1)
			##### Execute SQL command to store new record.
			cur.execute(cmd2exec)			
		##### Update record if already exists.
		except sqlite3.IntegrityError:
			##### Set SQL command to update existing record.
			cmd2exec='UPDATE '+resp_tablename+ \
			' SET RESULT=\''+respdf['RESULT'][index]+'\', RESPONSE=\''+ \
			str(respdf['RESPONSE'][index] or '')+'\', NOTES=\''+ \
			str(respdf['NOTES'][index] or '')+ \
			'\', MODIFIED_DT_GMT=CURRENT_TIMESTAMP, MODIFIED_ID=\''+ \
			gp.getuser().upper()+'\' WHERE YEAR='+str(year)+' AND MONTH=\''+ \
			month+'\' AND WAVE='+str(wave)+' AND TICKER=\''+ticker+ \
			'\' AND [CHECK]='+str(index+1)
			##### Execute SQL command to update existing record.
			cur.execute(cmd2exec)
	##### Close excel workbook without saving.
	xlwb.Close(False)
	##### Set processed filename.
	stgfile_split=staged_file[0].split('.')
	stgfile_split.insert(1,time.strftime('_%Y%m%d_%H%M%S.'))
	procfile=os.getcwd()+os.path.sep+processed_folder+ \
	os.path.sep+''.join(stgfile_split)
	##### Move file from staging to processed folder.
	shutil.move(stgfile,procfile)
	##### Display prompt.
	print('Processing Completed - File moved to %s' % \
	(processed_folder+os.path.sep+''.join(stgfile_split)))
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
##### Set processed rspconfig file.
procrspconfigfilename=processed_folder+os.path.sep+rspconfigname+ \
time.strftime('_%Y%m%d_%H%M%S')+'.txt'
##### Copy file from staging to processed folder.
shutil.copy2(rspconfigfilename,procrspconfigfilename)
##### Display prompt.
printtxt='***** '+resp_tablename+' Table Update Completed *****'
print('\n'+len(printtxt)*"*"); print(printtxt); print(len(printtxt)*"*")
print('***** ',rspconfigfilename,'copied to',procrspconfigfilename)
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
