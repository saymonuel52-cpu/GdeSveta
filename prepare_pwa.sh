#!/bin/bash
echo "📱 Подготовка PWA для сборки APK..."

# 1. Создаём правильный manifest.json
cat > manifest.json << 'MANIFEST'
{
  "name": "ГдеСвета — Семейный ежедневник",
  "short_name": "ГдеСвета",
  "description": "Ежедневник для мамы-мастера: работа, семья, дети, собака",
  "start_url": "./index.html",
  "display": "standalone",
  "background_color": "#fef9f9",
  "theme_color": "#ff6b9d",
  "orientation": "portrait",
  "icons": [
    {
      "src": "icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ],
  "categories": ["productivity", "lifestyle"],
  "lang": "ru"
}
MANIFEST

echo "✅ manifest.json создан"

# 2. Создаём папку иконок
mkdir -p icons

# 3. Генерируем иконки через SVG → PNG (без внешних зависимостей)
# Создаём простую SVG иконку
cat > icons/icon.svg << 'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#ff6b9d;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#ff8e53;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="512" height="512" rx="100" fill="url(#grad)"/>
  <text x="256" y="320" font-family="Arial" font-size="280" font-weight="bold" text-anchor="middle" fill="white">ГС</text>
</svg>
SVG

echo "✅ SVG иконка создана"

# 4. Конвертируем SVG в PNG через Python (есть в Termux)
python3 << 'PYTHON'
import base64
import struct
import zlib

def create_png(size, filename):
    """Создаём простой PNG с градиентом и текстом"""
    # PNG header
    png = b'\x89PNG\r\n\x1a\n'
    
    # IHDR chunk
    width = size
    height = size
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data) & 0xffffffff
    png += struct.pack('>I', 13) + b'IHDR' + ihdr_data + struct.pack('>I', ihdr_crc)
    
    # IDAT chunk (простой розовый градиент)
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'  # filter byte
        for x in range(width):
            # Градиент от #ff6b9d к #ff8e53
            ratio = (x + y) / (width + height)
            r = int(255)
            g = int(107 + (142 - 107) * ratio)
            b = int(157 + (83 - 157) * ratio)
            raw_data += bytes([r, g, b])
    
    compressed = zlib.compress(raw_data)
    idat_crc = zlib.crc32(b'IDAT' + compressed) & 0xffffffff
    png += struct.pack('>I', len(compressed)) + b'IDAT' + compressed + struct.pack('>I', idat_crc)
    
    # IEND chunk
    iend_crc = zlib.crc32(b'IEND') & 0xffffffff
    png += struct.pack('>I', 0) + b'IEND' + struct.pack('>I', iend_crc)
    
    with open(filename, 'wb') as f:
        f.write(png)
    print(f"✅ Создан {filename} ({size}x{size})")

create_png(192, 'icons/icon-192.png')
create_png(512, 'icons/icon-512.png')
PYTHON

echo "✅ PNG иконки созданы"

# 5. Обновляем service-worker.js для PWA
cat > service-worker.js << 'SW'
const CACHE_NAME = 'gdesveta-v1';
const urlsToCache = [
  './',
  './index.html',
  './styles/main.css',
  './app.js',
  './manifest.json',
  './icons/icon-192.png',
  './icons/icon-512.png'
];

// Установка — кэшируем файлы
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
  self.skipWaiting();
});

// Активация — удаляем старые кэши
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(names => 
      Promise.all(names.filter(n => n !== CACHE_NAME).map(n => caches.delete(n)))
    )
  );
  self.clients.claim();
});

// Fetch — сначала кэш, потом сеть
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => response || fetch(event.request))
  );
});
SW

echo "✅ service-worker.js обновлён"

# 6. Добавляем регистрацию service worker в index.html
# Проверяем, есть ли уже регистрация
if ! grep -q "serviceWorker" index.html; then
  # Добавляем перед закрывающим </body>
  sed -i '/<\/body>/i \  <script>\n    if ("serviceWorker" in navigator) {\n      navigator.serviceWorker.register("./service-worker.js")\n        .then(() => console.log("✅ Service Worker зарегистрирован"))\n        .catch(err => console.error("❌ SW ошибка:", err));\n    }\n  </script>' index.html
  echo "✅ Service Worker добавлен в index.html"
else
  echo "⚠️  Service Worker уже есть в index.html"
fi

# 7. Создаём ZIP для онлайн-конвертеров
echo ""
echo " Создаю ZIP для загрузки в конвертеры..."
zip -r gdesveta-pwa.zip \
  index.html \
  manifest.json \
  service-worker.js \
  app.js \
  styles/ \
  src/ \
  icons/ \
  -x "*.bak" "*.backup*" "logs/*" "*.pid" 2>/dev/null

if [ -f "gdesveta-pwa.zip" ]; then
  SIZE=$(du -h gdesveta-pwa.zip | cut -f1)
  echo "✅ ZIP создан: gdesveta-pwa.zip ($SIZE)"
else
  echo "❌ Не удалось создать ZIP (zip не установлен)"
  echo "   Установи: pkg install zip"
fi

echo ""
echo "═══════════════════════════════════════"
echo "✅ ПОДГОТОВКА PWA ЗАВЕРШЕНА!"
echo "═══════════════════════════════════════"
echo ""
echo "📁 Создано:"
echo "  ✅ manifest.json — метаданные PWA"
echo "  ✅ icons/icon-192.png — иконка 192x192"
echo "  ✅ icons/icon-512.png — иконка 512x512"
echo "  ✅ service-worker.js — офлайн-режим"
echo "  ✅ gdesveta-pwa.zip — для конвертеров"
echo ""
echo " СЛЕДУЮЩИЙ ШАГ: Сборка APK"
echo ""
echo "Выбери способ:"
echo "  1. PWA Builder (онлайн, самый простой)"
echo "  2. WebIntoApp (онлайн, альтернатива)"
echo "  3. Локальная сборка через Node.js"
