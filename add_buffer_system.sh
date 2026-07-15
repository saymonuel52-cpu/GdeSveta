#!/bin/bash
echo "🕐 ДОБАВЛЯЮ СИСТЕМУ БУФЕРНОГО ВРЕМЕНИ..."

# Добавляем в app.js
cat >> app.js << 'BUFFER'

// === СИСТЕМА БУФЕРНОГО ВРЕМЕНИ ===

// Получить буфер для конкретной услуги
window.getServiceBuffer = function(serviceName) {
  const buffers = {
    'Шугаринг': 15,
    'LPG-массаж': 10,
    'Другое': 10
  };
  return buffers[serviceName] || 10;
};

// Проверить конфликты с учётом буфера
window.checkTimeConflicts = function(date, time, duration, serviceName, excludeId = null) {
  const settings = JSON.parse(Storage.get('scheduleRules', '{"bufferTime":10}'));
  const baseBuffer = settings.bufferTime || 10;
  const serviceBuffer = getServiceBuffer(serviceName);
  const totalBuffer = Math.max(baseBuffer, serviceBuffer);
  
  const entries = Store.getEntries()
    .filter(e => e.date === date && e.category === 'work' && e.id !== excludeId);
  
  const [newHours, newMinutes] = time.split(':').map(Number);
  const newStart = newHours * 60 + newMinutes;
  const newEnd = newStart + duration;
  
  const conflicts = [];
  
  for (const entry of entries) {
    const [eHours, eMinutes] = entry.time.split(':').map(Number);
    const eStart = eHours * 60 + eMinutes;
    const eEnd = eStart + entry.duration;
    
    // Проверяем пересечение с учётом буфера
    const bufferMinutes = totalBuffer;
    
    if (newStart < eEnd + bufferMinutes && newEnd + bufferMinutes > eStart) {
      const conflictType = (newStart >= eStart && newEnd <= eEnd) ? 'overlap' : 'too_close';
      conflicts.push({
        entry,
        type: conflictType,
        message: conflictType === 'overlap' 
          ? `⛔ Пересечение с "${entry.name}" (${entry.time}-${Entry.getEndTime(entry)})`
          : `⚠️ Слишком близко к "${entry.name}" (нужно ${bufferMinutes} мин перерыва)`
      });
    }
  }
  
  return conflicts;
};

// Найти ближайшее свободное время
window.findNextAvailableTime = function(date, desiredTime, duration, serviceName) {
  const settings = JSON.parse(Storage.get('scheduleRules', '{"workStart":"09:00","workEnd":"20:00"}'));
  const [startH, startM] = settings.workStart.split(':').map(Number);
  const [endH, endM] = settings.workEnd.split(':').map(Number);
  const dayStart = startH * 60 + startM;
  const dayEnd = endH * 60 + endM;
  
  const [dHours, dMinutes] = desiredTime.split(':').map(Number);
  let currentTime = dHours * 60 + dMinutes;
  
  // Если время уже прошло — начинаем с текущего
  const now = new Date();
  const todayStr = now.toISOString().split('T')[0];
  if (date === todayStr) {
    const nowMinutes = now.getHours() * 60 + now.getMinutes();
    if (currentTime < nowMinutes) currentTime = nowMinutes;
  }
  
  // Пробуем найти свободное окно
  while (currentTime + duration <= dayEnd) {
    const timeStr = `${Math.floor(currentTime/60).toString().padStart(2,'0')}:${(currentTime%60).toString().padStart(2,'0')}`;
    const conflicts = checkTimeConflicts(date, timeStr, duration, serviceName);
    
    if (conflicts.length === 0) {
      return timeStr;
    }
    
    // Пропускаем конфликтующую запись + буфер
    const conflict = conflicts[0].entry;
    const [eH, eM] = conflict.time.split(':').map(Number);
    currentTime = eH * 60 + eM + conflict.duration + 15;
  }
  
  return null; // Нет свободного времени
};

// Интеграция проверки в форму работы
const _origHandleWorkSubmit = window.handleWorkSubmit;
window.handleWorkSubmit = function(e) {
  e.preventDefault();
  
  const date = document.getElementById('entryDate').value;
  const time = document.getElementById('entryTime').value;
  const duration = parseInt(document.getElementById('entryDuration').value);
  const serviceType = document.getElementById('serviceType')?.value || 'Другое';
  const entryId = document.getElementById('entryId').value;
  
  // Проверяем конфликты
  const conflicts = checkTimeConflicts(date, time, duration, serviceType, entryId ? parseInt(entryId) : null);
  
  if (conflicts.length > 0) {
    const conflictMsg = conflicts.map(c => c.message).join('\n');
    const nextTime = findNextAvailableTime(date, time, duration, serviceType);
    
    let suggestMsg = '';
    if (nextTime) {
      suggestMsg = `\n\n💡 Ближайшее свободное время: ${nextTime}`;
    }
    
    Modal.confirm(
      `${conflictMsg}${suggestMsg}\n\nВсё равно сохранить?`,
      () => {
        // Пользователь согласен — сохраняем
        if (_origHandleWorkSubmit) _origHandleWorkSubmit(e);
        else {
          // Резервный вариант сохранения
          const data = {
            category: 'work',
            name: document.getElementById('clientName').value,
            phone: document.getElementById('clientPhone')?.value || '',
            date,
            time,
            duration,
            service: serviceType,
            zone: document.getElementById('serviceZone')?.value || '',
            notes: document.getElementById('entryNotes')?.value || '',
            price: parseInt(document.getElementById('entryPrice')?.value || 0),
            status: 'new'
          };
          EntryService.create(data);
          Modal.close();
          Modal.alert('✅ Запись сохранена!');
          setTimeout(() => {
            if (typeof WorkView !== 'undefined') WorkView.render();
            if (typeof CalendarView !== 'undefined') CalendarView.render();
          }, 200);
        }
      },
      () => {
        // Пользователь отменил — предлагаем свободное время
        if (nextTime) {
          document.getElementById('entryTime').value = nextTime;
          Modal.alert(`⏰ Время изменено на ${nextTime}`);
        }
      }
    );
    return false;
  }
  
  // Нет конфликтов — сохраняем
  if (_origHandleWorkSubmit) _origHandleWorkSubmit(e);
  return false;
};

// Добавляем подсказку в форму работы
const _origOpenWorkForm = window.openWorkForm;
window.openWorkForm = function(id = null) {
  if (_origOpenWorkForm) _origOpenWorkForm(id);
  
  // После открытия формы добавляем подсказку о буфере
  setTimeout(() => {
    const settings = JSON.parse(Storage.get('scheduleRules', '{"bufferTime":10}'));
    const bufferHint = document.createElement('div');
    bufferHint.id = 'bufferHint';
    bufferHint.style.cssText = 'background:#fff3e0;border-left:4px solid #ff9800;padding:10px;margin:10px 0;border-radius:8px;font-size:13px;color:#333;';
    bufferHint.innerHTML = `⏱️ Буфер между записями: <b>${settings.bufferTime || 10} мин</b> (автоматически добавляется)`;
    
    const form = document.getElementById('workForm');
    if (form && !document.getElementById('bufferHint')) {
      form.insertBefore(bufferHint, form.firstChild);
    }
  }, 100);
};

console.log('✅ Система буферного времени загружена');
BUFFER

echo "✅ Буферная система добавлена в app.js"

# Git + сборка
echo ""
echo " Отправка на GitHub и сборка..."

git add .
git commit -m "feat: Добавлена система буферного времени между записями"
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
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_Buffer.apk
  cd ..
  cp GdeSveta_Buffer.apk ~/storage/downloads/GdeSveta_Buffer.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "🕐 БУФЕРНОЕ ВРЕМЯ ГОТОВО!"
  echo "═══════════════════════════════════════════════"
  echo "✅ Автоматический буфер между записями"
  echo "✅ Разные буферы для разных услуг:"
  echo "   • Шугаринг: 15 мин"
  echo "   • LPG-массаж: 10 мин"
  echo "   • Другое: 10 мин"
  echo "✅ Предупреждение при конфликте"
  echo "✅ Автоподбор ближайшего свободного времени"
  echo "✅ Подсказка в форме о буфере"
  echo ""
  echo " ТЕСТИРОВАНИЕ:"
  echo "1. Установи GdeSveta_Buffer.apk"
  echo "2. Добавь запись на 10:00 (60 мин)"
  echo "3. Попробуй добавить вторую на 10:30"
  echo "4. Система предупредит и предложит 11:15!"
  echo ""
  echo "📁 APK: ~/storage/downloads/GdeSveta_Buffer.apk"
  echo "═══════════════════════════════════════════════"
else
  echo "❌ Ошибка сборки"
  cd ..
fi
