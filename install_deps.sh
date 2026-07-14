#!/bin/bash
echo "🔧 Установка зависимостей для сборки APK..."

# 1. Проверяем Node.js
if ! command -v node &> /dev/null; then
  echo "❌ Node.js не установлен. Устанавливаю..."
  pkg update -y
  pkg install nodejs -y
else
  echo "✅ Node.js: $(node --version)"
fi

# 2. Проверяем npm
if ! command -v npm &> /dev/null; then
  echo "❌ npm не найден"
  exit 1
else
  echo "✅ npm: $(npm --version)"
fi

# 3. Java (нужна для сборки Android)
echo ""
echo "Проверка Java..."
if ! command -v java &> /dev/null; then
  echo "⚠️  Java не установлена. Для полной сборки APK нужна."
  echo "   Установить? (это займёт ~5 минут)"
  read -p "y/n: " answer
  if [ "$answer" = "y" ]; then
    pkg install openjdk-17 -y
  fi
else
  echo "✅ Java: $(java -version 2>&1 | head -1)"
fi

# 4. Gradle (система сборки Android)
echo ""
echo "Проверка Gradle..."
if ! command -v gradle &> /dev/null; then
  echo "⚠️  Gradle не установлен."
  echo "   Capacitor может использовать встроенный Gradle."
fi

echo ""
echo "✅ Базовые зависимости готовы"
