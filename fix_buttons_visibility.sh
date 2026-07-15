#!/bin/bash
echo "🎨 ИСПРАВЛЯЮ ВИДИМОСТЬ КНОПОК НА СВЕТЛОЙ ТЕМЕ..."

# Исправляем стили кнопок фильтров
cat >> styles/main.css << 'FIXSTYLES'

/* ИСПРАВЛЕНИЕ: Кнопки фильтров должны быть видны на светлой теме */
.family-filters button,
.dog-filters button,
.note-filters button {
  background: #ffffff !important;
  color: #333333 !important;
  border: 2px solid #e0e0e0 !important;
  font-weight: 600 !important;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1) !important;
}

.family-filters button:hover,
.dog-filters button:hover,
.note-filters button:hover {
  background: #f5f5f5 !important;
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.15) !important;
}

.family-filters button.active,
.dog-filters button.active,
.note-filters button.active {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53) !important;
  color: white !important;
  border-color: #ff6b9d !important;
}

/* Для тёмной темы оставляем как было */
body.dark-theme .family-filters button,
body.dark-theme .dog-filters button,
body.dark-theme .note-filters button {
  background: #1e293b !important;
  color: #f8fafc !important;
  border-color: #334155 !important;
}

body.dark-theme .family-filters button.active,
body.dark-theme .dog-filters button.active,
body.dark-theme .note-filters button.active {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53) !important;
  color: white !important;
}
FIXSTYLES

echo "✅ Стили кнопок исправлены"

# Также исправляем кнопку "Свободные окна"
sed -i 's|background:linear-gradient(135deg,#059669,#10b981);box-shadow:0 4px 12px rgba(5,150,105,0.5);border:2px solid #047857|background:linear-gradient(135deg,#059669,#10b981);color:white;border:none;border-radius:12px;font-weight:700;font-size:16px;cursor:pointer;box-shadow:0 4px 12px rgba(5,150,105,0.4);border:2px solid #047857|g' app.js

echo "✅ Кнопка 'Свободные окна' исправлена"

# Git + сборка
echo ""
echo "🔄 Отправка на GitHub и сборка..."

git add .
git commit -m "fix: Исправлена видимость кнопок фильтров на светлой теме"
git push origin main

echo "📦 Сборка APK..."
rm -rf android www
mkdir -p www
cp -r index.html manifest.json app.js styles/ src/ icons/ www/

npm init -y > /dev/null 2>&1
npm install @capacitor/core @capacitor/cli @capacitor/android --save > /dev/null 2>&1
npx cap init "GdeSveta" "com.gdesveta.app" --web-dir="www" > /dev/null 2>&1
npx cap add android > /dev/null 2>&1
npx cap sync android > /dev/null 2>&1

cd android
chmod +x gradlew
./gradlew assembleDebug > /dev/null 2>&1

if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_FixedButtons.apk
  cd ..
  cp GdeSveta_FixedButtons.apk ~/storage/downloads/GdeSveta_FixedButtons.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "✅ КНОПКИ ТЕПЕРЬ ВИДНЫ!"
  echo "═══════════════════════════════════════════════"
  echo "📁 APK: ~/storage/downloads/GdeSveta_FixedButtons.apk"
  echo ""
  echo "🎨 ЧТО ИСПРАВЛЕНО:"
  echo "• Все кнопки фильтров теперь с тёмным текстом"
  echo "• Видимая граница и тень на светлой теме"
  echo "• Активная кнопка — розовая с белым текстом"
  echo "• На тёмной теме всё как было"
  echo ""
  echo "📱 Установи и проверь — все кнопки должны быть видны!"
  echo "═══════════════════════════════════════════════"
else
  echo "❌ Ошибка сборки"
  cd ..
fi
