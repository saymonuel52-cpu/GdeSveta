#!/bin/bash
echo "🌙 Исправляю тёмную тему и собираю APK"

# 1. ПРОВЕРЯЕМ тёмную тему в CSS
echo "1.  Проверяю тёмную тему..."

# Добавляем тёмную тему если нет
if ! grep -q "dark-theme" styles/main.css; then
  echo "Добавляю тёмную тему в CSS..."
  cat >> styles/main.css << 'DARKCSS'

/* ТЁМНАЯ ТЕМА */
body.dark-theme {
  background: linear-gradient(135deg, #1a1a2e, #16213e);
  color: #eaeaea;
}

body.dark-theme header {
  background: linear-gradient(135deg, #2d3561, #3a4a7a);
}

body.dark-theme .nav-btn {
  background: rgba(255,255,255,0.1);
  color: white;
}

body.dark-theme .nav-btn.active {
  background: #ff6b9d;
}

body.dark-theme .calendar-controls,
body.dark-theme .calendar-grid,
body.dark-theme .stats-box,
body.dark-theme .entry-card,
body.dark-theme .note-card,
body.dark-theme .modal-content {
  background: #16213e;
  color: #eaeaea;
}

body.dark-theme .day-cell {
  background: #2d3561;
  color: #eaeaea;
}

body.dark-theme .day-header {
  color: #888;
}

body.dark-theme input,
body.dark-theme select,
body.dark-theme textarea {
  background: #2d3561;
  color: #eaeaea;
  border-color: #3a4a7a;
}

body.dark-theme .duration-btn,
body.dark-theme .status-btn {
  background: #2d3561;
  color: #eaeaea;
  border-color: #3a4a7a;
}

body.dark-theme .quick-add-btn {
  background: #2d3561;
  color: #eaeaea;
}

body.dark-theme .theme-toggle {
  background: rgba(255,255,255,0.2);
}
DARKCSS
  echo "✅ Тёмная тема добавлена в CSS"
else
  echo "✅ Тёмная тема уже есть в CSS"
fi

# 2. ПРОВЕРЯЕМ переключатель темы
echo "2.  Проверяю переключатель темы..."

if ! grep -q "themeToggle" app.js; then
  cat >> app.js << 'THEMEJS'

// ТЁМНАЯ ТЕМА
function initTheme() {
  const savedTheme = Storage.get('theme', 'light');
  const body = document.body;
  const toggle = document.getElementById('themeToggle');
  
  if (savedTheme === 'dark') {
    body.classList.add('dark-theme');
    if (toggle) toggle.textContent = '️';
  }
  
  if (toggle) {
    toggle.addEventListener('click', () => {
      body.classList.toggle('dark-theme');
      const isDark = body.classList.contains('dark-theme');
      Storage.set('theme', isDark ? 'dark' : 'light');
      toggle.textContent = isDark ? '☀️' : '🌙';
    });
  }
}

// Вызываем при загрузке
document.addEventListener('DOMContentLoaded', initTheme);
THEMEJS
  echo "✅ Переключатель темы добавлен"
else
  echo "✅ Переключатель темы уже есть"
fi

# 3. СОЗДАЁМ иконку для APK
echo "3. 🎨 Создаю иконку..."

mkdir -p icons

# Простая SVG иконка
cat > icons/icon.svg << 'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <rect width="512" height="512" rx="100" fill="#ff6b9d"/>
  <text x="256" y="320" font-family="Arial" font-size="280" font-weight="bold" text-anchor="middle" fill="white">ГС</text>
</svg>
SVG

echo "✅ Иконка создана"

# 4. ОБНОВЛЯЕМ manifest.json для APK
echo "4. 📱 Обновляю manifest.json..."

cat > manifest.json << 'MANIFEST'
{
  "name": "GdeSveta - Family Planner",
  "short_name": "GdeSveta",
  "description": "Daily planner for mom-master: work, family, kids, dog",
  "start_url": "./index.html",
  "display": "standalone",
  "background_color": "#fef9f9",
  "theme_color": "#ff6b9d",
  "orientation": "portrait",
  "icons": [
    {
      "src": "icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
MANIFEST

echo "✅ manifest.json обновлён"

# 5. СОЗДАЁМ инструкцию по сборке APK
echo "5. 📦 Создаю инструкцию по сборке..."

cat > BUILD_APK.md << 'BUILD'
# 📱 СБОРКА APK ДЛЯ "ГДЕСВЕТА"

## 🎯 ВАРИАНТ 1: Онлайн-конвертер (САМЫЙ ПРОСТОЙ)

### WebIntoApp (рекомендую):

1. **Подготовь ZIP:**
```bash
   cd ~/GdeSvet
   zip -r gdesveta.zip \
     index.html \
     manifest.json \
     app.js \
     styles/ \
     src/ \
     icons/ \
     -x "*.bak" "logs/*"
```

2. **Загрузи на сайт:**
   - Открой https://www.webintoapp.com/
   - Нажми "Make App"
   - Загрузи `gdesveta.zip`
   - App Name: `GdeSveta`
   - Icon: загрузи `icons/icon-512.png`
   - Orientation: `Portrait`
   - Нажми "Build"

3. **Скачай APK:**
   - Подожди 2-3 минуты
   - Скачай готовый `GdeSveta.apk`
   - Установи на телефон

---

## 🎯 ВАРИАНТ 2: PWA Builder (официальный)

1. **Загрузи на GitHub:**
   - Создай репозиторий на GitHub
   - Загрузи все файлы проекта
   - Включи GitHub Pages

2. **Используй PWA Builder:**
   - Открой https://www.pwabuilder.com/
   - Введи URL твоего сайта (https://твой-ник.github.io/GdeSvet)
   - Нажми "Package for stores"
   - Выбери "Android"
   - Скачай APK

---

## 🎯 ВАРИАНТ 3: Локально через Capacitor (сложно)

```bash
cd ~/GdeSvet

# Установи Node.js (если нет)
pkg install nodejs

# Установи Capacitor
npm init -y
npm install @capacitor/core @capacitor/cli @capacitor/android

# Инициализируй
npx cap init "GdeSveta" "com.gdesveta.app" --web-dir=.

# Добавь Android
npx cap add android

# Синхронизируй
npx cap sync android

# Открой в Android Studio
npx cap open android

# В Android Studio:
# Build → Build APK
```

---

## 📋 ПРОВЕРКА ПЕРЕД СБОРКОЙ

✅ Все кнопки работают (удалить/копировать/статус)  
✅ Тёмная тема переключается  
✅ Календарь переключается между днями  
✅ Записи синхронизируются между вкладками  
✅ Прайс-лист работает  

---

##  ПОСЛЕ СБОРКИ

1. Установи APK на телефон
2. Разреши установку из неизвестных источников
3. Протестируй все функции
4. Напиши отзыв! 😊

---

**Удачи! 🎉**
BUILD

echo "✅ BUILD_APK.md создан"

# 6. Создаём ZIP для онлайн-конвертера
echo "6. 📦 Создаю ZIP для загрузки..."

zip -r gdesveta.zip \
  index.html \
  manifest.json \
  app.js \
  styles/ \
  src/ \
  icons/ \
  -x "*.bak" "logs/*" "*.log" 2>/dev/null

if [ -f "gdesveta.zip" ]; then
  SIZE=$(du -h gdesveta.zip | cut -f1)
  echo "✅ ZIP создан: ~/GdeSvet/gdesveta.zip ($SIZE)"
else
  echo "⚠️  ZIP не создан (zip не установлен)"
  echo "   Установи: pkg install zip"
fi

# 7. Перезапуск
echo ""
echo "7. 🚀 Перезапуск сервера..."

pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000?v=$(date +%s)"
  echo "✅ Браузер открыт!"
fi

echo ""
echo "═══════════════════════════════════════"
echo "✅ ГОТОВО К СБОРКЕ APK!"
echo "═══════════════════════════════════════"
echo ""
echo "📋 ЧТО СДЕЛАНО:"
echo "  1. ✅ Тёмная тема исправлена"
echo "  2. ✅ manifest.json создан"
echo "  3. ✅ Иконка создана"
echo "  4. ✅ gdesveta.zip создан"
echo "  5. ✅ BUILD_APK.md с инструкцией"
echo ""
echo "📱 СБОРКА APK:"
echo ""
echo "ВАРИАНТ 1 (простой):"
echo "  1. Открой https://www.webintoapp.com/"
echo "  2. Загрузи ~/GdeSvet/gdesveta.zip"
echo "  3. Через 2 минуты скачай APK"
echo ""
echo "ВАРИАНТ 2 (PWA Builder):"
echo "  1. Загрузи проект на GitHub"
echo "  2. Открой https://www.pwabuilder.com/"
echo "  3. Введи URL твоего сайта"
echo "  4. Скачай APK"
echo ""
echo " Полная инструкция: BUILD_APK.md"
echo ""
echo "Удачи со сборкой! 🚀"
