#!/bin/bash
echo "🧠 Добавляю Магический модуль (Prediction Engine)..."

# 1. Создаем сервис предсказаний (адаптирован под нашу архитектуру без import/export)
cat > src/services/Predictor.js << 'PREDICTOR'
/**
 * PREDICTION ENGINE
 * Анализирует историю и дает умные подсказки
 */

const Predictor = {
  // Получает клиентов, которым пора напомнить о себе (не были дольше среднего интервала)
  getClientsToRemind: function() {
    const entries = Store.getEntries().filter(e => e.category === 'work' && e.status === 'done');
    const reminders = [];
    const clientHistory = {};

    // Группируем по имени клиента
    entries.forEach(entry => {
      if (!clientHistory[entry.name]) clientHistory[entry.name] = [];
      clientHistory[entry.name].push(new Date(entry.date));
    });

    const today = new Date();

    for (const [name, dates] of Object.entries(clientHistory)) {
      if (dates.length < 2) continue; // Нужно минимум 2 визита для прогноза

      dates.sort((a, b) => b - a); // Сортируем от новых к старым
      const lastVisit = dates[0];
      
      // Считаем средний интервал в днях
      let totalDays = 0;
      for (let i = 0; i < dates.length - 1; i++) {
        const diffTime = Math.abs(dates[i] - dates[i+1]);
        totalDays += Math.ceil(diffTime / (1000 * 60 * 60 * 24)); 
      }
      const avgInterval = Math.round(totalDays / (dates.length - 1));
      
      const daysSinceLastVisit = Math.ceil(Math.abs(today - lastVisit) / (1000 * 60 * 60 * 24));
      
      // Если прошло больше времени, чем средний интервал минус 3 дня (запас)
      if (daysSinceLastVisit >= (avgInterval - 3)) {
        reminders.push({
          name: name,
          lastVisit: lastVisit.toLocaleDateString('ru-RU'),
          daysAgo: daysSinceLastVisit,
          avgInterval: avgInterval
        });
      }
    }
    return reminders;
  },

  // Генерирует данные для утреннего брифинга
  getMorningBriefing: function() {
    const todayStr = new Date().toISOString().split('T')[0];
    const allEntries = Store.getEntries();
    
    const todayWork = allEntries.filter(e => e.category === 'work' && e.date === todayStr);
    const todayFamily = allEntries.filter(e => (e.category === 'family' || e.category === 'dog') && e.date === todayStr);
    const reminders = this.getClientsToRemind();
    
    const todayIncome = todayWork.reduce((sum, e) => sum + (parseInt(e.price) || 0), 0);

    return {
      date: new Date().toLocaleDateString('ru-RU', { weekday: 'long', day: 'numeric', month: 'long' }),
      workCount: todayWork.length,
      familyCount: todayFamily.length,
      income: todayIncome,
      reminders: reminders
    };
  }
};

window.Predictor = Predictor;
PREDICTOR

echo "✅ Predictor.js создан"

# 2. Добавляем скрипт в index.html (перед закрывающим </body>)
if ! grep -q "Predictor.js" index.html; then
  sed -i 's|<script src="src/globals.js"></script>|<script src="src/services/Predictor.js"></script>\n  <script src="src/globals.js"></script>|' index.html
  echo "✅ Predictor.js подключен к index.html"
fi

# 3. Добавляем Утренний брифинг на главный экран (в CalendarView или в начало app.js)
# Мы добавим его как красивую карточку в верхнюю часть вкладки Календарь
cat > patch_briefing.js << 'PATCH'

// === ФУНКЦИЯ ОТРИСОВКИ УТРЕННЕГО БРИФИНГА ===
function renderMorningBriefing() {
  const briefing = Predictor.getMorningBriefing();
  const calendarView = document.getElementById('calendarView');
  if (!calendarView) return;

  let reminderHtml = '';
  if (briefing.reminders.length > 0) {
    reminderHtml = `<div style="background:#fff3e0; border-left:4px solid #ff9800; padding:10px; margin-top:10px; border-radius:4px;">
      <b>🔔 Пора напомнить о себе (${briefing.reminders.length}):</b>
      <ul style="margin:5px 0 0 20px; padding:0; font-size:13px;">
        ${briefing.reminders.slice(0, 3).map(r => `<li><b>${r.name}</b> (был ${r.daysAgo} дн. назад, средн. интервал: ${r.avgInterval} дн.)</li>`).join('')}
      </ul>
    </div>`;
  }

  const briefingHtml = `
    <div style="background: linear-gradient(135deg, #ff6b9d, #ff8e53); color: white; padding: 15px; border-radius: 12px; margin-bottom: 15px; box-shadow: 0 4px 10px rgba(255,107,157,0.3);">
      <h3 style="margin:0 0 10px 0; font-size:18px;">☀️ Доброе утро, Света!</h3>
      <p style="margin:0 0 10px 0; opacity:0.9; font-size:14px; text-transform:capitalize;">${briefing.date}</p>
      <div style="display:flex; justify-content:space-between; text-align:center;">
        <div><div style="font-size:20px; font-weight:bold;">${briefing.workCount}</div><div style="font-size:12px; opacity:0.8;">Записей</div></div>
        <div><div style="font-size:20px; font-weight:bold;">${briefing.income}₽</div><div style="font-size:12px; opacity:0.8;">Доход сегодня</div></div>
        <div><div style="font-size:20px; font-weight:bold;">${briefing.familyCount}</div><div style="font-size:12px; opacity:0.8;">Семейных дел</div></div>
      </div>
      ${reminderHtml}
    </div>
  `;

  // Вставляем брифинг ПЕРЕД календарем
  const container = document.getElementById('calendarContainer') || calendarView;
  if (container.firstChild && container.firstChild.id !== 'morningBriefing') {
    const div = document.createElement('div');
    div.id = 'morningBriefing';
    div.innerHTML = briefingHtml;
    container.insertBefore(div, container.firstChild);
  }
}

// Вызываем при инициализации и при смене вкладки
const originalCalendarRender = CalendarView.render;
CalendarView.render = function() {
  originalCalendarRender.apply(this, arguments);
  setTimeout(renderMorningBriefing, 100); // Небольшая задержка, чтобы DOM успел отрисоваться
};
PATCH

cat patch_briefing.js >> app.js
rm patch_briefing.js
echo "✅ Утренний брифинг добавлен в код"

# 4. АВТОМАТИЗАЦИЯ: Git Commit + Push + Подготовка к сборке
echo ""
echo "🔄 Синхронизация с GitHub и подготовка сборки..."

git add .
git commit -m "feat: Добавлен Магический модуль (Prediction Engine) и Утренний брифинг"
git push origin main

if [ $? -eq 0 ]; then
  echo "✅ Код успешно отправлен на GitHub!"
else
  echo "⚠️ Ошибка при git push. Проверьте подключение."
fi

echo ""
echo "🎉 МАГИЯ ДОБАВЛЕНА!"
echo "Перезапустите сервер: pkill -f 'python.*http.server'; python -m http.server 8000 &"
echo "И откройте http://localhost:8000, чтобы увидеть Утренний брифинг!"
