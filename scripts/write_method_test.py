import sys,time,random,struct,statistics,os
sys.path.insert(0,'/ws/DynamixelSDK/python/src')
from dynamixel_sdk import *
LAT=os.environ.get('LAT','?'); N=int(os.environ.get('N','20'))
A,B=22,21; GOAL=116; POS=132; PV=112; PA=108; TQ=64; HW=70
STEP=114  # ticks ~ 10 deg
ph=PortHandler('/dev/ttyUSB0'); pk=PacketHandler(2.0)
assert ph.openPort() and ph.setBaudRate(1000000)
def log(*a): print(*a,file=sys.stderr,flush=True)
def r4(i,a): v,r,e=pk.read4ByteTxRx(ph,i,a);assert r==0,(i,a,r);return v
def w1(i,a,v): r,e=pk.write1ByteTxRx(ph,i,a,v);assert r==0,(i,a,r)
def w4(i,a,v): r,e=pk.write4ByteTxRx(ph,i,a,v);assert r==0,(i,a,r)
rd=GroupSyncRead(ph,pk,POS,4); rd.addParam(A); rd.addParam(B)
def poll():
    t0=time.perf_counter(); r=rd.txRxPacket(); t1=time.perf_counter()
    assert r==0,r
    def s(v): return v-(1<<32) if v>=1<<31 else v
    return (t0+t1)/2,s(rd.getData(A,POS,4)),s(rd.getData(B,POS,4))
def b4(v): return list(struct.pack('<i',v))
def cmd(method,order,ga,gb):
    goals={A:ga,B:gb}
    t0=time.perf_counter()
    if method=='write':
        for i in order: w4(i,GOAL,goals[i])
    elif method=='sync':
        g=GroupSyncWrite(ph,pk,GOAL,4)
        for i in order: g.addParam(i,b4(goals[i]))
        assert g.txPacket()==0; g.clearParam()
    elif method=='bulk':
        g=GroupBulkWrite(ph,pk)
        for i in order: g.addParam(i,GOAL,4,b4(goals[i]))
        assert g.txPacket()==0; g.clearParam()
    elif method=='regaction':
        for i in order:
            r,e=pk.regWriteTxRx(ph,i,GOAL,4,b4(goals[i]));assert r==0,r
        r=pk.action(ph,BROADCAST_ID);assert r==0,r
    return t0,time.perf_counter()
def crossing(ts,ds,th):
    for k in range(1,len(ds)):
        if ds[k]>=th>ds[k-1]:
            return ts[k-1]+(th-ds[k-1])/(ds[k]-ds[k-1])*(ts[k]-ts[k-1])
    return None
# setup
saved={}
for i in (A,B):
    saved[i]=(r4(i,PA),r4(i,PV))
    w1(i,TQ,0); w4(i,PA,60); w4(i,PV,120)
_,pa,pb=poll(); homeA,homeB=pa,pb
for i,h in ((A,homeA),(B,homeB)): w4(i,GOAL,h)
for i in (A,B): w1(i,TQ,1)
log('LAT',LAT,'home',homeA,homeB); time.sleep(0.5)
cells=[(m,o) for m in ('write','sync','bulk','regaction') for o in ('AB','BA')]
plan=cells*(N//2); random.seed(1); random.shuffle(plan)
print('latency_ms,method,first_id,skew_ms,issue_ms,poll_ms,final_err_ticks,n_thresholds,max_mismatch_ticks')
s=1
try:
    for n,(m,o) in enumerate(plan):
        s=-s
        order=[A,B] if o=='AB' else [B,A]
        ga=homeA+s*STEP; gb=homeB-s*STEP
        base=[poll() for _ in range(4)]
        a0=statistics.median(x[1] for x in base); b0=statistics.median(x[2] for x in base)
        tc0,tc1=cmd(m,order,ga,gb); T=[];DA=[];DB=[]
        te=time.perf_counter()+0.45
        while time.perf_counter()<te:
            t,pa,pb=poll();T.append(t);DA.append(abs(pa-a0));DB.append(abs(pb-b0))
        if max(DA)>STEP*3.2 or max(DB)>STEP*3.2: raise RuntimeError('overshoot abort')
        for i in (A,B):
            he,r,e=pk.read1ByteTxRx(ph,i,HW)
            if he: raise RuntimeError('hardware error %d id %d'%(he,i))
        sk=[]
        for th in (3,6,12,24,48):
            ta=crossing(T,DA,th);tb=crossing(T,DB,th)
            if ta is not None and tb is not None: sk.append((tb-ta)*1000)
        pm=statistics.median([T[k]-T[k-1] for k in range(1,len(T))])*1000
        fe=max(abs(DA[-1]-abs(ga-a0)),abs(DB[-1]-abs(gb-b0)))
        print('%s,%s,%d,%.3f,%.3f,%.2f,%d,%d,%d'%(LAT,m,order[0],statistics.mean(sk) if sk else float('nan'),(tc1-tc0)*1000,pm,fe,len(sk),max(abs(x-y) for x,y in zip(DA,DB))),flush=True)
        time.sleep(0.45)
finally:
    log('restoring')
    for i,h in ((A,homeA),(B,homeB)):
        try: w4(i,GOAL,h)
        except Exception as ex: log(ex)
    time.sleep(0.8)
    for i in (A,B):
        try: w1(i,TQ,0); w4(i,PA,saved[i][0]); w4(i,PV,saved[i][1])
        except Exception as ex: log(ex)
