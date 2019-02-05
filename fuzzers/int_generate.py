#!/usr/bin/env python3

from __future__ import print_function

import os

from prjxray.segmaker import Segmaker
from prjxray.bitfilter import get_bitfilter
import argparse

parser = argparse.ArgumentParser(description="Generate int segfiles")
parser.add_argument(
    '--todo', action='store', default='../../todo.txt', help='todo file path')
parser.add_argument(
    '--design',
    action='store',
    default='design.txt',
    help='design description file path')
parser.add_argument('--verbose', action='store_true', help='')
parser.add_argument(
    '--bits', action='store', default='design.bits', help='bits file path')

args = parser.parse_args()
segmk = Segmaker(args.bits)

verbose = args.verbose

tiledata = dict()
pipdata = dict()
ignpip = set()
todo = set()

print("Loading todo from %s." % args.todo)
with open(args.todo, "r") as f:
    for line in f:
        line = tuple(line.strip().split("."))
        verbose and print('todo', line)
        todo.add(line)

print("Loading tags from %s." % args.design)
with open(args.design, "r") as f:
    for line in f:
        tile, pip, src, dst, pnum, pdir = line.split()

        if not tile.startswith('INT_'):
            continue

        _, pip = pip.split(".")
        _, src = src.split("/")
        _, dst = dst.split("/")
        pnum = int(pnum)
        pdir = int(pdir)

        if tile not in tiledata:
            tiledata[tile] = {"pips": set(), "srcs": set(), "dsts": set()}

        if pip in pipdata:
            assert pipdata[pip] == (src, dst)
        else:
            pipdata[pip] = (src, dst)

        tiledata[tile]["pips"].add(pip)
        tiledata[tile]["srcs"].add(src)
        tiledata[tile]["dsts"].add(dst)

        if pdir == 0:
            tiledata[tile]["srcs"].add(dst)
            tiledata[tile]["dsts"].add(src)

        if pnum == 1 or pdir == 0:
            verbose and print('ignore pnum == 1 or pdir == 0: ', pip)
            ignpip.add(pip)

        t = ("_".join(tile.split("_")[0:2]), dst, src)
        if t not in todo:
            verbose and print('ignore not todo: ', t)
            ignpip.add(pip)

for tile, pips_srcs_dsts in tiledata.items():
    pips = pips_srcs_dsts["pips"]
    srcs = pips_srcs_dsts["srcs"]
    dsts = pips_srcs_dsts["dsts"]

    for pip, src_dst in pipdata.items():
        src, dst = src_dst
        if pip in ignpip:
            pass
        elif pip in pips:
            segmk.add_tile_tag(tile, "%s.%s" % (dst, src), 1)
        elif src_dst[1] not in dsts:
            segmk.add_tile_tag(tile, "%s.%s" % (dst, src), 0)

segmk.compile(bitfilter=get_bitfilter(os.getenv('XRAY_DATABASE'), 'INT'))
segmk.write()
