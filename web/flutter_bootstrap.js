// Desby OS — custom Flutter web bootstrap.
//
// Flutter's default template registers `flutter_service_worker.js` on every
// page load. This project ships a service worker that deliberately unregisters
// itself and then force-navigates every open window client, so each load ran:
//
//   register -> activate -> unregister -> client.navigate() -> register -> ...
//
// which is an infinite reload loop. The app never finished booting and every
// refresh made it worse.
//
// The project's nginx config already declares the intent: main.dart.js is NOT
// content-hashed, so it must revalidate on every load, and the service worker is
// served `no-cache, no-store`. Caching via a service worker is therefore not in
// use here. `serviceWorkerSettings: null` stops Flutter registering it at all.
//
// Keeping this file also lets us keep the renderer configuration explicit rather
// than relying on the generated default.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: null,
  onEntrypointLoaded: async function (engineInitializer) {
    const engine = await engineInitializer.initializeEngine();
    await engine.runApp();
  },
});
