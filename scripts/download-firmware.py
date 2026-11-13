#!/usr/bin/env python3
"""Resume Apple's selected IPSW using verified HTTP byte ranges."""
import concurrent.futures, hashlib, json, os, pathlib, time, urllib.request

os.umask(0o077)
root=pathlib.Path(__file__).resolve().parent.parent
f=json.loads((root/'firmware/selected.json').read_text())['firmware']
name=f['url'].rsplit('/',1)[1]; final=root/'firmware'/name
part=final.with_suffix('.ipsw.part'); state=final.with_suffix('.chunks.json')
size=f['filesize']; chunk=64*1024*1024
if not final.exists():
 done=set(json.loads(state.read_text())) if state.exists() and part.exists() and part.stat().st_size==size else set()
 fd=os.open(part,os.O_RDWR|os.O_CREAT,0o644);os.ftruncate(fd,size)
 def get(i):
  start=i*chunk;end=min(size,start+chunk)-1
  for attempt in range(5):
   try:
    req=urllib.request.Request(f['url'],headers={'Range':f'bytes={start}-{end}'})
    with urllib.request.urlopen(req,timeout=120) as r:
     if r.status!=206 or r.headers.get('Content-Range')!=f'bytes {start}-{end}/{size}':raise RuntimeError('Unexpected HTTP range response')
     pos=start
     while data:=r.read(1024*1024):
      if pos+len(data)>end+1:raise RuntimeError('Range too long')
      view=memoryview(data)
      while view:
       n=os.pwrite(fd,view,pos);pos+=n;view=view[n:]
     if pos!=end+1:raise RuntimeError('Incomplete HTTP range')
    return i
   except Exception:
    if attempt==4:raise
    time.sleep(2*(attempt+1))
 count=(size+chunk-1)//chunk
 with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
  for i in pool.map(get,[i for i in range(count) if i not in done]):
   done.add(i);os.fsync(fd)
   temp=state.with_suffix('.tmp');temp.write_text(json.dumps(sorted(done)));temp.replace(state)
   print(f'{len(done)}/{count} chunks complete',flush=True)
 os.close(fd)
 target=part
else:target=final
print('Verifying SHA-256...',flush=True)
h=hashlib.sha256()
with target.open('rb') as r:
 while block:=r.read(8*1024*1024):h.update(block)
if h.hexdigest()!=f['sha256sum']:raise RuntimeError('SHA-256 mismatch; do not use this image')
if target==part:part.replace(final)
(root/'firmware/VERIFIED.txt').write_text(f'{name}\nSHA-256: {h.hexdigest()}\nVerified {time.strftime("%Y-%m-%d %H:%M:%S %z")}\n')
print('Apple IPSW download verified.',flush=True)
