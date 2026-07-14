#!/bin/bash
# Перезапуск сервера с очисткой кэша

echo "🔄 Перезапуск сервера..."
echo ""

# Останавливаем
./stop_server.sh
echo ""

# Очищаем кэш браузера (через timestamp в URL)
TIMESTAMP=$(date +%s)
echo " Кэш будет очищен через параметр URL: ?v=$TIMESTAMP"
echo ""

# Запускаем
./start_server.sh
echo ""

if [ -f "logs/server.pid" ]; then
  echo "📱 Открыть приложение:"
  echo "   termux-open-url 'http://localhost:8000?v=$TIMESTAMP'"
  echo ""
  echo " Чтобы очистить кэш в браузере:"
  echo "   1. Открой http://localhost:8000?v=$TIMESTAMP"
  echo "   2. Или: Настройки браузера → Очистить кэш"
fi
