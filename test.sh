#!/bin/bash
# Автоматические тесты для ГдеСвета (Backend/Structure)

LOG_FILE="test_results.log"
PASS=0
FAIL=0

# Очистка лога
> "$LOG_FILE"

log() {
  echo "$1" | tee -a "$LOG_FILE"
}

check() {
  local desc="$1"
  local condition="$2"
  
  if eval "$condition"; then
    log "✅ PASS: $desc"
    ((PASS++))
  else
    log " FAIL: $desc"
    ((FAIL++))
  fi
}

echo " Запуск автоматических тестов..." | tee -a "$LOG_FILE"
echo "Дата: $(date)" | tee -a "$LOG_FILE"
echo "-----------------------------------" | tee -a "$LOG_FILE"

# 1. Проверка структуры файлов
check "index.html существует" "[ -f index.html ]"
check "app.js существует" "[ -f app.js ]"
check "globals.js существует" "[ -f src/globals.js ]"
check "EntryCard.js существует" "[ -f src/ui/components/EntryCard.js ]"
check "main.css существует" "[ -f styles/main.css ]"

# 2. Проверка критических функций в коде (grep)
check "Функция initTheme есть в app.js" "grep -q 'function initTheme' app.js"
check "Функция deleteEntry есть в globals.js" "grep -q 'window.deleteEntry' src/globals.js"
check "Функция refreshAllViews есть в globals.js" "grep -q 'function refreshAllViews' src/globals.js"
check "Тёмная тема есть в CSS" "grep -q 'body.dark-theme' styles/main.css"
check "Кнопка темы есть в index.html" "grep -q 'themeToggle' index.html"

# 3. Проверка отсутствия старых багов
check "attachEvents НЕ вызывается в CalendarView" "! grep 'attachEvents' | grep -v '//' src/views/CalendarView.js"
check "attachEvents НЕ вызывается в WorkView" "! grep 'attachEvents' | grep -v '//' src/views/WorkView.js"

# 4. Запуск сервера и проверка ответа
echo "🌐 Запуск тестового сервера..." | tee -a "$LOG_FILE"
pkill -f "python.*http.server.*8000" 2>/dev/null
python -m http.server 8000 > /dev/null 2>&1 &
SERVER_PID=$!
sleep 2

check "Сервер отвечает на localhost:8000" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8000 | grep -q 200"

# Остановка сервера
kill $SERVER_PID 2>/dev/null

echo "-----------------------------------" | tee -a "$LOG_FILE"
echo "📊 ИТОГО: Пройдено $PASS, Провалено $FAIL" | tee -a "$LOG_FILE"

if [ $FAIL -eq 0 ]; then
  echo "🎉 Все автоматические тесты пройдены!" | tee -a "$LOG_FILE"
else
  echo "⚠️ Есть проваленные тесты. Смотри $LOG_FILE" | tee -a "$LOG_FILE"
fi
