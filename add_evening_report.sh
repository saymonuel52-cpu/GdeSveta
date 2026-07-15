#!/bin/bash
echo " ДОБАВЛЯЮ ВЕЧЕРНИЙ ОТЧЁТ И ПЛАН НА ЗАВТРА..."

# 1. Добавляем сервис вечернего отчёта в app.js
cat >> app.js << 'EVENINGREPORT'

// === ВЕЧЕРНИЙ ОТЧЁТ И ПЛАН НА ЗАВТРА ===

// Получить статистику дня
window.getDailyStats = function(date = null) {
  if (!date) {
    date = new Date().toISOString().split('T')[0];
  }
  
  const entries = Store.getEntries().filter(e => e.date === date);
  const workEntries = entries.filter(e => e.category === 'work');
  const familyEntries = entries.filter(e => e.category === 'family' || e.category === 'dog');
  
  const completed = workEntries.filter(e => e.status === 'done');
  const cancelled = workEntries.filter(e => e.status === 'cancelled');
  const pending = workEntries.filter(e => e.status === 'new' || e.status === 'confirmed');
  
  const totalIncome = completed.reduce((sum, e) => sum + (parseInt(e.price) || 0), 0);
  const plannedIncome = workEntries.reduce((sum, e) => sum + (parseInt(e.price) || 0), 0);
  
  return {
    date,
    total: entries.length,
    work: workEntries.length,
    family: familyEntries.length,
    completed: completed.length,
    cancelled: cancelled.length,
    pending: pending.length,
    totalIncome,
    plannedIncome,
    entries: workEntries.sort((a, b) => a.time.localeCompare(b.time))
  };
};

// Получить план на завтра
window.getTomorrowPlan = function() {
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const tomorrowStr = tomorrow.toISOString().split('T')[0];
  
  const entries = Store.getEntries()
    .filter(e => e.date === tomorrowStr)
    .sort((a, b) => a.time.localeCompare(b.time));
  
  const workEntries = entries.filter(e => e.category === 'work');
  const familyEntries = entries.filter(e => e.category === 'family' || e.category === 'dog');
  
  const totalWorkTime = workEntries.reduce((sum, e) => sum + e.duration, 0);
  const totalIncome = workEntries.reduce((sum, e) => sum + (parseInt(e.price) || 0), 0);
  
  // Проверяем, не перегружен ли день
  const isOverloaded = workEntries.length > 6 || totalWorkTime > 480;
  
  return {
    date: tomorrowStr,
    entries,
    workCount: workEntries.length,
    familyCount: familyEntries.length,
    totalWorkTime,
    totalIncome,
    isOverloaded,
    entries
  };
};

// Показать вечерний отчёт
window.showEveningReport = function() {
  const today = getDailyStats();
  const tomorrow = getTomorrowPlan();
  
  const tomorrowDate = new Date(tomorrow.date).toLocaleDateString('ru-RU', { 
    weekday: 'long', 
    day: 'numeric', 
    month: 'long' 
  });
  
  let html = `
    <div style="padding:10px;">
      <h2 style="text-align:center;margin-bottom:20px;color:#1e293b;"> Итоги дня</h2>
      
      <!-- СЕГОДНЯ -->
      <div style="background:linear-gradient(135deg,#10b981,#34d399);color:white;padding:20px;border-radius:16px;margin-bottom:20px;box-shadow:0 4px 12px rgba(16,185,129,0.3);">
        <h3 style="margin:0 0 15px 0;font-size:20px;">✨ Сегодня</h3>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:15px;">
          <div style="background:rgba(255,255,255,0.2);padding:10px;border-radius:10px;text-align:center;">
            <div style="font-size:28px;font-weight:700;">${today.completed}</div>
            <div style="font-size:13px;opacity:0.9;">Выполнено</div>
          </div>
          <div style="background:rgba(255,255,255,0.2);padding:10px;border-radius:10px;text-align:center;">
            <div style="font-size:28px;font-weight:700;">${today.pending}</div>
            <div style="font-size:13px;opacity:0.9;">Запланировано</div>
          </div>
        </div>
        <div style="background:rgba(255,255,255,0.2);padding:15px;border-radius:10px;">
          <div style="display:flex;justify-content:space-between;margin-bottom:8px;">
            <span>💰 Заработано:</span>
            <b>${today.totalIncome}₽</b>
          </div>
          <div style="display:flex;justify-content:space-between;margin-bottom:8px;">
            <span> Всего записей:</span>
            <b>${today.work}</b>
          </div>
          ${today.cancelled > 0 ? `
          <div style="display:flex;justify-content:space-between;">
            <span>❌ Отменено:</span>
            <b>${today.cancelled}</b>
          </div>
          ` : ''}
        </div>
      </div>
      
      <!-- ЗАВТРА -->
      <div style="background:linear-gradient(135deg,#3b82f6,#60a5fa);color:white;padding:20px;border-radius:16px;margin-bottom:20px;box-shadow:0 4px 12px rgba(59,130,246,0.3);">
        <h3 style="margin:0 0 15px 0;font-size:20px;"> Завтра (${tomorrowDate})</h3>
        ${tomorrow.isOverloaded ? `
        <div style="background:rgba(239,68,68,0.9);padding:10px;border-radius:10px;margin-bottom:10px;text-align:center;">
          ⚠️ <b>Плотный день!</b> ${tomorrow.workCount} записей
        </div>
        ` : ''}
        <div style="background:rgba(255,255,255,0.2);padding:15px;border-radius:10px;margin-bottom:10px;">
          <div style="display:flex;justify-content:space-between;margin-bottom:8px;">
            <span>💼 Записей:</span>
            <b>${tomorrow.workCount}</b>
          </div>
          <div style="display:flex;justify-content:space-between;margin-bottom:8px;">
            <span>👨‍👩👧 Семейных дел:</span>
            <b>${tomorrow.familyCount}</b>
          </div>
          <div style="display:flex;justify-content:space-between;">
            <span>💰 Планируется:</span>
            <b>${tomorrow.totalIncome}₽</b>
          </div>
        </div>
        ${tomorrow.entries.length > 0 ? `
        <div style="font-size:14px;">
          <b>Расписание:</b>
          <div style="margin-top:8px;max-height:150px;overflow-y:auto;">
            ${tomorrow.entries.map(e => `
              <div style="background:rgba(255,255,255,0.1);padding:8px;margin:5px 0;border-radius:6px;">
                ${e.time} - ${e.name} (${e.duration} мин)
              </div>
            `).join('')}
          </div>
        </div>
        ` : '<div style="text-align:center;padding:10px;opacity:0.9;">🎉 Завтра выходной!</div>'}
      </div>
      
      <button onclick="Modal.close()" 
        style="width:100%;padding:15px;background:#e0e0e0;color:#333;border:none;border-radius:12px;font-weight:700;font-size:16px;cursor:pointer;">
        Закрыть
      </button>
    </div>
  `;
  
  Modal.form({ title: '📊 Вечерний отчёт', content: html });
};

// Автоматическая проверка времени (вызывать периодически)
window.checkEveningTime = function() {
  const now = new Date();
  const hours = now.getHours();
  const minutes = now.getMinutes();
  
  // Показываем отчёт в 20:00-22:00 если ещё не показали сегодня
  if (hours >= 20 && hours < 22) {
    const lastShown = Storage.get('eveningReportShown', '');
    const today = new Date().toISOString().split('T')[0];
    
    if (lastShown !== today) {
      // Проверяем, были ли сегодня записи
      const stats = getDailyStats();
      if (stats.work > 0) {
        setTimeout(() => {
          showEveningReport();
          Storage.set('eveningReportShown', today);
        }, 1000);
      }
    }
  }
};

// Запускаем проверку каждую минуту
setInterval(checkEveningTime, 60000);

// Проверяем сразу при загрузке
setTimeout(checkEveningTime, 2000);

console.log('✅ Вечерний отчёт загружен');
EVENINGREPORT

echo "✅ Вечерний отчёт добавлен"

# 2. Добавляем кнопку ручного вызова отчёта
sed -i 's|<button class="tab-action-btn" onclick="openRecurringForm()" style="background:#8b5cf6;color:white;border:none;padding:12px 20px;border-radius:10px;font-weight:600;cursor:pointer;">📅 Повтор</button>|<button class="tab-action-btn" onclick="openRecurringForm()" style="background:#8b5cf6;color:white;border:none;padding:12px 20px;border-radius:10px;font-weight:600;cursor:pointer;">📅 Повтор</button>\n          <button class="tab-action-btn" onclick="showEveningReport()" style="background:#10b981;color:white;border:none;padding:12px 20px;border-radius:10px;font-weight:600;cursor:pointer;">📊 Отчёт</button>|' index.html

echo "✅ Кнопка отчёта добавлена"

# Git + сборка
echo ""
echo " Отправка на GitHub и сборка..."

git add .
git commit -m "feat: Добавлен вечерний отчёт и план на завтра"
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
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_Evening.apk
  cd ..
  cp GdeSveta_Evening.apk ~/storage/downloads/GdeSveta_Evening.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "🌙 ВЕЧЕРНИЙ ОТЧЁТ ГОТОВ!"
  echo "═══════════════════════════════════════════════"
  echo "📁 APK: ~/storage/downloads/GdeSveta_Evening.apk"
  echo ""
  echo "✅ ЧТО ДОБАВЛЕНО:"
  echo "• Автоматический отчёт в 20:00-22:00"
  echo "• Итоги дня:"
  echo "  - Выполнено записей"
  echo "  - Заработано денег"
  echo "  - Отменено"
  echo "• План на завтра:"
  echo "  - Количество записей"
  echo "  - Расписание по времени"
  echo "  - Предупреждение о плотном дне"
  echo "• Кнопка '📊 Отчёт' для ручного вызова"
  echo ""
  echo "📱 ТЕСТИРОВАНИЕ:"
  echo "1. Установи GdeSveta_Evening.apk"
  echo "2. Открой вкладку 'Работа'"
  echo "3. Нажми '📊 Отчёт' (зелёная кнопка)"
  echo "4. Увидишь:"
  echo "   - Сколько выполнено сегодня"
  echo "   - Сколько заработано"
  echo "   - План на завтра с расписанием"
  echo "   - Предупреждение если завтра много записей"
  echo ""
  echo " АВТОМАТИЧЕСКИ:"
  echo "• В 20:00-22:00 отчёт откроется сам"
  echo "• Только один раз в день"
  echo "• Только если были записи сегодня"
  echo "═══════════════════════════════════════════════"
else
  echo "❌ Ошибка сборки"
  cd ..
fi
