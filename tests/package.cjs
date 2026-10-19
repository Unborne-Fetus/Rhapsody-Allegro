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
 const response=await context.window.fetch('https://example.test/rhapsody/index.wasm');
 const bytes=Buffer.from(await response.arrayBuffer());
 assert.deepEqual(bytes,fs.readFileSync('build/web/index.wasm'));
 assert(WebAssembly.validate(bytes),'assembled engine must be valid WebAssembly');
 assert.equal(response.headers.get('Content-Type'),'application/wasm');
 const largest=Math.max(...fs.readdirSync('dist').filter(x=>x.endsWith('.bin')).map(x=>fs.statSync('dist/'+x).size));
 assert(largest<=25*1024*1024);
 console.log('Split-engine loader: byte-identical, valid WASM, correct MIME, host size limits PASS');
})().catch(e=>{console.error(e);process.exit(1)});
