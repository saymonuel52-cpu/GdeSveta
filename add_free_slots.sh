#!/bin/bash
echo " ДОБАВЛЯЮ ВИЗУАЛЬНЫЙ ПОИСК СВОБОДНЫХ ОКОН..."

# Добавляем в app.js
cat >> app.js << 'FREESLOTS'

// === ВИЗУАЛЬНЫЙ ПОИСК СВОБОДНЫХ ОКОН ===

// Получить визуальное расписание дня
window.getDayTimeline = function(date) {
  const settings = JSON.parse(Storage.get('scheduleRules', '{"workStart":"09:00","workEnd":"20:00","bufferTime":10}'));
  const buffer = settings.bufferTime || 10;
  const [startH, startM] = settings.workStart.split(':').map(Number);
  const [endH, endM] = settings.workEnd.split(':').map(Number);
  const dayStart = startH * 60 + startM;
  const dayEnd = endH * 60 + endM;
  
  const entries = Store.getEntries()
    .filter(e => e.date === date)
    .sort((a, b) => a.time.localeCompare(b.time));
  
  const slots = [];
  let currentTime = dayStart;
  
  for (const entry of entries) {
    const [eH, eM] = entry.time.split(':').map(Number);
    const eStart = eH * 60 + eM;
    const eEnd = eStart + entry.duration;
    
    // Свободное окно перед записью
    if (eStart > currentTime) {
      slots.push({
        type: 'free',
        start: currentTime,
        end: eStart,
        duration: eStart - currentTime
      });
    }
    
    // Запись
    slots.push({
      type: 'busy',
      entry,
      start: eStart,
      end: eEnd,
      duration: entry.duration
    });
    
    // Буфер после записи
    currentTime = eEnd + buffer;
  }
  
  // Последнее свободное окно
  if (currentTime < dayEnd) {
    slots.push({
      type: 'free',
      start: currentTime,
      end: dayEnd,
      duration: dayEnd - currentTime
    });
  }
  
  return slots;
};

// Открыть визуальное расписание
window.openDayTimeline = function(date = null) {
  if (!date) {
    date = new Date().toISOString().split('T')[0];
  }
  
  const slots = getDayTimeline(date);
  const dateFormatted = new Date(date).toLocaleDateString('ru-RU', { weekday: 'long', day: 'numeric', month: 'long' });
  
  let html = `
    <div style="padding:10px;">
      <h3 style="margin:0 0 15px 0;text-align:center;text-transform:capitalize;">${dateFormatted}</h3>
      <div style="position:relative;">
  `;
  
  slots.forEach((slot, index) => {
    const startStr = `${Math.floor(slot.start/60).toString().padStart(2,'0')}:${(slot.start%60).toString().padStart(2,'0')}`;
    const endStr = `${Math.floor(slot.end/60).toString().padStart(2,'0')}:${(slot.end%60).toString().padStart(2,'0')}`;
    const duration = slot.duration;
    
    if (slot.type === 'free') {
      html += `
        <div onclick="bookFreeSlot('${date}', '${startStr}', ${duration})" 
             style="background:linear-gradient(135deg,#10b981,#34d399);color:white;padding:15px;margin:8px 0;border-radius:12px;cursor:pointer;transition:all 0.2s;box-shadow:0 2px 8px rgba(16,185,129,0.3);"
             onmouseover="this.style.transform='scale(1.02)'"
             onmouseout="this.style.transform='scale(1)'">
          <div style="font-size:18px;font-weight:700;margin-bottom:5px;">✅ Свободно: ${startStr} - ${endStr}</div>
          <div style="font-size:14px;opacity:0.9;">⏱️ ${duration} минут • Нажми, чтобы записать</div>
        </div>
      `;
    } else {
      const entry = slot.entry;
      const priority = getEventPriority(entry);
      const categoryColors = {
        work: 'linear-gradient(135deg,#ff6b9d,#ff8e53)',
        family: 'linear-gradient(135deg,#3b82f6,#60a5fa)',
        dog: 'linear-gradient(135deg,#f59e0b,#fbbf24)',
        note: 'linear-gradient(135deg,#8b5cf6,#a78bfa)'
      };
      const color = categoryColors[entry.category] || categoryColors.work;
      
      html += `
        <div style="background:${color};color:white;padding:15px;margin:8px 0;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.2);">
          <div style="font-size:18px;font-weight:700;margin-bottom:5px;">${entry.name}</div>
          <div style="font-size:14px;opacity:0.9;"> ${startStr} - ${endStr} • ⏱️ ${duration} мин</div>
          ${entry.price ? `<div style="font-size:14px;opacity:0.9;margin-top:5px;">💰 ${entry.price}₽</div>` : ''}
          <div style="font-size:11px;opacity:0.8;margin-top:5px;">${priority.label}</div>
        </div>
      `;
    }
  });
  
  if (slots.length === 0) {
    html += `<div style="text-align:center;padding:40px;color:#999;">Нет записей на этот день</div>`;
  }
  
  html += `
      </div>
      <div style="margin-top:20px;text-align:center;">
        <button onclick="Modal.close()" style="padding:12px 30px;background:#e0e0e0;color:#333;border:none;border-radius:10px;font-weight:600;cursor:pointer;">Закрыть</button>
      </div>
    </div>
  `;
  
  Modal.form({ title: ' Расписание дня', content: html });
};

// Забронировать свободное окно
window.bookFreeSlot = function(date, startTime, duration) {
  Modal.close();
  setTimeout(() => {
    openWorkForm(null);
    setTimeout(() => {
      document.getElementById('entryDate').value = date;
      document.getElementById('entryTime').value = startTime;
      document.getElementById('entryDuration').value = Math.min(duration, 60);
    }, 100);
  }, 200);
};

// Добавить кнопку в интерфейс
const _origWorkViewRender = WorkView.render;
WorkView.render = function() {
  _origWorkViewRender.apply(this, arguments);
  
  // Добавляем кнопку "Свободные окна"
  setTimeout(() => {
    const workView = document.getElementById('workView');
    if (workView && !document.getElementById('freeSlotsBtn')) {
      const btn = document.createElement('button');
      btn.id = 'freeSlotsBtn';
      btn.textContent = '🔍 Свободные окна';
      btn.style.cssText = 'width:100%;padding:15px;margin:15px 0;background:linear-gradient(135deg,#10b981,#34d399);color:white;border:none;border-radius:12px;font-weight:700;font-size:16px;cursor:pointer;box-shadow:0 4px 12px rgba(16,185,129,0.4);';
      btn.onclick = () => openDayTimeline();
      workView.insertBefore(btn, workView.firstChild);
    }
  }, 100);
};

console.log('✅ Визуальный поиск свободных окон загружен');
FREESLOTS

echo "✅ Визуальный поиск добавлен"

# Git + сборка
echo ""
echo "🔄 Отправка на GitHub и сборка..."

git add .
git commit -m "feat: Добавлен визуальный поиск свободных окон"
git push origin main

echo "📦 Сборка APK..."
rm -rf android www
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
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_FreeSlots.apk
  cd ..
  cp GdeSveta_FreeSlots.apk ~/storage/downloads/GdeSveta_FreeSlots.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "🎨 ВИЗУАЛЬНЫЙ ПОИСК СВОБОДНЫХ ОКОН ГОТОВ!"
  echo "═══════════════════════════════════════════════"
  echo "📁 APK: ~/storage/downloads/GdeSveta_FreeSlots.apk"
  echo ""
  echo "✅ ЧТО ДОБАВЛЕНО:"
  echo "• Кнопка ' Свободные окна' во вкладке Работа"
  echo "• Визуальная сетка дня с цветными блоками"
  echo "• Зелёные блоки — свободное время (кликабельные)"
  echo "• Цветные блоки — записи (розовый=работа, синий=семья)"
  echo "• При клике на свободное окно — сразу открывается форма"
  echo "• Время и дата автоматически заполняются"
  echo ""
  echo "📱 ТЕСТИРОВАНИЕ:"
  echo "1. Установи GdeSveta_FreeSlots.apk"
  echo "2. Открой вкладку 'Работа'"
  echo "3. Нажми зелёную кнопку ' Свободные окна'"
  echo "4. Увидишь расписание дня с цветными блоками"
  echo "5. Нажми на зелёный блок — откроется форма записи"
  echo "═══════════════════════════════════════════════"
else
  echo "❌ Ошибка сборки"
  cd ..
fi
