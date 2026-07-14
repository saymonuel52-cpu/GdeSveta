#!/bin/bash
echo "🔧 Начинаю автоматическое исправление кнопки..."

# 1. Обновляю index.html - добавляю кнопку перед </body>
echo "📝 Обновляю index.html..."
if ! grep -q "addAppBtnFixed" index.html; then
  sed -i 's|</body>|<button id="addAppBtnFixed" class="add-btn-fixed" aria-label="Добавить запись">+ Добавить запись</button>\n</body>|' index.html
  echo "✅ Кнопка добавлена в index.html"
else
  echo "⚠️  Кнопка уже есть в index.html"
fi

# 2. Обновляю style.css - добавляю стили для кнопки
echo "🎨 Обновляю style.css..."
if ! grep -q "add-btn-fixed" style.css; then
  cat >> style.css << 'CSS'

/* Фиксированная кнопка добавления записи */
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
  transition: all 0.3s ease;
  display: block;
}

.add-btn-fixed:active {
  transform: translateX(-50%) scale(0.95);
  box-shadow: 0 2px 8px rgba(255, 107, 157, 0.6);
}
CSS
  echo "✅ Стили добавлены в style.css"
else
  echo "⚠️  Стили уже есть в style.css"
fi

# 3. Обновляю app.js - добавляю обработчик кнопки
echo "⚙️  Обновляю app.js..."
if ! grep -q "addAppBtnFixed.*addEventListener" app.js; then
  cat >> app.js << 'JS'

// === АВТОМАТИЧЕСКИЙ ОБРАБОТЧИК КНОПКИ ===
document.addEventListener('DOMContentLoaded', () => {
  const addBtn = document.getElementById('addAppBtnFixed');
  if (addBtn) {
    addBtn.addEventListener('click', () => {
      // Ищем функцию открытия модалки
      if (typeof openAddModal === 'function') {
        openAddModal();
      } else if (typeof showModal === 'function') {
        showModal();
      } else if (typeof openModal === 'function') {
        openModal();
      } else if (typeof showAddForm === 'function') {
        showAddForm();
      } else {
        console.error('❌ Функция открытия модалки не найдена!');
        alert('Ошибка: функция открытия формы не найдена. Проверь app.js');
      }
    });
    console.log('✅ Кнопка добавления записи инициализирована');
  } else {
    console.error('❌ Кнопка addAppBtnFixed не найдена в DOM');
  }
});
JS
  echo "✅ Обработчик добавлен в app.js"
else
  echo "⚠️  Обработчик уже есть в app.js"
fi

# 4. Отключаю Service Worker (временное решение)
echo "🚫 Отключаю Service Worker..."
cat > service-worker.js << 'SW'
// Service Worker временно отключён для отладки
self.addEventListener('install', (event) => {
  console.log('SW: install (отключён)');
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  console.log('SW: activate (отключён)');
  event.waitUntil(clients.claim());
});

self.addEventListener('fetch', (event) => {
  // Не кэшируем ничего, просто пропускаем запросы
});
SW
echo "✅ Service Worker отключён"

# 5. Перезапускаю сервер
echo "🔄 Перезапускаю сервер..."
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2
echo "✅ Сервер запущен на http://localhost:8000"

echo ""
echo "🎉 ГОТОВО!"
echo ""
echo "📱 Теперь открой в Chrome:"
echo "   http://localhost:8000"
echo ""
echo "🧹 Очисти кэш Chrome:"
echo "   1. Открой chrome://serviceworker-internals/"
echo "   2. Найди localhost:8000"
echo "   3. Нажми Unregister и Clear"
echo "   4. Обнови страницу (потяни вниз)"
echo ""
echo "✨ Кнопка должна появиться!"
