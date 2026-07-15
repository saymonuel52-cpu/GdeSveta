#!/bin/bash
echo " ИСПРАВЛЯЮ КНОПКУ НАСТРОЕК..."

# 1. Проверяем, существует ли файл ScheduleSettings.js
if [ ! -f "src/ui/components/ScheduleSettings.js" ]; then
  echo "⚠️ Файл ScheduleSettings.js не найден, создаю заново..."
  
  cat > src/ui/components/ScheduleSettings.js << 'SETTINGS'
/**
 * SCHEDULE SETTINGS UI - ИСПРАВЛЕННАЯ ВЕРСИЯ
 */

const ScheduleSettings = {
  open: function() {
    console.log('⚙️ ScheduleSettings.open() вызван!');
    const settings = ScheduleRules.getSettings();
    const dayNames = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
    
    const content = `
      <form id="scheduleForm" onsubmit="return window.saveScheduleSettings(event)">
        <label>Рабочие дни</label>
        <div style="display:grid;grid-template-columns:repeat(7,1fr);gap:8px;margin:10px 0;">
          ${[0,1,2,3,4,5,6].map(day => `
            <label style="display:flex;flex-direction:column;align-items:center;padding:10px;background:#f5f5f5;border-radius:8px;cursor:pointer;">
              <input type="checkbox" name="workDays" value="${day}" 
                ${settings.workDays.includes(day) ? 'checked' : ''} style="margin-bottom:5px;">
              <span>${dayNames[day]}</span>
            </label>
          `).join('')}
        </div>
        
        <label>Начало рабочего дня</label>
        <input type="time" id="workStart" value="${settings.workStart}" required style="width:100%;padding:10px;margin:5px 0;border:2px solid #e0e0e0;border-radius:8px;">
        
        <label>Конец рабочего дня</label>
        <input type="time" id="workEnd" value="${settings.workEnd}" required style="width:100%;padding:10px;margin:5px 0;border:2px solid #e0e0e0;border-radius:8px;">
        
        <label style="display:flex;align-items:center;gap:10px;margin:10px 0;">
          <input type="checkbox" id="lunchEnabled" 
            ${settings.lunchBreak.enabled ? 'checked' : ''}
            onchange="document.getElementById('lunchSettings').style.display = this.checked ? 'block' : 'none'"
            style="width:20px;height:20px;">
          <span>Обеденный перерыв</span>
        </label>
        
        <div id="lunchSettings" style="display: ${settings.lunchBreak.enabled ? 'block' : 'none'}">
          <label>Начало обеда</label>
          <input type="time" id="lunchStart" value="${settings.lunchBreak.start}" style="width:100%;padding:10px;margin:5px 0;border:2px solid #e0e0e0;border-radius:8px;">
          
          <label>Конец обеда</label>
          <input type="time" id="lunchEnd" value="${settings.lunchBreak.end}" style="width:100%;padding:10px;margin:5px 0;border:2px solid #e0e0e0;border-radius:8px;">
        </div>
        
        <label>Буфер между записями (минут)</label>
        <input type="number" id="bufferTime" value="${settings.bufferTime}" min="0" max="60" style="width:100%;padding:10px;margin:5px 0;border:2px solid #e0e0e0;border-radius:8px;">
        
        <label>Максимум записей в день</label>
        <input type="number" id="maxBookings" value="${settings.maxBookingsPerDay}" min="1" max="20" style="width:100%;padding:10px;margin:5px 0;border:2px solid #e0e0e0;border-radius:8px;">
        
        <div style="display:flex;gap:10px;margin-top:15px;">
          <button type="submit" style="flex:1;padding:12px;background:#ff6b9d;color:white;border:none;border-radius:10px;font-weight:600;cursor:pointer;">Сохранить</button>
          <button type="button" onclick="Modal.close()" style="flex:1;padding:12px;background:#e0e0e0;color:#333;border:none;border-radius:10px;font-weight:600;cursor:pointer;">Отмена</button>
        </div>
      </form>
    `;
    
    Modal.form({ title: '⚙️ Настройки рабочего времени', content });
  }
};

// Глобальная функция сохранения
window.saveScheduleSettings = function(e) {
  e.preventDefault();
  console.log('💾 Сохранение настроек...');
  
  const workDays = Array.from(document.querySelectorAll('input[name="workDays"]:checked'))
    .map(cb => parseInt(cb.value));
  
  if (workDays.length === 0) {
    Modal.alert('❌ Выберите хотя бы один рабочий день!');
    return false;
  }
  
  const settings = {
    workDays,
    workStart: document.getElementById('workStart').value,
    workEnd: document.getElementById('workEnd').value,
    lunchBreak: {
      enabled: document.getElementById('lunchEnabled').checked,
      start: document.getElementById('lunchStart').value,
      end: document.getElementById('lunchEnd').value
    },
    bufferTime: parseInt(document.getElementById('bufferTime').value),
    maxBookingsPerDay: parseInt(document.getElementById('maxBookings').value)
  };
  
  ScheduleRules.saveSettings(settings);
  Modal.close();
  Modal.alert('✅ Настройки сохранены!');
  
  return false;
};

window.ScheduleSettings = ScheduleSettings;
console.log('✅ ScheduleSettings загружен');
SETTINGS
  
  echo "✅ ScheduleSettings.js создан"
fi

# 2. Проверяем ScheduleRules.js
if [ ! -f "src/services/ScheduleRules.js" ]; then
  echo "⚠️ ScheduleRules.js не найден, создаю..."
  
  cat > src/services/ScheduleRules.js << 'RULES'
const ScheduleRules = {
  defaults: {
    workDays: [1, 2, 3, 4, 5, 6],
    workStart: '09:00',
    workEnd: '20:00',
    lunchBreak: { start: '13:00', end: '14:00', enabled: false },
    bufferTime: 10,
    maxBookingsPerDay: 8
  },

  getSettings: function() {
    const saved = Storage.get('scheduleRules', null);
    return saved ? JSON.parse(saved) : this.defaults;
  },

  saveSettings: function(settings) {
    Storage.set('scheduleRules', JSON.stringify(settings));
  },

  isWorkDay: function(date) {
    const settings = this.getSettings();
    const dayOfWeek = new Date(date).getDay();
    return settings.workDays.includes(dayOfWeek);
  },

  isWorkTime: function(time) {
    const settings = this.getSettings();
    const [hours, minutes] = time.split(':').map(Number);
    const timeInMinutes = hours * 60 + minutes;
    const [startHours, startMinutes] = settings.workStart.split(':').map(Number);
    const [endHours, endMinutes] = settings.workEnd.split(':').map(Number);
    const startInMinutes = startHours * 60 + startMinutes;
    const endInMinutes = endHours * 60 + endMinutes;
    return timeInMinutes >= startInMinutes && timeInMinutes <= endInMinutes;
  },

  validateBooking: function(date, time, duration) {
    const errors = [];
    if (!this.isWorkDay(date)) errors.push('❌ Этот день — выходной');
    if (!this.isWorkTime(time)) errors.push('️ Время вне рабочих часов');
    return { valid: errors.length === 0, errors };
  }
};

window.ScheduleRules = ScheduleRules;
console.log('✅ ScheduleRules загружен');
RULES
  
  echo "✅ ScheduleRules.js создан"
fi

# 3. Проверяем подключение в index.html
if ! grep -q "ScheduleRules.js" index.html; then
  echo "Добавляю ScheduleRules.js в index.html..."
  sed -i '/<script src="src\/services\/Predictor.js"><\/script>/a \  <script src="src/services/ScheduleRules.js"></script>' index.html
fi

if ! grep -q "ScheduleSettings.js" index.html; then
  echo "Добавляю ScheduleSettings.js в index.html..."
  sed -i '/<script src="src\/ui\/components\/FamilySelect.js"><\/script>/a \  <script src="src/ui/components/ScheduleSettings.js"></script>' index.html
fi

echo "✅ Файлы подключены"

# 4. Проверяем кнопку в index.html
if ! grep -q "ScheduleSettings.open()" index.html; then
  echo "Добавляю кнопку настроек..."
  sed -i 's|<button class="tab-action-btn" onclick="showPriceList()">💰 Прайс</button>|<button class="tab-action-btn" onclick="showPriceList()">💰 Прайс</button>\n          <button class="tab-action-btn" onclick="ScheduleSettings.open()">⚙️ Настройки</button>|' index.html
fi

echo "✅ Кнопка добавлена"

# 5. Git + сборка
echo ""
echo "🔄 Отправка на GitHub и сборка..."

git add .
git commit -m "fix: Исправлена кнопка настроек рабочего времени"
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
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_Fixed.apk
  cd ..
  cp GdeSveta_Fixed.apk ~/storage/downloads/GdeSveta_Fixed.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "✅ ИСПРАВЛЕННАЯ ВЕРСИЯ ГОТОВА!"
  echo "═══════════════════════════════════════════════"
  echo "📁 APK: ~/storage/downloads/GdeSveta_Fixed.apk"
  echo ""
  echo "Удали старую версию и установи эту!"
  echo "Кнопка ⚙️ Настройки теперь должна работать!"
  echo "═══════════════════════════════════════════════"
else
  echo "❌ Ошибка сборки"
  cd ..
fi
