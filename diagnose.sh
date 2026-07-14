#!/bin/bash
echo "═══════════════════════════════════════"
echo "🔍 ДИАГНОСТИКА ПРИЛОЖЕНИЯ ГДЕСВЕТА"
echo "═══════════════════════════════════════"
echo ""

# Проверка файлов
echo " Проверка файлов..."
files=("index.html" "app.js" "manifest.json" "service-worker.js")
for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    size=$(du -h "$file" | cut -f1)
    echo "  ✅ $file ($size)"
  else
    echo "  ❌ $file — НЕ НАЙДЕН!"
  fi
done

echo ""
echo " Проверка структуры папок..."
dirs=("src/core" "src/models" "src/services" "src/views" "styles" "icons")
for dir in "${dirs[@]}"; do
  if [ -d "$dir" ]; then
    count=$(find "$dir" -type f | wc -l)
    echo "  ✅ $dir ($count файлов)"
  else
    echo "  ❌ $dir — НЕ НАЙДЕНА!"
  fi
done

echo ""
echo "🔧 Проверка функций в app.js..."
functions=("openEntryForm" "saveEntry" "initTheme" "toggleCard" "showFamilyMembers")
for func in "${functions[@]}"; do
  if grep -q "function $func" app.js; then
    echo "  ✅ $func"
  else
    echo "  ❌ $func — НЕ НАЙДЕНА!"
  fi
done

echo ""
echo "🌙 Проверка тёмной темы..."
if grep -q "dark-theme" styles/main.css; then
  echo "  ✅ CSS тёмной темы есть"
else
  echo "  ❌ CSS тёмной темы НЕТ!"
fi

if grep -q "initTheme" app.js; then
  echo "  ✅ Функция initTheme есть"
else
  echo "  ❌ Функция initTheme НЕТ!"
fi

echo ""
echo "📱 Проверка APK..."
if [ -f "android/app/build/outputs/apk/debug/app-debug.apk" ]; then
  size=$(du -h "android/app/build/outputs/apk/debug/app-debug.apk" | cut -f1)
  echo "  ✅ APK создан ($size)"
else
  echo "  ❌ APK НЕ НАЙДЕН!"
fi

echo ""
echo "═══════════════════════════════════════"
echo "✅ Диагностика завершена!"
echo "═══════════════════════════════════════"
