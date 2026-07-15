#!/bin/bash
echo "📊 ДОБАВЛЯЮ СТАТИСТИКУ ЗАГРУЗКИ НЕДЕЛИ..."

# 1. Добавляем функцию статистики недели в app.js
cat >> app.js << 'WEEKLYSTATS'

// === СТАТИСТИКА ЗАГРУЗКИ НЕДЕЛИ ===

// Получить статистику загрузки недели
window.getWeeklyLoadStats = function() {
  const today = new Date();
  const currentDay = today.getDay();
  
  // Начало недели (понедельник)
  const monday = new Date(today);
  monday.setDate(today.getDate() - (currentDay === 0 ? 6 : currentDay - 1));
  monday.setHours(0, 0, 0, 0);
  
  // Конец недели (воскресенье)
  const sunday = new Date(monday);
  sunday.setDate(monday.getDate() + 6);
  sunday.setHours(23, 59, 59, 999);
  
  const days = [];
  const dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  
  for (let i = 0; i < 7; i++) {
    const date = new Date(monday);
    date.setDate(monday.getDate() + i);
    const dateStr = date.toISOString().split('T')[0];
    
    const entries = Store.getEntries()
      .filter(e => e.date === dateStr && e.category === 'work');
    
    const completed = entries.filter(e => e.status === 'done');
    const totalDuration = entries.reduce((sum, e) => sum + e.duration, 0);
    const income = completed.reduce((sum, e) => sum + (parseInt(e.price) || 0), 0);
    
    // Считаем слоты (предполагаем 8-часовой рабочий день = 8 слотов по 1 часу)
    const maxSlots = 8;
    const usedSlots = Math.ceil(totalDuration / 60);
    const loadPercent = Math.min(Math.round((usedSlots / maxSlots) * 100), 100);
    
    days.push({
      date: dateStr,
      dayName: dayNames[i],
      dayNumber: date.getDate(),
      entries: entries.length,
      completed: completed.length,
      totalDuration,
      income,
      usedSlots,
      maxSlots,
      loadPercent,
      isToday: dateStr === today.toISOString().split('T')[0]
    });
  }
  
  // Общая статистика
  const totalIncome = days.reduce((sum, d) => sum + d.income, 0);
  const totalEntries = days.reduce((sum, d) => sum + d.entries, 0);
  const totalCompleted = days.reduce((sum, d) => sum + d.completed, 0);
  const avgLoad = Math.round(days.reduce((sum, d) => sum + d.loadPercent, 0) / 7);
  
  // Найти самый загруженный и свободный день
  const busiestDay = days.reduce((max, d) => d.loadPercent > max.loadPercent ? d : max, days[0]);
  const freestDay = days.reduce((min, d) => d.loadPercent < min.loadPercent ? d : min, days[0]);
  
  return {
    days,
    totalIncome,
    totalEntries,
    totalCompleted,
    avgLoad,
    busiestDay,
    freestDay
  };
};

// Показать статистику недели
window.showWeeklyStats = function() {
  const stats = getWeeklyLoadStats();
  
  // Определяем цвета для нагрузки
  const getLoadColor = (percent) => {
    if (percent >= 80) return '#ef4444'; // красный
    if (percent >= 60) return '#f59e0b'; // оранжевый
    if (percent >= 40) return '#10b981'; // зелёный
    return '#3b82f6'; // синий
  };
  
  const getLoadBars = (percent) => {
    const filled = Math.ceil(percent / 10);
    const empty = 10 - filled;
    return '█'.repeat(filled) + '░'.repeat(empty);
  };
  
  let html = `
    <div style="padding:10px;">
      <h2 style="text-align:center;margin-bottom:20px;color:#1e293b;">📊 Загрузка недели</h2>
      
      <!-- Общая статистика -->
      <div style="background:linear-gradient(135deg,#667eea,#764ba2);color:white;padding:20px;border-radius:16px;margin-bottom:20px;box-shadow:0 4px 12px rgba(102,126,234,0.3);">
        <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:10px;text-align:center;">
          <div>
            <div style="font-size:28px;font-weight:700;">${stats.totalEntries}</div>
            <div style="font-size:13px;opacity:0.9;">Записей</div>
          </div>
          <div>
            <div style="font-size:28px;font-weight:700;">${stats.totalCompleted}</div>
            <div style="font-size:13px;opacity:0.9;">Выполнено</div>
          </div>
          <div>
            <div style="font-size:28px;font-weight:700;">${stats.totalIncome}₽</div>
            <div style="font-size:13px;opacity:0.9;">Доход</div>
          </div>
        </div>
      </div>
      
      <!-- Дни недели -->
      <div style="margin-bottom:20px;">
        ${stats.days.map(day => `
          <div style="background:white;border-radius:12px;padding:12px;margin:8px 0;box-shadow:0 2px 8px rgba(0,0,0,0.1);${day.isToday ? 'border:2px solid #667eea;' : ''}">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
              <div style="display:flex;align-items:center;gap:10px;">
                <b style="font-size:16px;color:#1e293b;">${day.dayName}, ${day.dayNumber}</b>
                ${day.isToday ? '<span style="background:#667eea;color:white;padding:2px 8px;border-radius:6px;font-size:12px;">Сегодня</span>' : ''}
              </div>
              <div style="color:#64748b;font-size:14px;">${day.entries} записей</div>
            </div>
            <div style="font-family:monospace;font-size:14px;margin:5px 0;color:${getLoadColor(day.loadPercent)};">
              ${getLoadBars(day.loadPercent)} ${day.loadPercent}%
            </div>
            <div style="display:flex;justify-content:space-between;font-size:13px;color:#64748b;margin-top:5px;">
              <span>⏱️ ${Math.round(day.totalDuration / 60)}ч ${day.totalDuration % 60}мин</span>
              <span>💰 ${day.income}₽</span>
            </div>
          </div>
        `).join('')}
      </div>
      
      <!-- Рекомендации -->
      <div style="background:#fef3c7;border-left:4px solid #f59e0b;padding:15px;border-radius:10px;margin-bottom:20px;">
        <b style="color:#92400e;">💡 Рекомендации:</b>
        <ul style="margin:8px 0 0 20px;color:#92400e;font-size:14px;">
          ${stats.busiestDay.loadPercent > 80 ? `<li>️ ${stats.busiestDay.dayName} перегружен (${stats.busiestDay.loadPercent}%) — попробуй перенести часть записей</li>` : ''}
          ${stats.freestDay.loadPercent < 30 && stats.freestDay.dayName !== 'Вс' ? `<li>✅ ${stats.freestDay.dayName} свободен (${stats.freestDay.loadPercent}%) — можно добавить записи</li>` : ''}
          ${stats.avgLoad > 70 ? `<li>🔥 Высокая средняя загрузка (${stats.avgLoad}%) — следи за выгоранием!</li>` : ''}
          ${stats.avgLoad < 40 ? `<li>📈 Низкая загрузка (${stats.avgLoad}%) — время для рекламы!</li>` : ''}
        </ul>
      </div>
      
      <button onclick="Modal.close()" 
        style="width:100%;padding:15px;background:#e0e0e0;color:#333;border:none;border-radius:12px;font-weight:700;font-size:16px;cursor:pointer;">
        Закрыть
      </button>
    </div>
  `;
  
  Modal.form({ title: '📈 Статистика недели', content: html });
};

console.log('✅ Статистика недели загружена');
WEEKLYSTATS

echo "✅ Статистика недели добавлена"

# 2. Добавляем кнопку в статистику
sed -i 's|<button class="tab-action-btn" onclick="showEveningReport()" style="background:#10b981;color:white;border:none;padding:12px 20px;border-radius:10px;font-weight:600;cursor:pointer;">📊 Отчёт</button>|<button class="tab-action-btn" onclick="showEveningReport()" style="background:#10b981;color:white;border:none;padding:12px 20px;border-radius:10px;font-weight:600;cursor:pointer;">📊 Отчёт</button>\n          <button class="tab-action-btn" onclick="showWeeklyStats()" style="background:#667eea;color:white;border:none;padding:12px 20px;border-radius:10px;font-weight:600;cursor:pointer;"> Неделя</button>|' index.html

echo "✅ Кнопка статистики недели добавлена"

# Git + сборка
echo ""
echo "🔄 Отправка на GitHub и сборка..."

git add .
git commit -m "feat: Добавлена статистика загрузки недели с рекомендациями"
git push origin main

echo " Сборка APK..."
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
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_WeeklyStats.apk
  cd ..
  cp GdeSveta_WeeklyStats.apk ~/storage/downloads/GdeSveta_WeeklyStats.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "📊 СТАТИСТИКА НЕДЕЛИ ГОТОВА!"
  echo "═══════════════════════════════════════════════"
  echo "📁 APK: ~/storage/downloads/GdeSveta_WeeklyStats.apk"
  echo ""
  echo "✅ ЧТО ПОКАЗЫВАЕТ:"
  echo "• Визуальная загрузка каждого дня (полоски)"
  echo "• Процент загрузки (0-100%)"
  echo "• Время работы и доход за день"
  echo "• Общий доход за неделю"
  echo "• Выделение сегодняшнего дня"
  echo ""
  echo "✅ УМНЫЕ РЕКОМЕНДАЦИИ:"
  echo "• Предупреждение о перегруженных днях (>80%)"
  echo "• Советы по свободным дням (<30%)"
  echo "• Предупреждение о выгорании (средняя >70%)"
  echo "• Советы по рекламе (средняя <40%)"
  echo ""
  echo "📱 ТЕСТИРОВАНИЕ:"
  echo "1. Установи GdeSveta_WeeklyStats.apk"
  echo "2. Открой вкладку 'Работа'"
  echo "3. Нажми '📈 Неделя' (фиолетовая кнопка)"
  echo "4. Увидишь:"
  echo "   - Загрузку каждого дня полосками"
  echo "   - Процент загрузки"
  echo "   - Доход за каждый день"
  echo "   - Умные рекомендации"
  echo "═══════════════════════════════════════════════"
else
  echo "❌ Ошибка сборки"
  cd ..
fi
