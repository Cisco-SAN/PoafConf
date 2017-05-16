:: Check for Python Installation
:: http://stackoverflow.com/questions/13310221/shell-scripting-checking-python-version
::http://www.xinotes.net/notes/note/1459/
python --version 2>NUL

if errorlevel 1 goto errorNoPython

:: Reaching here means Python is installed.
:: Execute stuff...
echo Python installed now run the python file
python --version
start c:\python27\python indexWin.py

:: Once done, exit the batch file -- skips executing the errorNoPython section
goto:eof

:errorNoPython
echo.
echo Error^: Python not installed, First install python then proceed with this file
start iexplore https://www.python.org/downloads/release/python-2713/

pause