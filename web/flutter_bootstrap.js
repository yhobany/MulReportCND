{{flutter_js}}
{{flutter_build_config}}

// Register Service Worker for PWA offline capabilities
if ('serviceWorker' in navigator) {
  function registerSW() {
    navigator.serviceWorker.register('sw.js')
      .then(function (registration) {
        console.log('CND PWA Service Worker registered with scope:', registration.scope);
      })
      .catch(function (error) {
        console.warn('CND PWA Service Worker registration failed:', error);
      });
  }

  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    registerSW();
  } else {
    window.addEventListener('load', registerSW);
  }
}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    // Fade out and remove loading indicator when app is ready
    const loader = document.getElementById('loading-indicator');
    if (loader) {
      loader.style.opacity = '0';
      loader.style.transition = 'opacity 0.4s ease-out';
      setTimeout(function () {
        if (loader.parentNode) {
          loader.parentNode.removeChild(loader);
        }
      }, 400);
    }
    await appRunner.runApp();
  }
});
