#!/bin/bash
echo "📱 Настройка Capacitor..."

# 1. Инициализация npm проекта
if [ ! -f "package.json" ]; then
  echo "Создаю package.json..."
  npm init -y
fi

# 2. Установка Capacitor
echo ""
echo "Установка Capacitor (это займёт 2-3 минуты)..."
npm install @capacitor/core @capacitor/cli @capacitor/android --save

if [ $? -ne 0 ]; then
  echo "❌ Ошибка установки"
  echo "Попробуй: npm install --force"
  exit 1
fi

echo "✅ Capacitor установлен"

# 3. Инициализация проекта
echo ""
echo "Инициализация Capacitor..."
npx cap init "ГдеСвета" "com.gdesveta.app" --web-dir=. --android-package-name="com.gdesveta.app"

# 4. Добавление Android платформы
echo ""
echo "Добавление Android платформы..."
npx cap add android

# 5. Копирование веб-файлов
echo ""
echo "Копирование файлов..."
npx cap sync android

echo ""
echo "✅ Capacitor настроен!"
echo ""
echo "📁 Структура:"
echo "  android/ — Android проект"
echo "  www/ — твои веб-файлы"
