// Installed before Godot boots; inactive on the desktop URL.
if (new URLSearchParams(location.search).get('mobile') === '1') {
	// Keep 3D at CSS-pixel resolution; the parent HTML controls retain full DPR.
	// The 3D canvas can be lighter without reducing the sharpness of the controls.
	try { Object.defineProperty(window, 'devicePixelRatio', {get: () => 1}); } catch (_) {}
  const contexts = [];
  const NativeAudioContext = window.AudioContext || window.webkitAudioContext;
  if (NativeAudioContext) {
    const Wrapped = new Proxy(NativeAudioContext, {
      construct(Target, args) {
        const context = new Target(...args);
        contexts.push(context);
        return context;
      }
    });
    window.AudioContext = Wrapped;
    if (window.webkitAudioContext) window.webkitAudioContext = Wrapped;
  }
  window.mobileEngine = {
    onCommand: null,
    unlockAudio() {
      // Called synchronously by a tap in our same-origin parent on iOS too.
      for (const context of contexts) if (context.state === 'suspended') context.resume().catch(() => {});
    },
    send(json) {
      clearInterval(statusWatch);
      parent.postMessage({channel: 'dogsled-mobile-state', data: JSON.parse(json)}, location.origin);
    }
  };
  const statusWatch = setInterval(() => {
    const failure = document.getElementById('status-notice')?.textContent?.trim();
    if (failure) {
      clearInterval(statusWatch);
      parent.postMessage({channel:'dogsled-mobile-error'}, location.origin);
    }
  }, 500);
  addEventListener('message', event => {
    if (event.source !== parent || event.origin !== location.origin || event.data?.channel !== 'dogsled-mobile-command') return;
    if (window.mobileEngine.onCommand) window.mobileEngine.onCommand(JSON.stringify(event.data.data));
  });
}
