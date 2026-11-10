@echo off
call C:\Xilinx\14.7\ISE_DS\settings64.bat
cd /d C:\hobby\karabas_go_v6z80p\src\ise
xst -intstyle ise -ifn osca676p.xst -ofn work\osca676p.syr
