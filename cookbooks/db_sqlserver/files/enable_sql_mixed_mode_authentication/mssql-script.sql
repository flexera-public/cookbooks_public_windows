/* MSSQL Standard 2008 */
EXECUTE master..xp_regwrite 'HKEY_LOCAL_MACHINE','SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL10.MSSQLSERVER\MSSQLServer',N'LoginMode',N'REG_DWORD',2;

/* MSSQL Express 2008 */
EXECUTE master..xp_regwrite 'HKEY_LOCAL_MACHINE','SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL10.SQLEXPRESS\MSSQLServer',N'LoginMode',N'REG_DWORD',2;

/* MSSQL Standard & Express 2003 */
EXECUTE master..xp_regwrite 'HKEY_LOCAL_MACHINE','SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL.1\MSSQLServer',N'LoginMode',N'REG_DWORD',2;


return