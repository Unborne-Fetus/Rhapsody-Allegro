// Phone browser ergonomics; feature detection keeps unsupported APIs optional.
(() => {
  const coarse = () => navigator.maxTouchPoints > 0;
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
