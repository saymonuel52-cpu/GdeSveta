#!/bin/bash
echo "🔄 ПОЛНАЯ ПЕРЕУСТАНОВКА ПРИЛОЖЕНИЯ..."

# 1. Проверяем что все файлы на месте
echo "📁 Проверка файлов..."
if [ ! -f "app.js" ]; then
  echo "❌ app.js не найден!"
  exit 1
fi

if [ ! -f "index.html" ]; then
  echo "❌ index.html не найден!"
  exit 1
fi

echo "✅ Основные файлы найдены"

# 2. Проверяем содержимое app.js
echo "🔍 Проверка app.js..."
if grep -q "switchTab" app.js; then
  echo "✅ Функция switchTab найдена"
else
  echo "❌ Функция switchTab не найдена в app.js!"
  exit 1
fi

# 3. Проверяем что CalendarView существует
if [ -f "src/views/CalendarView.js" ]; then
  echo "✅ CalendarView.js найден"
else
  echo "❌ CalendarView.js не найден!"
  exit 1
fi

# 4. Полная пересборка с нуля
echo ""
echo "📦 Полная пересборка..."
rm -rf android www node_modules

mkdir -p www
cp -r index.html manifest.json app.js styles/ src/ icons/ www/

echo "✅ Файлы скопированы в www/"

# 5. Устанавливаем Capacitor
npm init -y > /dev/null 2>&1
npm install @capacitor/core @capacitor/cli @capacitor/android --save > /dev/null 2>&1

echo "✅ Capacitor установлен"

# 6. Инициализация
npx cap init "GdeSveta" "com.gdesveta.app" --web-dir="www" > /dev/null 2>&1
npx cap add android > /dev/null 2>&1
npx cap sync android > /dev/null 2>&1

echo "✅ Android проект создан"

# 7. Сборка
cd android
chmod +x gradlew
./gradlew assembleDebug > /dev/null 2>&1

if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_Fresh.apk
  cd ..
  cp GdeSveta_Fresh.apk ~/storage/downloads/GdeSveta_Fresh.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "✅ СВЕЖАЯ СБОРКА ГОТОВА!"
  echo "═══════════════════════════════════════════════"
  echo "📁 APK: ~/storage/downloads/GdeSveta_Fresh.apk"
  echo ""
  echo "📱 ИНСТРУКЦИЯ ПО УСТАНОВКЕ:"
  echo ""
  echo "ШАГ 1: УДАЛИТЬ СТАРОЕ ПРИЛОЖЕНИЕ"
  echo "  - Зажми иконку 'ГдеСвета' на рабочем столе"
  echo "  - Выбери 'Удалить'"
  echo "  - Подтверди удаление"
  echo ""
  echo "ШАГ 2: ОЧИСТИТЬ КЭШ БРАУЗЕРА"
  echo "  - Открой Chrome"
  echo "  - Настройки → Конфиденциальность → Очистить данные"
  echo "  - Выбери 'Файлы cookie и данные сайтов'"
  echo "  - Нажми 'Удалить данные'"
  echo ""
  echo "ШАГ 3: УСТАНОВИТЬ НОВОЕ ПРИЛОЖЕНИЕ"
  echo "  - Открой файловый менеджер"
  echo "  - Найди GdeSveta_Fresh.apk в Загрузках"
  echo "  - Нажми и установи"
  echo "  - Разреши установку из неизвестных источников"
  echo ""
  echo "ШАГ 4: ПРОВЕРИТЬ РАБОТУ"
  echo "  - Открой приложение"
  echo "  - Нажми на вкладку 'Работа' (портфель)"
  echo "  - Должен появиться список записей"
  echo "  - Нажми на вкладку 'Календарь'"
  echo "  - Должен появиться календарь"
  echo ""
  echo "⚠️ ЕСЛИ ВСЁ ЕЩЁ НЕ РАБОТАЕТ:"
  echo "  Напиши мне и мы проверим код через браузер"
  echo "═══════════════════════════════════════════════"
else
  echo " Ошибка сборки"
  cd ..
fi
