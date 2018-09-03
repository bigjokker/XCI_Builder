@echo off
title XCI_BUILDER v0.6.5.2  by julesontheroad
setlocal enabledelayedexpansion
color 03

::XCI_Builder v0.6.5.2 by julesontheroad::
::A batch file made to automate nsp to xci files conversion via hacbuild
::XCI_Builder serves as a workflow helper for hacbuild, hactool and nspbuild
::Just drag and drop. Drag a nsp file into XCI_Builder .bat and it'll take care of everything
::hacbuild made by LucaFraga https://github.com/LucaFraga/hacbuild
::hactool made by SciresM https://github.com/SciresM/hactool
::nspBuild made by CVFireDragon https://github.com/CVFireDragon/nspBuild

::Requirements at least NETFramework=v4.5.2
::hacbuild  needs python 2/3 installed in the system 
::nspBuild needs python 2/3 installed in the system 

::Thx to my friends from elotrolado.net and gbatemp

::Set options preset
::OPTION 1 - "preservemanual"
::In case the nsp have a manual nca it will be saved to output folder
::Don't install it as it will cause issues in your switch, it's meant for and
::xci debuilder that will be able to restore nsp to original conditions
::by default=0
::OPTION 2 - "delete_brack_tags"
::Delete bracket tags like [trimmed] by default 1
::OPTION 3 - "delete_pa_tags"
::Delete parenthesis tags like (USA) by default 0, if activated it may also erase [] tags
set /a preservemanual=0
set /a delete_brack_tags=1
set /a delete_pa_tags=0

::check for keys.txt
if not exist "%~dp0\ztools\keys.txt" echo Keys.txt needs to be in ztools folder
echo.
if not exist "%~dp0\ztools\keys.txt" pause
if not exist "%~dp0\ztools\keys.txt" exit

::Set working folder and file
set file=%~n1
FOR %%i IN ("%file%") DO (
set filename=%%~ni
)
CD /d "%~dp0"


::check if Python 2.7 is availible to run nspBuild.py
where python.exe> "ztools\python.txt"
FINDSTR "Python27" "ztools\python.txt">nul 2>&1
if %ERRORLEVEL%==1 echo Python 2.7 needs to be installed to build "GameTitle[lc].nsp"
if %ERRORLEVEL%==1 echo.
if %ERRORLEVEL%==1 pause
del "ztools\python.txt"

if "%~x1"==".nsp" (goto nsp)
if "%~x1"==".xci" (goto xci)
echo XCI_Builder v0.6.5.2 by julesontheroad
echo.
echo A batch file made to automate nsp to xci files conversion via hacbuild
echo.
echo Just drag and drop. Drag a nsp file into XCI_Builder .bat and it'll take care of everything
echo.
echo XCI_Builder's author is not responsible for any problems that may occur in your system
echo.
echo hacbuild made by LucaFraga https://github.com/LucaFraga/hacbuild
echo.
echo hactool made by SciresM https://github.com/SciresM/hactool
echo.
echo nspBuild made by CVFireDragon https://github.com/CVFireDragon/nspBuild
echo.
pause
exit


:xci
MD game_info
if exist "game_info\!filename!.ini" del "game_info\!filename!.ini"
"ztools\hacbuild.exe" read xci "%~1"
move  "!filename!.ini"  "game_info\" >nul 2>&1
echo.
echo : : XCI Cart Info in "game_info" folder
echo.
pause
exit

:nsp
if exist "%~dp0\nspDecrypted\" rmdir /s /q "%~dp0\nspDecrypted\"
MD nspDecrypted

:: If activated remove identifiers [] or () in filename.
if exist nspDecrypted\*.txt del nspDecrypted\*.txt
echo %filename%>nspDecrypted\fname.txt

if !delete_brack_tags! EQU 1 goto deletebrackets
goto notdeletebrackets
:deletebrackets
for /f "tokens=1* delims=[" %%a in (nspDecrypted\fname.txt) do (
    set filename=%%a)
echo %filename%>nspDecrypted\fname.txt
:notdeletebrackets
if !delete_pa_tags! EQU 1 goto deleteparenthesis
goto notdeleteparenthesis
:deleteparenthesis
for /f "tokens=1* delims=(" %%a in (nspDecrypted\fname.txt) do (
    set filename=%%a)
echo %filename%>nspDecrypted\fname.txt
:notdeleteparenthesis
if exist nspDecrypted\fname.txt del nspDecrypted\fname.txt

::I also wanted to remove_(
set filename=%filename:_= %

if exist "%~dp0\output_xcib\!filename!" RD /s /q "%~dp0\output_xcib\!filename!"

set ofolder=%filename%

echo STARTING PROCESS... 
echo Please wait till window closes
echo Depending on file size it can take a little while
echo.
::Extract nsp to rawsecure
echo hactool v1.2.0  by SciresM
echo --------------
"%~dp0\ztools\hactool.exe" -k "%~dp0\ztools\keys.txt" -t pfs0 --pfs0dir=nspDecrypted\rawsecure "%~1"
echo.
::Delete .jpg files if BBB dump
if exist nspDecrypted\rawsecure\*.jpg del nspDecrypted\rawsecure\*.jpg
::List .nca files in directory
dir nspDecrypted\rawsecure\*.nca > nspDecrypted\lisfiles.txt
FINDSTR /I ".nca" "nspDecrypted\lisfiles.txt">nspDecrypted\nca_list.txt
del nspDecrypted\lisfiles.txt
set /a nca_number=0
for /f %%a in (nspDecrypted\nca_list.txt) do (
    set /a nca_number=!nca_number! + 1
)
::echo !nca_number!>nspDecrypted\nca_number.txt
::a nsp doesn't need .xml files to work. If it have them it will make our life easier
if exist "nspDecrypted\rawsecure\*.cnmt.xml" goto nsp_proper
goto nsp_notproper

:nsp_proper
::If we only have 4 nca files we don't have a manual
if !nca_number! LEQ 4 goto nsp_proper_nm
::Process for nsp with manual
set meta_xml=nspDecrypted\rawsecure\*.cnmt.xml

::Get a list of id's
FINDSTR /N /I "<id>" %meta_xml%>nspDecrypted\id.txt

::Find the html document (manual)
FINDSTR /N "HtmlDocument" %meta_xml%>nspDecrypted\ishtmldoc.txt
for /f "tokens=2* delims=: " %%a in (nspDecrypted\ishtmldoc.txt) do (
set html_pos=%%a)
::echo !html_pos!>nspDecrypted\html_pos.txt
set /a html_id_pos=!html_pos!+1
::echo %html_id_pos%>nspDecrypted\html_nca_id__pos.txt

::Set the filename for the manual nca
FINDSTR /N "%html_id_pos%:" nspDecrypted\id.txt>nspDecrypted\ishtml_id.txt
for /f "tokens=3* delims=<>" %%a in (nspDecrypted\ishtml_id.txt) do (
set myhtmlnca=%%a.nca)

::If we don't want to preserve the manual erase it
::If we want to preserve it move it out of rawsecure
::echo %myhtmlnca%>nspDecrypted\myhtmlnca.txt
if !preservemanual! EQU 1 ( move "nspDecrypted\rawsecure\%myhtmlnca%"  "nspDecrypted\" ) 
if !preservemanual! NEQ 1 ( del "nspDecrypted\rawsecure\%myhtmlnca%" )
::echo %myhtmlnca%>nspDecrypted\myhtmlnca.txt
set filename=!filename![nm]

:nsp_proper_nm
::Process for nsp without manual or nest step if we have a manual
set meta_xml=nspDecrypted\rawsecure\*.cnmt.xml
if exist nspDecrypted\id.txt del nspDecrypted\id.txt

FINDSTR /N /I "<id>" %meta_xml%>nspDecrypted\id.txt

::Identify the control nca and set it in a variable for next steps

FINDSTR /N "Control" %meta_xml%>nspDecrypted\iscontrolnca.txt
for /f "tokens=2* delims=: " %%a in (nspDecrypted\iscontrolnca.txt) do (
set control_pos=%%a)
echo !control_pos!>nspDecrypted\control_pos.txt
set /a control_id_pos=!control_pos!+1
::echo %control_id_pos%>nspDecrypted\control_id_pos.txt
FINDSTR /N "%control_id_pos%:" nspDecrypted\id.txt>nspDecrypted\iscrl_id.txt
for /f "tokens=3* delims=<>" %%a in (nspDecrypted\iscrl_id.txt) do (
set myctrlnca=%%a.nca)
echo %myctrlnca%>nspDecrypted\myctrlnca.txt

::Go and make a license .nsp
goto :lcnsp

::If the nsp doesn't have a .xml file follow a guessing approach
::In this portion we'll identify the manual nca files via hactool
::Hactool will recognize 2 of them as manual when one is actually legal
::We'll do a supposition to identify each
:nsp_notproper
set /a c_gamenca=1
set mycheck=Manual
set mycheck2=Control

for /f "tokens=4* delims= " %%a in (nspDecrypted\nca_list.txt) do (
echo %%a>>nspDecrypted\nca_list_helper.txt)
del nspDecrypted\nca_list.txt

if !nca_number! LEQ 4 goto nsp_notproper_nm

:nsp_notproper_man
set gstring=
if !c_gamenca! EQU 6 ( goto nsp_notproper_man2 )
if !c_gamenca! EQU 1 ( set gstring=,2,3,4,5, )
if !c_gamenca! EQU 2 ( set gstring=,1,3,4,5, )
if !c_gamenca! EQU 3 ( set gstring=,1,2,4,5, )
if !c_gamenca! EQU 4 ( set gstring=,1,2,3,5, )
if !c_gamenca! EQU 5 ( set gstring=,1,2,3,4, )

Set "skip=%gstring%"
(for /f "tokens=1,*delims=:" %%a in (' findstr /n "^" ^<nspDecrypted\nca_list_helper.txt'
) do Echo=%skip%|findstr ",%%a," 2>&1>NUL ||Echo=%%b
)>nspDecrypted\ncatocheck.txt

for /f %%a in (nspDecrypted\ncatocheck.txt) do (
    set ncatocheck=%%a
)
"%~dp0\ztools\hactool.exe" -k "%~dp0\ztools\keys.txt" -t nca -i "nspDecrypted\rawsecure\%ncatocheck%" >"nspDecrypted\nca_data.txt"
FINDSTR "Type" nspDecrypted\nca_data.txt >nspDecrypted\nca_helper.txt
for /f "tokens=3* delims=: " %%a in (nspDecrypted\nca_helper.txt) do (
echo %%a>>nspDecrypted\nca_helper2.txt)
Set "skip=,2,3,"
(for /f "tokens=1,*delims=:" %%a in (' findstr /n "^" ^<nspDecrypted\nca_helper2.txt'
) do Echo=%skip%|findstr ",%%a," 2>&1>NUL ||Echo=%%b
)>nspDecrypted\nca_type.txt
for /f %%a in (nspDecrypted\nca_type.txt) do (
    set nca_type=%%a
)
if %nca_type% EQU %mycheck% ( echo %ncatocheck%>>nspDecrypted\manual_list.txt )
if %nca_type% EQU %mycheck2% ( set myctrlnca=%ncatocheck% )
::echo %myctrlnca%> nspDecrypted\myctrlnca.txt
set /a c_gamenca+=1
del nspDecrypted\ncatocheck.txt
del nspDecrypted\nca_data.txt
del nspDecrypted\nca_helper.txt
del nspDecrypted\nca_helper2.txt
del nspDecrypted\nca_type.txt
goto nsp_notproper_man

:nsp_notproper_man2
::We'll get the route of the alleged "manual nca" 
set crlt=0
for /f %%a in (nspDecrypted\manual_list.txt) do (
    set /a crlt=!crlt! + 1
    set tmanual!crlt!=%%a
)

::del manual_list.txt

::Set complete route
set f_tmanual1="%~dp0\nspDecrypted\rawsecure\%tmanual1%"
set f_tmanual2="%~dp0\nspDecrypted\rawsecure\%tmanual2%"

::Get size of both nca
for /f "usebackq" %%A in ('%f_tmanual1%') do set size_tm1=%%~zA
for /f "usebackq" %%A in ('%f_tmanual2%') do set size_tm2=%%~zA

echo !size_tm1!>nspDecrypted\size_tm1.txt
echo !size_tm2!>nspDecrypted\size_tm2.txt

::Ok, here's some technical explanation
::Normaly legas is like 130-190kb
::Manual can be some mb (offline manual) or less size than legal (online manual)
::I'm assuming the limit for legal sise is a little over 300kb. Can be altered if needed

if !size_tm1! GTR 3400000 ( goto case1 )
if !size_tm1! GTR 3400000 ( goto case2 )
if !size_tm1! GTR !size_tm2! ( goto case3 )
if !size_tm2! GTR !size_tm1!( goto case4 )
goto nomanual

:case1
if !preservemanual! EQU 1 ( move "%f_tmanual1%"  "nspDecrypted\" ) 
if !preservemanual! NEQ 1 ( del "%f_tmanual1%" ) 
del "%f_tmanual1%"
set filename=!filename![nm]
goto lcnsp
:case2
if !preservemanual! EQU 1 ( move "%f_tmanual2%"  "nspDecrypted\" ) 
if !preservemanual! NEQ 1 ( del "%f_tmanual2%" ) 
del "%f_tmanual2%"
set filename=!filename![nm]
goto lcnsp
:case3
if !preservemanual! EQU 1 ( move "%f_tmanual2%"  "nspDecrypted\" ) 
if !preservemanual! NEQ 1 ( del "%f_tmanual2%" ) 
del "%f_tmanual2%"
set filename=!filename![nm]
goto lcnsp
:case4
if !preservemanual! EQU 1 ( move "%f_tmanual1%"  "nspDecrypted\" ) 
if !preservemanual! NEQ 1 ( del "%f_tmanual1%" ) 
del "%f_tmanual1%"
set filename=!filename![nm]
goto lcnsp

::Same aproach as before but only to identify the control .nca to make the license
:nsp_notproper_nm
set gstring=
if !c_gamenca! EQU 5 ( goto lcnsp )
if !c_gamenca! EQU 1 ( set gstring=,2,3,4, )
if !c_gamenca! EQU 2 ( set gstring=,1,3,4, )
if !c_gamenca! EQU 3 ( set gstring=,1,2,4, )
if !c_gamenca! EQU 4 ( set gstring=,1,2,3, )

Set "skip=%gstring%"
(for /f "tokens=1,*delims=:" %%a in (' findstr /n "^" ^<nspDecrypted\nca_list_helper.txt'
) do Echo=%skip%|findstr ",%%a," 2>&1>NUL ||Echo=%%b
)>nspDecrypted\ncatocheck.txt

for /f %%a in (nspDecrypted\ncatocheck.txt) do (
    set ncatocheck=%%a
)
"%~dp0\ztools\hactool.exe" -k "%~dp0\ztools\keys.txt" -t nca -i "nspDecrypted\rawsecure\%ncatocheck%" >"nspDecrypted\nca_data.txt"
FINDSTR "Type" nspDecrypted\nca_data.txt >nspDecrypted\nca_helper.txt
for /f "tokens=3* delims=: " %%a in (nspDecrypted\nca_helper.txt) do (
echo %%a>>nspDecrypted\nca_helper2.txt)
Set "skip=,2,3,"
(for /f "tokens=1,*delims=:" %%a in (' findstr /n "^" ^<nspDecrypted\nca_helper2.txt'
) do Echo=%skip%|findstr ",%%a," 2>&1>NUL ||Echo=%%b
)>nspDecrypted\nca_type.txt
for /f %%a in (nspDecrypted\nca_type.txt) do (
    set nca_type=%%a
)

if %nca_type% EQU %mycheck2% ( set myctrlnca=%ncatocheck% )
::echo %myctrlnca%> nspDecrypted\myctrlnca.txt
set /a c_gamenca+=1
del nspDecrypted\ncatocheck.txt
del nspDecrypted\nca_data.txt
del nspDecrypted\nca_helper.txt
del nspDecrypted\nca_helper2.txt
del nspDecrypted\nca_type.txt
goto nsp_notproper_nm


:lcnsp
del nspDecrypted\*.txt
if exist "nspDecrypted\licencia" RD /S /Q "nspDecrypted\licencia"
MD nspDecrypted\licencia
::echo f | xcopy /f /y "nspDecrypted\rawsecure\%myctrlnca%" "nspDecrypted\licencia\"
xcopy /Y "nspDecrypted\rawsecure\%myctrlnca%" "nspDecrypted\licencia\" >nul 2>&1
move /Y "nspDecrypted\rawsecure\*.cnmt.xml"  "nspDecrypted\licencia" >nul 2>&1
move /Y "nspDecrypted\rawsecure\*.tik"  "nspDecrypted\licencia" >nul 2>&1
move /Y "nspDecrypted\rawsecure\*.cert"  "nspDecrypted\licencia" >nul 2>&1
dir "%~dp0\nspDecrypted\licencia" /b  > "%~dp0\nspDecrypted\fileslist.txt"
set list=0
for /F "tokens=*" %%A in (nspDecrypted\fileslist.txt) do (
    SET /A list=!list! + 1
    set varlist!list!=%%A
)
set varlist >nul 2>&1
echo ************************************************************************************************************************
echo.
echo nspBuild 3.0 Beta  by CVFireDragon
echo -----------------
echo.
if exist  nspDecrypted\licencia\*.cnmt.xml goto nspwithxml
if exist  nspDecrypted\licencia\*.tik goto nspwithoutxml
goto createxci
:nspwithxml
if not exist  nspDecrypted\licencia\*.tik goto createxci
set var1=nspDecrypted\licencia\%varlist1%
set var2=nspDecrypted\licencia\%varlist2%
set var3=nspDecrypted\licencia\%varlist3%
set var4=nspDecrypted\licencia\%varlist4%
"%~dp0ztools\nspbuild.py" "nspDecrypted\!ofolder![lc].nsp" %var1% %var2% %var3% %var4%
del nspDecrypted\fileslist.txt
rmdir /s /q "%~dp0\nspDecrypted\licencia"
goto createxci
:nspwithoutxml
set var1=nspDecrypted\licencia\%varlist1%
set var2=nspDecrypted\licencia\%varlist2%
set var3=nspDecrypted\licencia\%varlist3%
"%~dp0\ztools\nspbuild.py" "nspDecrypted\!ofolder![lc].nsp" %var1% %var2% %var3%
del nspDecrypted\fileslist.txt
rmdir /s /q "%~dp0\nspDecrypted\licencia"
goto createxci

::Pass everything to hacbuild
:createxci
if exist nspDecrypted\rawsecure\*.tik del nspDecrypted\rawsecure\*.tik
if exist nspDecrypted\rawsecure\*.xml del nspDecrypted\rawsecure\*.xml
if exist nspDecrypted\rawsecure\*.cert del nspDecrypted\rawsecure\*.cert
if exist nspDecrypted\*.txt del nspDecrypted\*.txt
if exist nspDecrypted\rawsecure\*.jpg del nspDecrypted\rawsecure\*.jpg
if exist nspDecrypted\secure RD /S /Q nspDecrypted\secure\
MD nspDecrypted\secure
xcopy /y "ztools\game_info_preset.ini" "nspDecrypted\" >nul 2>&1
RENAME nspDecrypted\game_info_preset.ini "game_info.ini"
move  "%~dp0\nspDecrypted\rawsecure\*.nca"  "%~dp0\nspDecrypted\secure\" >nul 2>&1
RD /S /Q nspDecrypted\rawsecure\
MD nspDecrypted\normal
MD nspDecrypted\update
echo.
echo ************************************************************************************************************************
echo.
"%~dp0\ztools\hacbuild.exe" xci_auto "%~dp0\nspDecrypted"  "%~dp0\nspDecrypted\!filename![xcib].xci" 
RD /S /Q "%~dp0\nspDecrypted\secure"
RD /S /Q "%~dp0\nspDecrypted\normal"
RD /S /Q "%~dp0\nspDecrypted\update"
del "%~dp0\nspDecrypted\game_info.ini"
MD "%~dp0\output_xcib\!ofolder!"
move  "%~dp0\nspDecrypted\*.*"  "%~dp0\output_xcib\!ofolder!" >nul 2>&1
rmdir /s /q "%~dp0\nspDecrypted"
echo.
echo ************************************************************************************************************************
echo.
setlocal disabledelayedexpansion
echo Process finished!
echo.
echo Your files should be in the output_xcib folder!
endlocal
PING -n 5 127.0.0.1 >NUL 2>&1
echo.
echo    /@
echo    \ \
echo  ___\ \
echo (__O)  \
echo (____@)  \
echo (____@)   \
echo (__o)_    \
echo       \    \

PING -n 5 127.0.0.1 >NUL 2>&1
exit
















