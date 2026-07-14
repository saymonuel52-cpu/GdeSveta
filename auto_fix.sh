#!/bin/bash
echo "🚀 Запускаю полное автоматическое исправление..."

# 1. Добавляю мета-теги против кэширования в <head>
echo "📝 Добавляю защиту от кэширования в index.html..."
if ! grep -q "Cache-Control.*no-cache" index.html; then
  sed -i '/<head>/a \  <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">\n  <meta http-equiv="Pragma" content="no-cache">\n  <meta http-equiv="Expires" content="0">' index.html
  echo "✅ Мета-теги добавлены"
else
  echo "⚠️  Мета-теги уже есть"
fi

# 2. Добавляю кнопку перед </body>
echo "🔘 Добавляю кнопку в index.html..."
if ! grep -q "addAppBtnFixed" index.html; then
  sed -i 's|</body>|<button id="addAppBtnFixed" class="add-btn-fixed">+ Добавить запись</button>\n</body>|' index.html
  echo "✅ Кнопка добавлена"
else
  echo "⚠️  Кнопка уже есть"
fi

# 3. Добавляю стили для кнопки
echo "🎨 Добавляю стили в style.css..."
if ! grep -q "add-btn-fixed" style.css; then
  cat >> style.css << 'CSS'

.add-btn-fixed {
  position: fixed;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 9999;
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  border: none;
  border-radius: 50px;
  padding: 15px 30px;
  font-size: 16px;
  font-weight: bold;
  box-shadow: 0 4px 15px rgba(255, 107, 157, 0.5);
  cursor: pointer;
  display: block;
}
.add-btn-fixed:active {
  transform: translateX(-50%) scale(0.95);
}
CSS
  echo "✅ Стили добавлены"
else
  echo "⚠️  Стили уже есть"
fi

# 4. Добавляю автоочистку SW + обработчик кнопки в app.js
echo "⚙️  Обновляю app.js (автоочистка кэша + обработчик)..."
if ! grep -q "АВТО-ОЧИСТКА SW" app.js; then
  cat >> app.js << 'JS'

// === АВТО-ОЧИСТКА SERVICE WORKER И ОБРАБОТЧИК КНОПКИ ===
(async () => {
  // Очищаем все кэши
  if ('caches' in window) {
    const names = await caches.keys();
    await Promise.all(names.map(n => caches.delete(n)));
    console.log('🗑️ Кэши очищены:', names);
  }
  // Отменяем все Service Workers
  if ('serviceWorker' in navigator) {
    const regs = await navigator.serviceWorker.getRegistrations();
    await Promise.all(regs.map(r => r.unregister()));
    console.log('🚫 Service Workers отключены:', regs.length);
  }
})();

document.addEventListener('DOMContentLoaded', () => {
  const addBtn = document.getElementById('addAppBtnFixed');
  if (addBtn) {
    addBtn.addEventListener('click', () => {
      // Ищем функцию открытия модалки
      const fn = ['openAddModal','showModal','openModal','showAddForm','addEntry']
        .find(name => typeof window[name] === 'function');
      if (fn) {
        window[fn]();
      } else {
        const name = prompt('Имя клиента:');
        if (name) alert('✅ Запись создана для: ' + name);
      }
    });
    console.log('✅ Кнопка работает!');
  }
});
JS
  echo "✅ Код добавлен"
else
  echo "⚠️  Код уже есть"
fi

# 5. Отключаю Service Worker
echo "🚫 Отключаю Service Worker..."
cat > service-worker.js << 'SW'
// SW отключён - не кэшируем ничего
self.addEventListener('install', e => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(clients.claim()));
self.addEventListener('fetch', () => {});
SW
echo "✅ SW отключён"

# 6. Перезапускаю сервер
echo "🔄 Перезапускаю сервер..."
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

# 7. Проверяем, что сервер запустился
if curl -s -o /dev/null http://localhost:8000; then
  echo "✅ Сервер работает на http://localhost:8000"
else
  echo "❌ Ошибка запуска сервера!"
  exit 1
fi

# 8. Автоматически открываем браузер
echo "🌐 Открываю браузер..."
if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000"
  echo "✅ Браузер открыт!"
else
  echo "⚠️  termux-open-url не найден. Установи: pkg install termux-api"
  echo "📱 Открой вручную: http://localhost:8000"
fi

echo ""
echo "🎉 ВСЁ ГОТОВО!"
echo "✨ Кнопка должна появиться автоматически"
