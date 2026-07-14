#!/bin/bash
echo "🔨 Локальная сборка APK через Node.js + Capacitor..."

# Проверка Node.js
if ! command -v node &> /dev/null; then
  echo "❌ Node.js не установлен!"
  echo "   Установи: pkg install nodejs"
  exit 1
fi

echo "✅ Node.js: $(node --version)"

# Установка Capacitor
echo ""
echo " Установка Capacitor..."
npm init -y > /dev/null 2>&1
npm install @capacitor/core @capacitor/cli @capacitor/android > /dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "❌ Ошибка установки Capacitor"
  echo "   Попробуй: npm install --force"
  exit 1
fi

echo "✅ Capacitor установлен"

# Инициализация
npx cap init "ГдеСвета" "com.gdesveta.app" --web-dir=. > /dev/null 2>&1

# Добавление Android платформы
npx cap add android > /dev/null 2>&1

echo ""
echo "⚠️  Для полной сборки нужен Android SDK и Gradle."
echo "   Это сложно настроить в Termux."
echo ""
echo "💡 Рекомендую использовать PWA Builder или WebIntoApp"
echo "   (см. инструкцию выше)"
