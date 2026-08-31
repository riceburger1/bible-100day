const CACHE_NAME = 'yc-proverbs100-pwa-v1';
const RUNTIME_CACHE = 'yc-proverbs100-runtime-v1';
const APP_SHELL = [
  './',
  './index.html',
  './config.js',
  './manifest.json',
  './icon-192.png',
  './icon-512.png',
  './apple-touch-icon.png'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys => Promise.all(
      keys.filter(key => key !== CACHE_NAME && key !== RUNTIME_CACHE)
        .map(key => caches.delete(key))
    )).then(() => self.clients.claim())
  );
});

function isSupabaseRequest(url) {
  return url.hostname.endsWith('.supabase.co');
}

function isBibleOrLibraryRequest(url) {
  return url.hostname === 'cdn.jsdelivr.net' ||
         url.hostname === 'raw.githubusercontent.com';
}

async function networkFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  try {
    const fresh = await fetch(request);
    if (fresh && fresh.ok) cache.put(request, fresh.clone());
    return fresh;
  } catch (error) {
    const cached = await cache.match(request);
    if (cached) return cached;
    throw error;
  }
}

async function staleWhileRevalidate(request) {
  const cache = await caches.open(RUNTIME_CACHE);
  const cached = await cache.match(request);
  const network = fetch(request).then(response => {
    if (response && (response.ok || response.type === 'opaque')) {
      cache.put(request, response.clone());
    }
    return response;
  }).catch(() => null);
  return cached || network || Response.error();
}

self.addEventListener('fetch', event => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);

  // 학생 제출·관리자 조회 등 Supabase 요청은 항상 서버에서 처리합니다.
  if (isSupabaseRequest(url)) return;

  // 페이지 이동과 설정파일은 새 버전을 우선 확인합니다.
  if (request.mode === 'navigate' || url.pathname.endsWith('/config.js') || url.pathname.endsWith('/index.html')) {
    event.respondWith(networkFirst(request).catch(() => caches.match('./index.html')));
    return;
  }

  // 외부 성경 데이터와 Supabase JS 라이브러리는 한 번 받은 뒤 재사용합니다.
  if (isBibleOrLibraryRequest(url)) {
    event.respondWith(staleWhileRevalidate(request));
    return;
  }

  // 같은 사이트의 아이콘·manifest 등 정적 파일
  if (url.origin === self.location.origin) {
    event.respondWith(
      caches.match(request).then(cached => cached || fetch(request).then(response => {
        if (response && response.ok) {
          const copy = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(request, copy));
        }
        return response;
      }))
    );
  }
});
