// Phone browser ergonomics; feature detection keeps unsupported APIs optional.
(() => {
  const coarse = () => navigator.maxTouchPoints > 0;
  // Godot's full-window policy uses innerWidth/innerHeight. On phones we own
  // the backing buffer from the canvas rect, matching safe areas and iframe size.
  window.rhapsodyPrepareCanvas = config => {
    if (!coarse()) return;
    const canvas = document.getElementById('canvas');
    if (!canvas) return;
    config.canvasResizePolicy = 0;
    let queued = false;
    function sync() {
      queued = false;
      // Embedded previews can report innerWidth wider than their visible area.
      // Bound CSS geometry first, then derive the sole backing-buffer size.
      const root = document.documentElement;
      if (root?.clientWidth && canvas.style && typeof getComputedStyle === 'function') {
        const css = getComputedStyle(canvas), viewport = window.visualViewport;
        const width = Math.min(root.clientWidth, viewport?.width || root.clientWidth);
        const height = Math.min(root.clientHeight, viewport?.height || root.clientHeight);
        const inset = key => parseFloat(css.getPropertyValue(key)) || 0;
        canvas.style.setProperty('width', Math.max(1,width-inset('left')-inset('right'))+'px','important');
        canvas.style.setProperty('height', Math.max(1,height-inset('top')-inset('bottom'))+'px','important');
      }
      const rect = canvas.getBoundingClientRect();
      if (rect.width < 1 || rect.height < 1) return;
      const ratio = window.devicePixelRatio || 1;
      const width = Math.max(1, Math.round(rect.width * ratio));
      const height = Math.max(1, Math.round(rect.height * ratio));
      if (canvas.width !== width) canvas.width = width;
      if (canvas.height !== height) canvas.height = height;
    }
    function schedule() {
      if (queued) return;
      queued = true;
      requestAnimationFrame(sync);
    }
    if (typeof ResizeObserver !== 'undefined') new ResizeObserver(schedule).observe(canvas);
    if (typeof MutationObserver !== 'undefined') new MutationObserver(schedule).observe(canvas, {attributes:true, attributeFilter:['width','height']});
    window.addEventListener('resize', schedule, {passive:true});
    window.visualViewport?.addEventListener('resize', schedule, {passive:true});
    window.addEventListener('orientationchange', () => {
      schedule(); setTimeout(schedule, 150); setTimeout(schedule, 450);
    }, {passive:true});
    sync(); schedule();
  };
  let wake = null;
  async function keepAwake() {
    if (!coarse() || document.visibilityState !== 'visible' || !navigator.wakeLock || wake) return;
    try { wake = await navigator.wakeLock.request('screen'); wake.addEventListener('release', () => { wake = null; }); } catch (_) {}
  }
  window.rhapsodyFullscreen = async () => {
    const root = document.documentElement;
    try { if (!document.fullscreenElement && root.requestFullscreen) await root.requestFullscreen(); } catch (_) {}
    await keepAwake();
  };
  document.addEventListener('pointerdown', keepAwake, {passive:true});
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') keepAwake();
    else if (wake) { wake.release().catch(() => {}); wake = null; }
  });
  // Avoid a browser page gesture stealing the virtual stick or held skill.
  document.addEventListener('contextmenu', e => { if (e.target.id === 'canvas') e.preventDefault(); });
})();
