@echo off
rem Full ISE build with checks: every stage must produce its output (stale files are deleted first), the final line says BUILD OK / BUILD FAILED.
call C:\Xilinx\14.7\ISE_DS\settings64.bat
cd /d C:\hobby\karabas_go_v6z80p\ise
if not exist work mkdir work
if not exist work\xst\projnav.tmp mkdir work\xst\projnav.tmp
del /q osca676p.ngc work\osca676p.ngc work\osca676p.ngd work\osca676p_map.ncd work\osca676p.ncd work\osca676p.par work\osca676p.twr work\osca676p.bin work\osca676p.bit 2>nul
set XSTF=%1
if "%XSTF%"=="" set XSTF=osca676p.xst
xst -intstyle ise -ifn %XSTF% -ofn work\osca676p.syr > work\xst_console.log 2>&1
if not exist osca676p.ngc (echo BUILD FAILED at xst & exit /b 1)
copy /y osca676p.ngc work\ > nul
copy /y osca676p.ucf work\osca676p.ucf > nul
cd work
ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc osca676p.ucf -p xc6slx25-ftg256-2 osca676p.ngc osca676p.ngd > impl_console.log 2>&1
if not exist osca676p.ngd (echo BUILD FAILED at ngdbuild & exit /b 2)
map -intstyle ise -p xc6slx25-ftg256-2 -w -logic_opt on -ol high -xe n -t 2 -register_duplication on -r 4 -global_opt off -mt 2 -detail -ir off -pr b -lc off -power off -o osca676p_map.ncd osca676p.ngd osca676p.pcf >> impl_console.log 2>&1
if not exist osca676p_map.ncd (echo BUILD FAILED at map: see ise\work\impl_console.log & exit /b 3)
par -w -intstyle ise -ol high -xe n -mt 4 osca676p_map.ncd osca676p.ncd osca676p.pcf >> impl_console.log 2>&1
if not exist osca676p.ncd (echo BUILD FAILED at par: see ise\work\impl_console.log & exit /b 4)
trce -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml osca676p.twx osca676p.ncd -o osca676p.twr osca676p.pcf -ucf osca676p.ucf >> impl_console.log 2>&1
bitgen -intstyle ise -f ..\osca676p.ut osca676p.ncd > bit_console.log 2>&1
if not exist osca676p.bin (echo BUILD FAILED at bitgen & exit /b 5)
findstr /c:"All constraints were met" osca676p.par > nul
if errorlevel 1 (echo BUILD DONE but TIMING NOT MET & exit /b 6)
echo BUILD OK
