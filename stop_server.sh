#!/bin/bash
# Остановка сервера ГдеСвета

PID_FILE="logs/server.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "⚠️  PID файл не найден"
  echo "   Возможно, сервер не запущен"
  
  # Пробуем найти по порту
  PID=$(lsof -ti:8000 2>/dev/null || fuser 8000/tcp 2>/dev/null)
  if [ -n "$PID" ]; then
    echo "🔍 Найден процесс на порту 8000: $PID"
    kill "$PID" 2>/dev/null
    echo "✅ Остановлен"
  else
    echo "❌ Сервер не найден"
  fi
  exit 0
fi

PID=$(cat "$PID_FILE")

if ps -p "$PID" > /dev/null 2>&1; then
  echo "🛑 Остановка сервера (PID: $PID)..."
  kill "$PID" 2>/dev/null
  sleep 1
  
  if ps -p "$PID" > /dev/null 2>&1; then
    echo "⚠️  Принудительная остановка..."
    kill -9 "$PID" 2>/dev/null
  fi
  
  echo "✅ Сервер остановлен"
else
  echo "⚠️  Процесс $PID не найден"
fi

rm -f "$PID_FILE"
echo "🗑️  PID файл удалён"
