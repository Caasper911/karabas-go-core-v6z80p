#!/usr/bin/env python3
"""Build a Karabas Go core file (.kg1) for the OSCA port: header (1024 bytes) + bitstream (.bin from bitgen) + ROM blocks + OSD item count.
Layout from karabas-go-firmware (src/config.h FILE_POS_*, src/fpga/core_loader.cpp, lib/KarabasCommon/src/kg_format.cpp); no OSD items.
The ROM block carries the FLOS boot image (ram_image.bin: FLOS at $1000 of the system RAM); the MCU writes it while the core is held in reset.
Usage: make_kg1.py [--bit ise/work/osca676p.bin] [--rom ram_image.bin] [--out ise/work/osca.kg1] [--build YYMMDDHH]"""
import argparse, os, struct, time

def pad(s, n):
    b = s.encode('ascii')
    assert len(b) <= n
    return b + b' ' * (n - len(b))

def main():
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
    ap = argparse.ArgumentParser()
    ap.add_argument('--bit', default=os.path.join(root, 'ise', 'work', 'osca676p.bin'))
    ap.add_argument('--rom', default=os.path.join(root, 'ram_image.bin'))
    ap.add_argument('--rom-addr', type=lambda x: int(x, 0), default=0)
    ap.add_argument('--out', default=os.path.join(root, 'ise', 'work', 'osca.kg1'))
    ap.add_argument('--build', default=time.strftime('%y%m%d%H'))
    ap.add_argument('--order', type=int, default=0x30)
    a = ap.parse_args()
    bit = open(a.bit, 'rb').read()
    rom = open(a.rom, 'rb').read()
    assert bit[:16] == b'\xff' * 16 and b'\xaa\x99\x55\x66' in bit[:64], 'not a bitgen .bin'
    roms = struct.pack('>II', len(rom), a.rom_addr) + rom
    h = bytearray(b'\xff' * 1024)
    h[0:0xba] = bytes(0xba)
    h[0:4] = b'kgo1'
    h[4:36] = pad('osca', 32)
    h[36:68] = pad('OSCA V6Z80P+', 32)
    h[68:76] = pad(a.build, 8)
    h[76] = 1                      # visible
    h[77] = a.order & 0xff         # order in the core browser
    h[78] = 0x01                   # CORE_TYPE_OSD (normal core)
    h[79] = 0xff                   # no EEPROM bank
    h[80:84] = struct.pack('>I', len(bit))
    h[84:88] = struct.pack('>I', len(roms))
    h[88] = 0                      # no RTC
    h[185] = 0                     # default SPI frequency
    out = bytes(h) + bit + roms + b'\x00'   # trailing 0 = number of OSD items
    open(a.out, 'wb').write(out)
    print(f'{a.out}: {len(out)} bytes (bitstream {len(bit)}, ROM block {len(roms)}, build {a.build})')

main()
