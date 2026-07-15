#!/bin/bash
echo " СОЗДАЮ ПРОСТУЮ КНОПКУ НАСТРОЕК (встроено в app.js)..."

# Добавляем функции прямо в app.js
cat >> app.js << 'SETTINGS'

// === ПРОСТЫЕ НАСТРОЙКИ РАБОЧЕГО ВРЕМЕНИ (встроено) ===
window.openScheduleSettings = function() {
  console.log('🔧 openScheduleSettings вызван!');
  
  // Получаем текущие настройки или используем значения по умолчанию
  const settings = JSON.parse(Storage.get('scheduleRules', '{"workDays":[1,2,3,4,5,6],"workStart":"09:00","workEnd":"20:00","lunchBreak":{"enabled":false,"start":"13:00","end":"14:00"},"bufferTime":10,"maxBookingsPerDay":8}'));
  
  const dayNames = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
  
  const content = `
    <form id="scheduleForm" onsubmit="return window.saveScheduleSettings(event)">
      <label style="display:block;margin-bottom:10px;font-weight:600;">Рабочие дни (отметьте галочкой):</label>
      <div style="display:grid;grid-template-columns:repeat(7,1fr);gap:8px;margin-bottom:20px;">
        ${[0,1,2,3,4,5,6].map(day => `
          <label style="display:flex;flex-direction:column;align-items:center;padding:12px;background:${settings.workDays.includes(day) ? '#ff6b9d' : '#f0f0f0'};border-radius:10px;cursor:pointer;transition:all 0.2s;">
            <input type="checkbox" name="workDays" value="${day}" 
              ${settings.workDays.includes(day) ? 'checked' : ''} 
              style="width:20px;height:20px;margin-bottom:8px;"
              onchange="this.parentElement.style.background=this.checked?'#ff6b9d':'#f0f0f0'">
            <span style="font-size:14px;font-weight:600;">${dayNames[day]}</span>
          </label>
        `).join('')}
      </div>
      
      <label style="display:block;margin-bottom:5px;font-weight:600;">Начало рабочего дня:</label>
      <input type="time" id="workStart" value="${settings.workStart}" required 
        style="width:100%;padding:12px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
      
      <label style="display:block;margin-bottom:5px;font-weight:600;">Конец рабочего дня:</label>
      <input type="time" id="workEnd" value="${settings.workEnd}" required 
        style="width:100%;padding:12px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
      
      <label style="display:flex;align-items:center;gap:10px;margin:15px 0;padding:15px;background:#f8f8f8;border-radius:10px;cursor:pointer;">
        <input type="checkbox" id="lunchEnabled" 
          ${settings.lunchBreak.enabled ? 'checked' : ''}
          onchange="document.getElementById('lunchSettings').style.display = this.checked ? 'block' : 'none'"
          style="width:22px;height:22px;">
        <span style="font-weight:600;font-size:16px;">🍽️ Обеденный перерыв</span>
      </label>
      
      <div id="lunchSettings" style="display: ${settings.lunchBreak.enabled ? 'block' : 'none'};margin-bottom:15px;">
        <label style="display:block;margin-bottom:5px;">Начало обеда:</label>
        <input type="time" id="lunchStart" value="${settings.lunchBreak.start}" 
          style="width:100%;padding:12px;margin-bottom:10px;border:2px solid #e0e0e0;border-radius:10px;">
        
        <label style="display:block;margin-bottom:5px;">Конец обеда:</label>
        <input type="time" id="lunchEnd" value="${settings.lunchBreak.end}" 
          style="width:100%;padding:12px;margin-bottom:10px;border:2px solid #e0e0e0;border-radius:10px;">
      </div>
      
      <label style="display:block;margin-bottom:5px;font-weight:600;">⏱️ Буфер между записями (минут):</label>
      <input type="number" id="bufferTime" value="${settings.bufferTime}" min="0" max="60" 
        style="width:100%;padding:12px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
      
      <div style="display:flex;gap:10px;margin-top:20px;">
        <button type="submit" 
          style="flex:1;padding:15px;background:linear-gradient(135deg,#ff6b9d,#ff8e53);color:white;border:none;border-radius:12px;font-weight:700;font-size:16px;cursor:pointer;box-shadow:0 4px 12px rgba(255,107,157,0.4);">
          💾 Сохранить настройки
        </button>
        <button type="button" onclick="Modal.close()" 
          style="flex:1;padding:15px;background:#e0e0e0;color:#333;border:none;border-radius:12px;font-weight:700;font-size:16px;cursor:pointer;">
          Отмена
        </button>
      </div>
    </form>
  `;
  
  Modal.form({ title: '⚙️ Настройки рабочего времени', content });
};

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
    maxBookingsPerDay: 8
  };
  
  Storage.set('scheduleRules', JSON.stringify(settings));
  Modal.close();
  
  setTimeout(() => {
    Modal.alert('✅ Настройки рабочего времени сохранены!\n\nТеперь при добавлении записей система будет проверять:\n• Рабочие дни\n• Рабочие часы\n• Обеденный перерыв\n• Буфер между записями');
  }, 100);
  
  return false;
};

console.log('✅ Функции настроек загружены');
SETTINGS

echo "✅ Функции добавлены в app.js"

# Обновляем кнопку в index.html — делаем максимально простой onclick
sed -i 's|<button class="tab-action-btn" onclick="ScheduleSettings.open()">⚙️ Настройки</button>|<button class="tab-action-btn" onclick="openScheduleSettings()" style="background:#667eea;color:white;border:none;padding:12px 20px;border-radius:10px;font-weight:600;cursor:pointer;">⚙️ Настройки</button>|' index.html

echo "✅ Кнопка обновлена"

# Git + сборка
echo ""
echo "🔄 Отправка на GitHub и сборка..."

git add .
git commit -m "fix: Встроены настройки прямо в app.js для надёжности"
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
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_Settings.apk
  cd ..
  cp GdeSveta_Settings.apk ~/storage/downloads/GdeSveta_Settings.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "✅ НАСТРОЙКИ ГОТОВЫ!"
  echo "═══════════════════════════════════════════════"
  echo " APK: ~/storage/downloads/GdeSveta_Settings.apk"
  echo ""
  echo "📱 ТЕСТИРОВАНИЕ:"
  echo "1. Удали старую версию приложения"
  echo "2. Установи GdeSveta_Settings.apk"
  echo "3. Открой вкладку 'Работа'"
  echo "4. Нажми на синюю кнопку '⚙️ Настройки'"
  echo "5. Должна открыться форма с настройками!"
  echo "═══════════════════════════════════════════════"
else
  echo "❌ Ошибка сборки"
  cd ..
fi
