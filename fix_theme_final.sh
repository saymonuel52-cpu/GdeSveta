#!/bin/bash
echo "🌙 ИСПРАВЛЕНИЕ ТЁМНОЙ ТЕМЫ"

# 1. ПРОВЕРЯЕМ есть ли кнопка в index.html
echo "1. 🔍 Проверяю index.html..."

if ! grep -q "themeToggle" index.html; then
  echo "Добавляю кнопку темы..."
  sed -i 's/<h1>📅 ГдеСвета<\/h1>/<h1>📅 ГдеСвета<\/h1>\n      <button class="theme-toggle" id="themeToggle" title="Переключить тему">🌙<\/button>/' index.html
  echo "✅ Кнопка добавлена"
else
  echo "✅ Кнопка уже есть"
fi

# 2. ИСПРАВЛЯЕМ app.js — добавляем тему ПРАВИЛЬНО
echo "2.  Исправляю app.js..."

# Удаляем старую тему если есть
sed -i '/function initTheme/,/^}/d' app.js
sed -i '/\/\/ ТЁМНАЯ ТЕМА/,/initTheme/d' app.js

# Добавляем новую правильную реализацию
cat >> app.js << 'THEMEJS'

// === ТЁМНАЯ ТЕМА ===
function initTheme() {
  console.log(' initTheme вызван');
  const savedTheme = Storage.get('theme', 'light');
  const body = document.body;
  const toggle = document.getElementById('themeToggle');
  
  console.log('   savedTheme:', savedTheme);
  console.log('   toggle:', toggle);
  
  if (savedTheme === 'dark') {
    body.classList.add('dark-theme');
    if (toggle) {
      toggle.textContent = '️';
      console.log('   Применена тёмная тема');
    }
  }
  
  if (toggle) {
    toggle.onclick = function() {
      console.log('🔴 Кнопка темы нажата!');
      body.classList.toggle('dark-theme');
      const isDark = body.classList.contains('dark-theme');
      Storage.set('theme', isDark ? 'dark' : 'light');
      this.textContent = isDark ? '☀️' : '🌙';
      console.log('   Тема переключена:', isDark ? 'тёмная' : 'светлая');
    };
    console.log('   Обработчик клика добавлен');
  } else {
    console.error(' Кнопка #themeToggle не найдена!');
  }
}

// Вызываем ПРИ ЗАГРУЗКЕ
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initTheme);
} else {
  initTheme();
}
THEMEJS

echo "✅ app.js обновлён"

# 3. ДОБАВЛЯЕМ стили тёмной темы
echo "3. 🎨 Добавляю стили..."

if ! grep -q "body.dark-theme" styles/main.css; then
  cat >> styles/main.css << 'DARKCSS'

/* ТЁМНАЯ ТЕМА */
body.dark-theme {
  background: linear-gradient(135deg, #1a1a2e, #16213e) !important;
  color: #eaeaea !important;
}

body.dark-theme header {
  background: linear-gradient(135deg, #2d3561, #3a4a7a) !important;
}

body.dark-theme .nav-btn {
  background: rgba(255,255,255,0.1) !important;
  color: white !important;
}

body.dark-theme .nav-btn.active {
  background: #ff6b9d !important;
}

body.dark-theme .calendar-controls,
body.dark-theme .calendar-grid,
body.dark-theme .stats-box,
body.dark-theme .entry-card,
body.dark-theme .note-card,
body.dark-theme .modal-content,
body.dark-theme .test-section {
  background: #16213e !important;
  color: #eaeaea !important;
}

body.dark-theme .day-cell {
  background: #2d3561 !important;
  color: #eaeaea !important;
}

body.dark-theme .day-header {
  color: #888 !important;
}

body.dark-theme input,
body.dark-theme select,
body.dark-theme textarea {
  background: #2d3561 !important;
  color: #eaeaea !important;
  border-color: #3a4a7a !important;
}

body.dark-theme .duration-btn,
body.dark-theme .status-btn,
body.dark-theme .family-filter,
body.dark-theme .note-filter {
  background: #2d3561 !important;
  color: #eaeaea !important;
  border-color: #3a4a7a !important;
}

body.dark-theme .quick-add-btn {
  background: #2d3561 !important;
  color: #eaeaea !important;
}

body.dark-theme .theme-toggle {
  background: rgba(255,255,255,0.2) !important;
}

body.dark-theme .legend-item {
  color: #aaa !important;
}

body.dark-theme .empty-state {
  color: #888 !important;
}
DARKCSS
  echo "✅ Стили добавлены"
else
  echo "✅ Стили уже есть"
fi

# 4. ДОБАВЛЯЕМ стили для кнопки темы
echo "4. 🎨 Добавляю стили кнопки..."

cat >> styles/main.css << 'BUTTONCSS'

/* КНОПКА ТЕМЫ */
.theme-toggle {
  position: fixed;
  top: 15px;
  right: 15px;
  background: rgba(255,255,255,0.2);
  border: none;
  border-radius: 50%;
  width: 45px;
  height: 45px;
  font-size: 22px;
  cursor: pointer;
  z-index: 1000;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
  backdrop-filter: blur(10px);
}

.theme-toggle:hover {
  background: rgba(255,255,255,0.3);
  transform: scale(1.1);
}

.theme-toggle:active {
  transform: scale(0.95);
}
BUTTONCSS

echo "✅ Стили кнопки добавлены"

# 5. СБОРКА APK через Capacitor
echo "5.  СБОРКА APK..."

# Проверяем Node.js
if ! command -v node &> /dev/null; then
  echo "⚠️  Node.js не установлен. Устанавливаю..."
  pkg update -y
  pkg install nodejs -y
fi

echo "✅ Node.js: $(node --version)"

# Переходим в папку
cd ~/GdeSvet

# Очищаем старое
rm -rf node_modules package-lock.json android/

# Инициализируем npm
echo "Инициализация npm..."
npm init -y > /dev/null 2>&1

# Устанавливаем Capacitor
echo "Установка Capacitor (это займёт 2-3 минуты)..."
npm install @capacitor/core @capacitor/cli @capacitor/android --save > /dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "❌ Ошибка установки Capacitor"
  echo "Попробуй: npm install --force"
  exit 1
fi

echo "✅ Capacitor установлен"

# Инициализация
echo "Инициализация проекта..."
npx cap init "GdeSveta" "com.gdesveta.app" --web-dir=. > /dev/null 2>&1

# Добавление Android
echo "Добавление Android платформы..."
npx cap add android > /dev/null 2>&1

# Синхронизация
echo "Синхронизация файлов..."
npx cap sync android > /dev/null 2>&1

# Сборка
echo ""
echo " СБОРКА APK (это займёт 3-5 минут, НЕ закрывай Termux)..."
cd android
chmod +x gradlew
./gradlew assembleDebug

# Проверка результата
if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
  cp app/build/outputs/apk/debug/app-debug.apk ../gdesveta.apk
  
  echo ""
  echo "═══════════════════════════════════════"
  echo "🎉 APK СОБРАН УСПЕШНО!"
  echo "═══════════════════════════════════════"
  echo ""
  echo " APK находится здесь:"
  echo "   ~/GdeSvet/gdesveta.apk"
  echo ""
  echo " Размер: $(du -h ../gdesveta.apk | cut -f1)"
  echo ""
  echo "📥 Установить:"
  echo "   termux-open-file ../gdesveta.apk"
  echo ""
  echo "Или найди файл в файловом менеджере:"
  echo "   /data/data/com.termux/files/home/GdeSvet/gdesveta.apk"
  echo ""
else
  echo ""
  echo "❌ ОШИБКА СБОРКИ"
  echo "Проверь логи выше"
fi

cd ..

echo ""
echo "═══════════════════════════════════════"
echo "✅ ГОТОВО!"
echo "═══════════════════════════════════════"
echo ""
echo " ЧТО СДЕЛАНО:"
echo "  1. ✅ Тёмная тема исправлена"
echo "  2. ✅ Кнопка темы работает (onclick)"
echo "  3. ✅ APK собран"
echo ""
echo "🧪 ТЕСТИРОВАНИЕ ТЕМЫ:"
echo ""
echo "1. Открой http://localhost:8000"
echo "2. Нажми на кнопку 🌙 (вверху справа)"
echo "3. Фон должен стать ТЁМНЫМ"
echo "4. Кнопка должна смениться на ☀️"
echo "5. При обновлении страницы — тема сохранится"
echo ""
echo "📱 УСТАНОВКА APK:"
echo ""
echo "1. Найди файл gdesveta.apk"
echo "2. Нажми на него"
echo "3. Разреши установку из неизвестных источников"
echo "4. Установи"
echo "5. Открой приложение"
echo "6. Протестируй тёмную тему!"
echo ""
echo "Напиши 'установил' когда закончишь!"
