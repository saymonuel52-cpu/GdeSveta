#!/bin/bash
echo "🔧 ИСПРАВЛЕНИЕ И СБОРКА..."

# 1. Проверяем app.js
if [ ! -f "app.js" ]; then
  echo "❌ app.js не найден!"
  exit 1
fi

echo "✅ app.js существует"

# 2. Создаём недостающие View файлы
echo "📁 Проверка View файлов..."

# CalendarView
if [ ! -f "src/views/CalendarView.js" ]; then
  cat > src/views/CalendarView.js << 'CVIEW'
const CalendarView = {
  render: function() {
    const container = document.getElementById('calendarView');
    if (!container) return;
    const today = new Date();
    const monthNames = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
    let html = '<div style="padding:20px;">';
    html += '<h3 style="text-align:center;margin-bottom:20px;">' + monthNames[today.getMonth()] + ' ' + today.getFullYear() + '</h3>';
    html += '<div style="background:white;padding:30px;border-radius:12px;text-align:center;">';
    html += '<p style="font-size:18px;">Сегодня: ' + today.getDate() + ' ' + monthNames[today.getMonth()] + '</p>';
    html += '<p style="color:#999;margin-top:20px;">Календарь загружен успешно</p>';
    html += '</div></div>';
    container.innerHTML = html;
  }
};
window.CalendarView = CalendarView;
console.log('CalendarView загружен');
CVIEW
  echo "✅ CalendarView.js создан"
fi

# WorkView
if [ ! -f "src/views/WorkView.js" ]; then
  cat > src/views/WorkView.js << 'WVIEW'
const WorkView = {
  render: function() {
    const container = document.getElementById('workView');
    if (!container) return;
    let html = '<div style="padding:20px;">';
    html += '<h3 style="margin-bottom:20px;">Работа</h3>';
    html += '<div style="background:#f5f5f5;padding:30px;border-radius:12px;text-align:center;">';
    html += '<p style="color:#666;">Нет записей</p>';
    html += '<button onclick="openWorkForm()" style="margin-top:15px;padding:12px 30px;background:#ff6b9d;color:white;border:none;border-radius:10px;font-size:16px;cursor:pointer;">+ Добавить запись</button>';
    html += '</div></div>';
    container.innerHTML = html;
  }
};
window.WorkView = WorkView;
console.log('WorkView загружен');
WVIEW
  echo "✅ WorkView.js создан"
fi

# FamilyView
if [ ! -f "src/views/FamilyView.js" ]; then
  cat > src/views/FamilyView.js << 'FVIEW'
const FamilyView = {
  render: function() {
    const container = document.getElementById('familyView');
    if (!container) return;
    let html = '<div style="padding:20px;">';
    html += '<h3 style="margin-bottom:20px;">Семья</h3>';
    html += '<div style="background:#f5f5f5;padding:30px;border-radius:12px;text-align:center;">';
    html += '<p style="color:#666;">Нет событий</p>';
    html += '</div></div>';
    container.innerHTML = html;
  }
};
window.FamilyView = FamilyView;
console.log('FamilyView загружен');
FVIEW
  echo "✅ FamilyView.js создан"
fi

# NotesView
if [ ! -f "src/views/NotesView.js" ]; then
  cat > src/views/NotesView.js << 'NVIEW'
const NotesView = {
  render: function() {
    const container = document.getElementById('notesView');
    if (!container) return;
    let html = '<div style="padding:20px;">';
    html += '<h3 style="margin-bottom:20px;">Заметки</h3>';
    html += '<div style="background:#f5f5f5;padding:30px;border-radius:12px;text-align:center;">';
    html += '<p style="color:#666;">Нет заметок</p>';
    html += '</div></div>';
    container.innerHTML = html;
  }
};
window.NotesView = NotesView;
console.log('NotesView загружен');
NVIEW
  echo "✅ NotesView.js создан"
fi

# StatsView
if [ ! -f "src/views/StatsView.js" ]; then
  cat > src/views/StatsView.js << 'SVIEW'
const StatsView = {
  render: function() {
    const container = document.getElementById('statsView');
    if (!container) return;
    let html = '<div style="padding:20px;">';
    html += '<h3 style="margin-bottom:20px;">Статистика</h3>';
    html += '<div style="background:#f5f5f5;padding:30px;border-radius:12px;text-align:center;">';
    html += '<p style="color:#666;">Статистика будет здесь</p>';
    html += '</div></div>';
    container.innerHTML = html;
  }
};
window.StatsView = StatsView;
console.log('StatsView загружен');
SVIEW
  echo "✅ StatsView.js создан"
fi

# DogView
if [ ! -f "src/views/DogView.js" ]; then
  cat > src/views/DogView.js << 'DVIEW'
const DogView = {
  render: function() {
    const container = document.getElementById('dogView');
    if (!container) return;
    let html = '<div style="padding:20px;">';
    html += '<h3 style="margin-bottom:20px;">Собака</h3>';
    html += '<div style="background:#f5f5f5;padding:30px;border-radius:12px;text-align:center;">';
    html += '<p style="color:#666;">Нет событий</p>';
    html += '</div></div>';
    container.innerHTML = html;
  }
};
window.DogView = DogView;
console.log('DogView загружен');
DVIEW
  echo "✅ DogView.js создан"
fi

# 3. Сборка
echo ""
echo "📦 Сборка APK..."
rm -rf android www node_modules
mkdir -p www
cp -r index.html manifest.json app.js styles/ src/ icons/ www/

npm init -y > /dev/null 2>&1
npm install @capacitor/core @capacitor/cli @capacitor/android --save > /dev/null 2>&1
npx cap init "GdeSveta" "com.gdesveta.app" --web-dir="www" > /dev/null 2>&1
npx cap add android > /dev/null 2>&1
npx cap sync android > /dev/null 2>&1

cd android
chmod +x gradlew
./gradlew assembleDebug > /dev/null 2>&1

if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_Final.apk
  cd ..
  cp GdeSveta_Final.apk ~/storage/downloads/GdeSveta_Final.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "✅ СБОРКА ЗАВЕРШЕНА!"
  echo "═══════════════════════════════════════════════"
  echo "📁 APK: ~/storage/downloads/GdeSveta_Final.apk"
  echo ""
  echo "📱 УСТАНОВКА:"
  echo "1. Удали старое приложение"
  echo "2. Очисти кэш Chrome"
  echo "3. Установи GdeSveta_Final.apk"
  echo "4. Открой и проверь вкладки"
  echo "═══════════════════════════════════════════════"
else
  echo "❌ Ошибка сборки"
  cd ..
fi
