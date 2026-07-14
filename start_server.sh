#!/bin/bash
# Запуск сервера ГдеСвета с логированием

LOG_FILE="logs/server.log"
PID_FILE="logs/server.pid"

# Проверяем, не запущен ли уже
if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  if ps -p "$PID" > /dev/null 2>&1; then
    echo "⚠️  Сервер уже запущен (PID: $PID)"
    echo "   Используй ./stop_server.sh для остановки"
    exit 0
  else
    echo "🗑️  Удалён stale PID файл"
    rm "$PID_FILE"
  fi
fi

# Проверяем порт 8000
if netstat -tuln 2>/dev/null | grep -q ":8000 "; then
  echo "⚠️  Порт 8000 уже занят"
  echo "   Останови другой процесс или используй другой порт"
  exit 1
fi

# Запускаем сервер в фоне с логированием
echo "🚀 Запуск сервера..."
nohup python -m http.server 8000 > "$LOG_FILE" 2>&1 &
SERVER_PID=$!

# Сохраняем PID
echo "$SERVER_PID" > "$PID_FILE"

# Ждём запуска
sleep 2

# Проверяем что запустился
if ps -p "$SERVER_PID" > /dev/null 2>&1; then
  echo "✅ Сервер запущен!"
  echo "   PID: $SERVER_PID"
  echo "   URL: http://localhost:8000"
  echo "   Лог: $LOG_FILE"
  echo ""
  echo "📱 Открыть в браузере:"
  echo "   termux-open-url 'http://localhost:8000?v=$(date +%s)'"
else
  echo "❌ Ошибка запуска!"
  echo "   Смотри лог: tail -f $LOG_FILE"
  rm "$PID_FILE"
  exit 1
fi
