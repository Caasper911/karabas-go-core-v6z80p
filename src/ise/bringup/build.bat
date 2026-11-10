@echo off
rem usage: build.bat <name> <USE_DCM 0|1>
call C:\Xilinx\14.7\ISE_DS\settings64.bat
cd /d C:\hobby\karabas_go_v6z80p\src\ise\bringup
if exist %1 rmdir /s /q %1
mkdir %1\xst\projnav.tmp
echo verilog work "../kg_bringup_top.v"> %1\%1.prj
cd %1
copy /y ..\bringup.ucf . > nul
(echo set -tmpdir "xst/projnav.tmp"& echo set -xsthdpdir "xst"& echo run& echo -ifn %1.prj& echo -ofn %1& echo -ofmt NGC& echo -p xc6slx25-2-ftg256& echo -top kg_bringup_top& echo -generics {USE_DCM=%2}& echo -iob True& echo -opt_mode Speed& echo -opt_level 1) > %1.xst
xst -ifn %1.xst -ofn %1.syr || exit /b 1
ngdbuild -dd _ngo -uc bringup.ucf -p xc6slx25-ftg256-2 %1.ngc %1.ngd || exit /b 2
map -p xc6slx25-ftg256-2 -w -o %1_map.ncd %1.ngd %1.pcf || exit /b 3
par -w %1_map.ncd %1.ncd %1.pcf || exit /b 4
bitgen -f ..\..\osca676p.ut %1.ncd || exit /b 5
