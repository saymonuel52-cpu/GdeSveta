#!/bin/bash
echo "🔨 Сборка проекта..."

# Проверка структуры
echo "📁 Проверка структуры..."
if [ ! -d "src/core" ]; then
  echo "❌ Папка src/core не найдена!"
  exit 1
fi

# Проверка модулей
echo "📦 Проверка модулей..."
modules=(
  "src/core/storage.js"
  "src/core/events.js"
  "src/core/utils.js"
  "src/core/store.js"
)

for module in "${modules[@]}"; do
  if [ -f "$module" ]; then
    echo "✅ $module"
  else
    echo "❌ $module не найден!"
    exit 1
  fi
done

# Запуск сервера
echo "🚀 Запуск сервера..."
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

# Открытие браузера
if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000?v=$(date +%s)"
  echo "✅ Браузер открыт!"
else
  echo "📱 Открой вручную: http://localhost:8000"
fi

echo ""
echo "✅ Сборка завершена!"
