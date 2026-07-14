#!/bin/bash
# Статус сервера

PID_FILE="logs/server.pid"
LOG_FILE="logs/server.log"

echo "📊 Статус сервера ГдеСвета"
echo "═══════════════════════════"
echo ""

if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  if ps -p "$PID" > /dev/null 2>&1; then
    echo "✅ Сервер ЗАПУЩЕН"
    echo "   PID: $PID"
    echo "   URL: http://localhost:8000"
    echo ""
    
    # Размер лога
    if [ -f "$LOG_FILE" ]; then
      SIZE=$(du -h "$LOG_FILE" | cut -f1)
      echo "📝 Лог: $LOG_FILE ($SIZE)"
      echo ""
      echo "📋 Последние 5 строк лога:"
      tail -5 "$LOG_FILE" | sed 's/^/   /'
    fi
  else
    echo "❌ PID файл есть, но процесс не запущен"
    echo "   Запусти: ./start_server.sh"
  fi
else
  echo "⚠️  Сервер НЕ запущен"
  echo "   Запусти: ./start_server.sh"
fi

echo ""
echo "═══════════════════════════"
echo "Команды:"
echo "  ./start_server.sh   — запустить"
echo "  ./stop_server.sh    — остановить"
echo "  ./restart_server.sh — перезапустить"
echo "  ./status_server.sh  — статус"
echo "  tail -f logs/server.log — следить за логом"
