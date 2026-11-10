#!/usr/bin/env python3
"""A small FAT16 disk image for the emulated SD card in the simulation (tb_boot.sv +sdimg=<file>).

Default: an MBR with one FAT16 partition (type 06) from LBA 63, as on a card; --nombr: the file system from sector 0 (FLOS
takes both: fat16_code: sector 0 with "FAT16" at $36 = no MBR, else partition 0 of the MBR, its type with bit 2 set).
The root directory has the volume label and a few files.

usage: make_fat16_image.py <out.img> [--mb 16] [--nombr] [--label OSCATEST]
"""
import argparse, struct

ap = argparse.ArgumentParser()
ap.add_argument('out')
ap.add_argument('--mb', type=int, default=16)
ap.add_argument('--nombr', action='store_true')
ap.add_argument('--label', default='OSCATEST')
a = ap.parse_args()

total = a.mb * 1024 * 1024 // 512
part_lba = 0 if a.nombr else 63
psec = total - part_lba
spc = 4                                   # sectors per cluster (2 KB)
reserved = 1
nfats = 2
root_ents = 512
root_secs = root_ents * 32 // 512
# sectors per FAT: enough for the clusters that remain
spf = 1
while True:
    data = psec - reserved - nfats * spf - root_secs
    clusters = data // spc
    if (clusters + 2) * 2 <= spf * 512:
        break
    spf += 1
assert 4085 <= clusters < 65525, clusters

img = bytearray(total * 512)

if not a.nombr:
    mbr = bytearray(512)
    e = struct.pack('<B3sB3sII', 0x00, b'\x01\x01\x00', 0x06, b'\xfe\xff\xff', part_lba, psec)
    mbr[0x1BE:0x1BE + 16] = e
    mbr[510:512] = b'\x55\xaa'
    img[0:512] = mbr

bs = bytearray(512)
bs[0:3] = b'\xeb\x3c\x90'
bs[3:11] = b'MSDOS5.0'
struct.pack_into('<HBHBHHBHHHII', bs, 11, 512, spc, reserved, nfats, root_ents, psec if psec < 65536 else 0, 0xF8, spf, 63, 255,
                 part_lba, psec if psec >= 65536 else 0)
struct.pack_into('<BBBI', bs, 36, 0x80, 0, 0x29, 0x12345678)
bs[43:54] = a.label.ljust(11)[:11].encode()
bs[54:62] = b'FAT16   '
bs[510:512] = b'\x55\xaa'
base = part_lba * 512
img[base:base + 512] = bs

fat_lba = part_lba + reserved
root_lba = fat_lba + nfats * spf
data_lba = root_lba + root_secs

fat = bytearray(spf * 512)
struct.pack_into('<HH', fat, 0, 0xFFF8, 0xFFFF)
root = bytearray(root_secs * 512)
ent = 0
def dirent(name, attr, cluster=0, size=0):
    global ent
    d = bytearray(32)
    d[0:11] = name.encode()
    d[11] = attr
    struct.pack_into('<HHHI', d, 22, 0, 0x5B6A, cluster, size)    # time, date 2025-11-10, cluster, size
    root[ent * 32:(ent + 1) * 32] = d
    ent += 1
dirent(a.label.ljust(11)[:11], 0x08)
next_cl = 2
files = [('HELLO   TXT', b'Hello from the emulated SD card of Karabas Go\r\n'),
         ('NUMBERS BIN', bytes(range(256)) * 20)]                 # 5120 bytes: three clusters
for name, content in files:
    ncl = max(1, (len(content) + spc * 512 - 1) // (spc * 512))
    first = next_cl
    for i in range(ncl):
        c = next_cl + i
        struct.pack_into('<H', fat, c * 2, 0xFFFF if i == ncl - 1 else c + 1)
        off = (data_lba + (c - 2) * spc) * 512
        chunk = content[i * spc * 512:(i + 1) * spc * 512]
        img[off:off + len(chunk)] = chunk
    next_cl += ncl
    dirent(name, 0x20, first, len(content))
for f in range(nfats):
    off = (fat_lba + f * spf) * 512
    img[off:off + len(fat)] = fat
img[root_lba * 512:root_lba * 512 + len(root)] = root
open(a.out, 'wb').write(img)
print('%s: %d MB, %s, partition at LBA %d, %d clusters of %d sectors, FAT %d sectors x %d, root at %d, data at %d' %
      (a.out, a.mb, 'no MBR' if a.nombr else 'MBR', part_lba, clusters, spc, spf, nfats, root_lba, data_lba))
