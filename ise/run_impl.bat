@echo off
call C:\Xilinx\14.7\ISE_DS\settings64.bat
cd /d C:\hobby\karabas_go_v6z80p\ise
copy /y osca676p.ngc work\ > nul
copy /y osca676p.ucf work\osca676p.ucf > nul
cd work
ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc osca676p.ucf -p xc6slx25-ftg256-2 osca676p.ngc osca676p.ngd || exit /b 1
map -intstyle ise -p xc6slx25-ftg256-2 -w -logic_opt off -ol high -xe n -t 2 -register_duplication off -r 4 -global_opt off -mt 2 -detail -ir off -pr b -lc off -power off -o osca676p_map.ncd osca676p.ngd osca676p.pcf || exit /b 2
par -w -intstyle ise -ol high -xe n -mt 4 osca676p_map.ncd osca676p.ncd osca676p.pcf || exit /b 3
trce -intstyle ise -v 3 -s 2 -n 3 -fastpaths -xml osca676p.twx osca676p.ncd -o osca676p.twr osca676p.pcf -ucf osca676p.ucf
