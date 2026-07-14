#!/bin/bash
echo "🚀 Начинаю полную автоматическую сборку APK..."

# 1. Свежий код с GitHub
echo "⬇️ Скачиваю последние изменения..."
git pull origin main

# 2. Очистка и подготовка
echo "🧹 Очищаю старые сборки..."
rm -rf android/ www/
mkdir -p www
cp -r index.html manifest.json app.js styles/ src/ icons/ www/

# 3. Настройка Capacitor (быстрая)
echo "⚙️ Настраиваю Capacitor..."
npm init -y > /dev/null 2>&1
npm install @capacitor/core @capacitor/cli @capacitor/android --save > /dev/null 2>&1
npx cap init "GdeSveta" "com.gdesveta.app" --web-dir="www" > /dev/null 2>&1
npx cap add android > /dev/null 2>&1
npx cap sync android > /dev/null 2>&1

# 4. Сборка
echo "📦 Собираю APK (это займет 1-2 минуты)..."
cd android
chmod +x gradlew
./gradlew assembleDebug > /dev/null 2>&1

if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
  cp app/build/outputs/apk/debug/app-debug.apk ../gdesveta-magic.apk
  cd ..
  cp gdesveta-magic.apk ~/storage/downloads/GdeSveta_Magic.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════"
  echo "🎉 СБОРКА ЗАВЕРШЕНА УСПЕШНО!"
  echo "═══════════════════════════════════════"
  echo "📁 Файл: ~/GdeSvet/gdesveta-magic.apk"
  echo "📥 Готов к установке: ~/storage/downloads/GdeSveta_Magic.apk"
  echo ""
  echo "Удали старую версию и установи эту, чтобы проверить Утренний брифинг!"
else
  echo "❌ Ошибка сборки. Проверьте логи."
  cd ..
fi
