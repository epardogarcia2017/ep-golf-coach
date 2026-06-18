// ============================================================
// EP GOLF COACH — Service Worker
// Estrategia: NETWORK-FIRST para la página (siempre busca la
// versión más nueva en el servidor; si no hay internet, usa la
// copia guardada). Así las actualizaciones se ven solas, sin
// tener que limpiar caché a mano nunca más.
// Los íconos y el manifest se sirven desde caché (rápido).
// Las notificaciones push quedan exactamente igual que antes.
// ============================================================

const CACHE = 'ep-golf-v3';
const ASSETS = ['/', '/index.html', '/manifest.json'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;

  // No tocar pedidos que no sean GET (ej: guardar reservas en Supabase)
  if (req.method !== 'GET') return;

  const url = new URL(req.url);
  const isPage =
    req.mode === 'navigate' ||
    url.pathname === '/' ||
    url.pathname.endsWith('/index.html');

  if (isPage) {
    // NETWORK-FIRST: primero el servidor (versión nueva), caché como respaldo offline
    e.respondWith(
      fetch(req)
        .then(res => {
          const copy = res.clone();
          caches.open(CACHE).then(c => c.put(req, copy)).catch(() => {});
          return res;
        })
        .catch(() => caches.match(req).then(c => c || caches.match('/index.html')))
    );
    return;
  }

  // Resto de archivos propios (íconos, manifest): caché primero, rápido
  e.respondWith(
    caches.match(req).then(cached =>
      cached ||
      fetch(req).then(res => {
        if (res.ok && url.origin === self.location.origin) {
          const copy = res.clone();
          caches.open(CACHE).then(c => c.put(req, copy)).catch(() => {});
        }
        return res;
      })
    )
  );
});

self.addEventListener('push', e => {
  const data = e.data ? e.data.json() : {};
  e.waitUntil(
    self.registration.showNotification(data.title || 'EP Golf Coach', {
      body: data.body || '',
      icon: '/icon-192.png',
      badge: '/icon-192.png',
      vibrate: [200, 100, 200],
      data: { url: data.url || '/' },
      tag: data.tag || 'ep-golf',
      renotify: true
    })
  );
});

self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(clients.openWindow(e.notification.data.url || '/'));
});
