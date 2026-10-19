"""Package a real Godot export for static hosts with per-file size limits.
Godot's engine is unchanged. Only its fetch of index.wasm is assembled from
three normal static files, avoiding a >25 MiB individual asset.
"""
from pathlib import Path
import shutil, json
root = Path(__file__).resolve().parents[1]
source, dest = root/'build/web', root/'dist'
if dest.exists(): shutil.rmtree(dest)
shutil.copytree(source,dest)
wasm=(dest/'index.wasm').read_bytes()
chunks=[]
for index,start in enumerate(range(0,len(wasm),12*1024*1024)):
    name=f'engine-{index}.bin'
    (dest/name).write_bytes(wasm[start:start+12*1024*1024])
    chunks.append(name)
(dest/'index.wasm').unlink()
loader='''<script>
// Large WebAssembly assets are split solely for static-host compatibility.
const originalFetch = window.fetch.bind(window);
window.fetch = async function(resource, options) {
  const url = typeof resource === 'string' ? resource : resource.url;
  if (url && new URL(url, location.href).pathname.endsWith('/index.wasm')) {
    const parts = await Promise.all(CHUNKS.map(async name => {
      const response = await originalFetch(new URL(name, location.href), options);
      if (!response.ok) throw new Error('Engine download failed: '+name);
      return response.arrayBuffer();
    }));
    const blob = new Blob(parts, {type:'application/wasm'});
    return new Response(blob, {headers:{'Content-Type':'application/wasm','Content-Length':String(blob.size)}});
  }
  return originalFetch(resource, options);
};
</script>'''.replace('CHUNKS',json.dumps(chunks))
html=(dest/'index.html').read_text()
html=html.replace('<head>','<head>\n'+loader)
html=html.replace('<title>Rhapsody: Allegro</title>','<title>Rhapsody: Allegro — Play</title>')
(dest/'index.html').write_text(html)
(dest/'_headers').write_text('/*.bin\n  Content-Type: application/octet-stream\n  Cache-Control: public, max-age=31536000, immutable\n/index.html\n  Cache-Control: no-cache\n')
# Content changes across builds: do not cache stable engine filenames forever.
(dest/'_headers').write_text('/*.bin\n  Content-Type: application/octet-stream\n  Cache-Control: public, max-age=3600\n/index.html\n  Cache-Control: no-cache\n')
print(f'Packaged {len(wasm):,} engine bytes into {len(chunks)} chunks.')
