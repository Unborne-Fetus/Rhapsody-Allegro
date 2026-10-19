// Exercise resize ownership without browser automation or a WebGL dependency.
const assert = require('node:assert/strict'), fs = require('node:fs'), vm = require('node:vm');
const source = fs.readFileSync('tools/phone-browser.js','utf8');
function fixture(touch) {
 const events={}, timers=[], frames=[];
 let rect={width:390,height:844}, sizeObserver, mutationObserver;
 const canvas={width:1280,height:720,getBoundingClientRect:()=>rect};
 const window={devicePixelRatio:3,addEventListener:(name,fn)=>{events[name]=fn;},visualViewport:{addEventListener:(name,fn)=>{events['visual-'+name]=fn;}}};
 const context={window,navigator:{maxTouchPoints:touch?5:0},document:{getElementById:()=>canvas,addEventListener:()=>{},visibilityState:'visible'},requestAnimationFrame:fn=>frames.push(fn),setTimeout:fn=>timers.push(fn),ResizeObserver:class{constructor(fn){sizeObserver=fn;} observe(){}},MutationObserver:class{constructor(fn){mutationObserver=fn;}observe(){}}};
 vm.runInNewContext(source,context);
 return {window,canvas,events,frames,timers,config:{canvasResizePolicy:2},resize:(w,h)=>{rect={width:w,height:h};sizeObserver();},mutate:()=>mutationObserver(),flush:()=>{while(frames.length) frames.shift()();}};
}
const mobile=fixture(true); mobile.window.rhapsodyPrepareCanvas(mobile.config); mobile.flush();
assert.equal(mobile.config.canvasResizePolicy,0);
assert.equal(mobile.canvas.width,1170); assert.equal(mobile.canvas.height,2532);
for(let i=0;i<8;i++) {
 mobile.resize(844,390); mobile.events.orientationchange(); mobile.flush();
 assert.equal(mobile.canvas.width,2532); assert.equal(mobile.canvas.height,1170);
 mobile.resize(390,844); mobile.events['visual-resize'](); mobile.flush();
 assert.equal(mobile.canvas.width,1170); assert.equal(mobile.canvas.height,2532);
}
// Engine boot can assign its original project size after a slow download.
mobile.canvas.width=1280; mobile.canvas.height=720; mobile.mutate(); mobile.flush();
assert.equal(mobile.canvas.width,1170); assert.equal(mobile.canvas.height,2532);
mobile.resize(782,352); mobile.flush();
assert.equal(mobile.canvas.width,2346); assert.equal(mobile.canvas.height,1056);
const desktop=fixture(false); desktop.window.rhapsodyPrepareCanvas(desktop.config);
assert.equal(desktop.config.canvasResizePolicy,2); assert.equal(desktop.canvas.width,1280);
console.log('Phone browser canvas: rotation, safe-area size, DPR, delayed engine boot and desktop isolation PASS');
