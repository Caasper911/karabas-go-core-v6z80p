@echo off
call C:\Xilinx\14.7\ISE_DS\settings64.bat
cd /d C:\hobby\karabas_go_v6z80p\ise\work
bitgen -intstyle ise -f ..\osca676p.ut osca676p.ncd
