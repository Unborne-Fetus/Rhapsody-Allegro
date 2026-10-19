"""Package a real Godot export for static hosts with per-file size limits.
Godot's engine is unchanged. Only its fetch of index.wasm is assembled from
bounded static files, avoiding a >25 MiB individual asset.
"""
from pathlib import Path
import shutil, json, hashlib
root = Path(__file__).resolve().parents[1]
source, dest = root/'build/web', root/'dist'
if dest.exists(): shutil.rmtree(dest)
dest.mkdir(parents=True)
# Export directories can retain interrupted engine copies and import sidecars.
# Only runtime files belong in the hosted build.
for asset in source.iterdir():
    if asset.is_file() and not asset.name.startswith('.') and asset.suffix in {'.html','.js','.wasm','.pck','.png'}:
        shutil.copy2(asset,dest/asset.name)
wasm=(dest/'index.wasm').read_bytes()
chunks=[]
for index,start in enumerate(range(0,len(wasm),12*1024*1024)):
    piece=wasm[start:start+12*1024*1024]
    name=f'engine-{hashlib.sha256(piece).hexdigest()[:12]}.bin'
    (dest/name).write_bytes(piece)
    chunks.append(name)
(dest/'index.wasm').unlink()
(dest/'.gdignore').touch()
loader='''<script>
// Large WebAssembly assets are split solely for static-host compatibility.
const originalFetch = window.fetch.bind(window);
let downloadedBytes = 0;
async function loadEnginePart(name, options) {
  const response = await originalFetch(new URL(name, location.href), options);
  if (!response.ok) throw new Error('Engine download failed: '+name);
  if (!response.body) return response.arrayBuffer();
  const reader = response.body.getReader();
  const buffers=[];
  for (;;) {
    const {done,value}=await reader.read();
    if (done) break;
    buffers.push(value); downloadedBytes += value.byteLength;
    if (typeof document !== 'undefined') {
      const label=document.getElementById('load-detail');
      if (label) label.textContent='Loading the stage · '+(downloadedBytes/1048576).toFixed(1)+' / ENGINE_MIB MB';
    }
  }
  return new Blob(buffers).arrayBuffer();
}
window.fetch = async function(resource, options) {
  const url = typeof resource === 'string' ? resource : (resource instanceof URL ? resource.href : resource.url);
  if (url && new URL(url, location.href).pathname.endsWith('/index.wasm')) {
    const parts = await Promise.all(CHUNKS.map(name => loadEnginePart(name, options)));
    const blob = new Blob(parts, {type:'application/wasm'});
    return new Response(blob, {headers:{'Content-Type':'application/wasm','Content-Length':String(blob.size)}});
  }
  return originalFetch(resource, options);
};
</script>'''.replace('CHUNKS',json.dumps(chunks)).replace('ENGINE_MIB',f'{len(wasm)/1048576:.1f}')
html=(dest/'index.html').read_text()
game_hash=hashlib.sha256((dest/'index.pck').read_bytes()).hexdigest()[:12]
# Force every release to fetch its matching game pack, even behind a stale CDN.
html=html.replace('index.pck',f'index-{game_hash}.pck')
(dest/'index.pck').rename(dest/f'index-{game_hash}.pck')
html=html.replace('<head>','<head>\n'+loader)
html=html.replace('width=device-width, user-scalable=no, initial-scale=1.0','width=device-width, initial-scale=1.0, viewport-fit=cover, user-scalable=no')
phone_script=(root/'tools/phone-browser.js').read_text()
html=html.replace('const engine = new Engine(GODOT_CONFIG);',phone_script+f'\nGODOT_CONFIG.mainPack = "index-{game_hash}.pck";\nwindow.rhapsodyPrepareCanvas(GODOT_CONFIG);\nconst engine = new Engine(GODOT_CONFIG);')
html=html.replace('<title>Rhapsody: Allegro</title>','<title>Rhapsody: Allegro — Play</title>')
brand='''<div id="load-brand" role="status"><span>R / A</span><h1>RHAPSODY<br><em>ALLEGRO</em></h1><p id="load-detail">Preparing the first movement…</p><small>Two-thumb controls · Portrait or landscape · Keyboard and controller supported</small></div>'''
css='''<style>
html,body {overflow:hidden;overscroll-behavior:none;touch-action:none;-webkit-user-select:none;user-select:none;-webkit-touch-callout:none;background:#0b1019}
#canvas {touch-action:none;position:fixed!important;left:env(safe-area-inset-left,0px)!important;top:env(safe-area-inset-top,0px)!important;right:env(safe-area-inset-right,0px)!important;bottom:env(safe-area-inset-bottom,0px)!important;width:calc(100vw - env(safe-area-inset-left,0px) - env(safe-area-inset-right,0px))!important;height:calc(100dvh - env(safe-area-inset-top,0px) - env(safe-area-inset-bottom,0px))!important}
#status {background:#0b1019!important;color:#f2ebda;font-family:Arial,sans-serif}
#status-splash {display:none!important}
#load-brand {text-align:center;padding:20px}
#load-brand span {color:#74ead5;font-size:17px;letter-spacing:.3em}
#load-brand h1 {font-size:clamp(32px,6vw,64px);letter-spacing:.08em;line-height:1.05;margin:24px 0}
#load-brand em {font-style:normal;color:#ef7854;font-size:.6em;letter-spacing:.27em}
#load-brand p {color:#a5b4bf;font-size:14px}
#load-brand small {color:#7e939e;font-size:12px}
#status-progress {width:min(320px,70vw);bottom:12%;height:5px;accent-color:#74ead5}
#status-notice {max-width:650px;overflow:auto;background:#251923;border-color:#ef7854}
</style>'''
html=html.replace('</head>',css+'\n</head>')
html=html.replace('<div id="status">','<div id="status">'+brand)
(dest/'index.html').write_text(html)
(dest/'build-info.json').write_text(json.dumps({'version':'0.8.0','godot':'4.5.1','engine_sha256':hashlib.sha256(wasm).hexdigest(),'game_sha256':hashlib.sha256((dest/f'index-{game_hash}.pck').read_bytes()).hexdigest()},indent=2)+'\n')
# Content changes across builds: do not cache stable engine filenames forever.
(dest/'_headers').write_text('/*.bin\n  Content-Type: application/octet-stream\n  Cache-Control: public, max-age=31536000, immutable\n/index.html\n  Cache-Control: no-cache\n')
print(f'Packaged {len(wasm):,} engine bytes into {len(chunks)} chunks.')
