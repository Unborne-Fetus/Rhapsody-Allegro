// Validate the deployed split-engine loader without requiring browser graphics.
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
(async()=>{
 const html=fs.readFileSync('dist/index.html','utf8');
 const loader=html.match(/<script>([\s\S]*?)<\/script>/)[1];
 const context={URL,Blob,Response,location:{href:'https://example.test/rhapsody/'},window:{fetch:async resource=>{
   const name=new URL(resource).pathname.split('/').pop();
   return new Response(fs.readFileSync('dist/'+name));
 }}};
 vm.runInNewContext(loader,context);
 const response=await context.window.fetch(new URL('https://example.test/rhapsody/index.wasm')); 
 const bytes=Buffer.from(await response.arrayBuffer());
 assert.deepEqual(bytes,fs.readFileSync('build/web/index.wasm'));
 assert(WebAssembly.validate(bytes),'assembled engine must be valid WebAssembly');
 assert.equal(response.headers.get('Content-Type'),'application/wasm');
 const packName=fs.readdirSync('dist').find(name=>/^index-[a-f0-9]+\.pck$/.test(name));
 assert(packName && html.includes('GODOT_CONFIG.mainPack = \"'+packName+'\"'),'engine explicitly preloads content-addressed pack');
 const pack=await context.window.fetch('https://example.test/rhapsody/'+packName);
 assert.deepEqual(Buffer.from(await pack.arrayBuffer()),fs.readFileSync('dist/'+packName));
 const bad={URL,Blob,Response,location:{href:'https://example.test/rhapsody/'},window:{fetch:async()=>new Response('missing',{status:404})}};
 vm.runInNewContext(loader,bad);
 await assert.rejects(bad.window.fetch('https://example.test/rhapsody/index.wasm'),/Engine download failed/);
 assert(!fs.readdirSync('dist').some(name=>name.startsWith('.index.') || name.endsWith('.import') || name.includes('.pck-')),'temporary export files must not be shipped');
 assert(html.includes('viewport-fit=cover') && html.includes('safe-area-inset-left') && html.includes('100dvh'),'phone viewport respects safe areas and browser bars');
 assert(html.indexOf('window.rhapsodyPrepareCanvas(GODOT_CONFIG)')>=0 && html.indexOf('window.rhapsodyPrepareCanvas(GODOT_CONFIG)')<html.indexOf('const engine = new Engine(GODOT_CONFIG)'),'phone canvas ownership must be configured before engine creation');
 assert(html.includes('rhapsodyFullscreen') && html.includes('wakeLock'),'phone browser helpers bundled');
 const largest=Math.max(...fs.readdirSync('dist').filter(x=>x.endsWith('.bin')).map(x=>fs.statSync('dist/'+x).size));
 assert(largest<=25*1024*1024);
 console.log('Split-engine loader: byte-identical, valid WASM, correct MIME, host size limits PASS');
})().catch(e=>{console.error(e);process.exit(1)});
