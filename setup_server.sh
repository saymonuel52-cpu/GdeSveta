#!/bin/bash
echo " Настройка сервера с кэшем и автозапуском..."

# 1. Создаём структуру
mkdir -p logs
mkdir -p ~/.termux/boot

echo "📁 Структура создана"

# 2. Скрипт запуска сервера
cat > start_server.sh << 'START'
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
START

chmod +x start_server.sh
echo "✅ start_server.sh создан"

# 3. Скрипт остановки
cat > stop_server.sh << 'STOP'
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
STOP

chmod +x stop_server.sh
echo "✅ stop_server.sh создан"

# 4. Скрипт перезапуска с очисткой кэша
cat > restart_server.sh << 'RESTART'
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
RESTART

chmod +x restart_server.sh
echo "✅ restart_server.sh создан"

# 5. Скрипт статуса
cat > status_server.sh << 'STATUS'
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
STATUS

chmod +x status_server.sh
echo "✅ status_server.sh создан"

# 6. Автозапуск при загрузке телефона
cat > ~/.termux/boot/start-gdesveta.sh << 'BOOT'
#!/data/data/com.termux/files/usr/bin/bash
# Автозапуск ГдеСвета при загрузке телефона

cd ~/GdeSvet

# Ждём 10 секунд после загрузки
sleep 10

# Запускаем сервер
nohup python -m http.server 8000 > logs/server.log 2>&1 &
echo "✅ ГдеСвета автозапущена" >> logs/boot.log
BOOT

chmod +x ~/.termux/boot/start-gdesveta.sh
echo "✅ Автозапуск настроен"

# 7. Инструкция по установке termux-boot
cat > AUTOBOOT_SETUP.md << 'MD'
# Автозапуск ГдеСвета

## Установка termux-boot

⚠️ **Важно:** termux-boot доступен только в F-Droid, НЕ в Google Play!

### Шаги:

1. **Установи F-Droid** (если нет):
   - Скачай с https://f-droid.org
   - Установи APK

2. **Установи termux-boot через F-Droid**:
   - Открой F-Droid
   - Найди "Termux:Boot"
   - Установи

3. **Включи автозапуск**:
   - Открой приложение "Termux:Boot" один раз
   - Разреши автозапуск в настройках Android

4. **Проверь**:
   - Перезагрузи телефон
   - Открой браузер
   - Перейди на http://localhost:8000

## Если не работает:

- Проверь что файл `~/.termux/boot/start-gdesveta.sh` существует
- Проверь права: `chmod +x ~/.termux/boot/start-gdesveta.sh`
- Смотри лог: `cat ~/GdeSvet/logs/boot.log`
MD

echo "✅ AUTOBOOT_SETUP.md создан"

# 8. Создаём .gitignore
cat > .gitignore << 'GIT'
logs/
*.log
*.pid
.env
.DS_Store
node_modules/
GIT

echo "✅ .gitignore создан"

# 9. Запускаем сервер
echo ""
echo "═══════════════════════════════════════"
echo " ЗАПУСК СЕРВЕРА..."
echo "═══════════════════════════════════════"
echo ""

./start_server.sh

echo ""
echo "═══════════════════════════════════════"
echo "✅ НАСТРОЙКА ЗАВЕРШЕНА!"
echo "═══════════════════════════════════════"
echo ""
echo "📁 Созданные файлы:"
echo "  ✅ start_server.sh   — запуск"
echo "  ✅ stop_server.sh    — остановка"
echo "  ✅ restart_server.sh — перезапуск с очисткой кэша"
echo "  ✅ status_server.sh  — проверка статуса"
echo "  ✅ ~/.termux/boot/start-gdesveta.sh — автозапуск"
echo "  ✅ AUTOBOOT_SETUP.md — инструкция"
echo ""
echo "📋 Команды:"
echo "  ./start_server.sh    # Запустить"
echo "  ./stop_server.sh     # Остановить"
echo "  ./restart_server.sh  # Перезапустить (с очисткой кэша)"
echo "  ./status_server.sh   # Проверить статус"
echo "  tail -f logs/server.log  # Следить за логом"
echo ""
echo "🔄 Для очистки кэша браузера:"
echo "  Открой: http://localhost:8000?v=\$(date +%s)"
echo ""
echo "📱 Автозапуск:"
echo "  Установи termux-boot из F-Droid"
echo "  Смотри AUTOBOOT_SETUP.md"
