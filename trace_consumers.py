import sys, re, os, collections
sys.path.insert(0,'/home/claude')
import sch2v
import glob
mods={}
for f in sorted(glob.glob('osca676p/*.sch')):
    m=sch2v.parse_sch(f); mods[m.name]=m
SEQ=re.compile(r'^(fd|ft|sr\d|cb|cc|ram16|ramb4|ofd)')
OUTP={'O','CO','EQ','S','OFL','O0','Q','DPO','SPO','DO','TC','CEO'}
def base(s):
    return sch2v.split_sig(s.split(',')[0].strip())[0].lower() if s else None
def bases(sig):
    return {sch2v.split_sig(p.strip())[0].lower() for p in sig.split(',')}
results=[]
seen=set()
def prop(modname, net, path):
    key=(modname,net)
    if key in seen: return
    seen.add(key)
    m=mods[modname]
    for inst in m.insts:
        for pin,sig in inst['pins']:
            if not sig or net not in bases(sig): continue
            pb=sch2v.split_sig(pin)[0]
            sym=inst['sym']
            if sym in mods:                              # hierarchical: descend through the same-named port
                prop(sym, pb.lower(), path+[f"{modname}.{inst['name']}({sym}).{pb}"])
            elif sym.startswith('obuf'):
                results.append((modname,inst['name'],sym+' (to pads / CPU bus)',pb,[],[],path))
            elif SEQ.match(sym):
                clk=[s for p2,s in inst['pins'] if sch2v.split_sig(p2)[0] in ('C','CLK','WCLK','CLKA','CLKB')]
                ce =[s for p2,s in inst['pins'] if sch2v.split_sig(p2)[0] in ('CE','WE','L','ENA','ENB','EN')]
                results.append((modname,inst['name'],sym,pb,clk,ce,path))
            else:                                        # combinational: follow its outputs
                for p2,s2 in inst['pins']:
                    if sch2v.split_sig(p2)[0] in OUTP and s2:
                        for b2 in bases(s2): prop(modname,b2,path+[f"{inst['name']}({sym})"])
start=sys.argv[1]; top='osca_pal'
prop(top,start.lower(),[])
print("consumers of",start,":",len(results))
for r in results:
    print(f"  {r[0]}.{r[1]:<12} {r[2]:<8} data-pin={r[3]:<4} clk={r[4]} ce/we={r[5]}   via {' > '.join(r[6][-2:])}")
