#!/bin/bash
echo "🚀 ЗАПУСК ПОЛНОЙ АВТОМАТИЗАЦИИ..."
echo "⏳ Пожалуйста, подожди 2-3 минуты, не закрывай Termux..."

# 1. Останавливаем старые процессы
pkill -f "python.*http.server" 2>/dev/null

# 2. Создаем Магический модуль (Predictor)
mkdir -p src/services
cat > src/services/Predictor.js << 'PREDICTOR'
const Predictor = {
  getClientsToRemind: function() {
    const entries = Store.getEntries().filter(e => e.category === 'work' && e.status === 'done');
    const reminders = [];
    const clientHistory = {};
    entries.forEach(entry => {
      if (!clientHistory[entry.name]) clientHistory[entry.name] = [];
      clientHistory[entry.name].push(new Date(entry.date));
    });
    const today = new Date();
    for (const [name, dates] of Object.entries(clientHistory)) {
      if (dates.length < 2) continue;
      dates.sort((a, b) => b - a);
      const lastVisit = dates[0];
      let totalDays = 0;
      for (let i = 0; i < dates.length - 1; i++) {
        totalDays += Math.ceil(Math.abs(dates[i] - dates[i+1]) / (1000 * 60 * 60 * 24)); 
      }
      const avgInterval = Math.round(totalDays / (dates.length - 1));
      const daysSinceLastVisit = Math.ceil(Math.abs(today - lastVisit) / (1000 * 60 * 60 * 24));
      if (daysSinceLastVisit >= (avgInterval - 3)) {
        reminders.push({ name: name, daysAgo: daysSinceLastVisit, avgInterval: avgInterval });
      }
    }
    return reminders;
  },
  getMorningBriefing: function() {
    const todayStr = new Date().toISOString().split('T')[0];
    const allEntries = Store.getEntries();
    const todayWork = allEntries.filter(e => e.category === 'work' && e.date === todayStr);
    const todayFamily = allEntries.filter(e => (e.category === 'family' || e.category === 'dog') && e.date === todayStr);
    return {
      date: new Date().toLocaleDateString('ru-RU', { weekday: 'long', day: 'numeric', month: 'long' }),
      workCount: todayWork.length,
      familyCount: todayFamily.length,
      income: todayWork.reduce((sum, e) => sum + (parseInt(e.price) || 0), 0),
      reminders: this.getClientsToRemind()
    };
  }
};
window.Predictor = Predictor;
PREDICTOR

# 3. Внедряем Predictor в index.html
sed -i '/<\/body>/i \  <script src="src/services/Predictor.js"></script>' index.html

# 4. Внедряем Утренний брифинг в app.js
cat >> app.js << 'BRIEFING'
function renderMorningBriefing() {
  if (typeof Predictor === 'undefined') return;
  const briefing = Predictor.getMorningBriefing();
  const container = document.getElementById('calendarView');
  if (!container || document.getElementById('morningBriefing')) return;

  let reminderHtml = '';
  if (briefing.reminders.length > 0) {
    reminderHtml = `<div style="background:#fff3e0; border-left:4px solid #ff9800; padding:10px; margin-top:10px; border-radius:4px; color:#333;">
      <b>🔔 Пора напомнить о себе:</b>
      <ul style="margin:5px 0 0 20px; padding:0; font-size:13px;">
        ${briefing.reminders.slice(0, 3).map(r => `<li><b>${r.name}</b> (был ${r.daysAgo} дн. назад)</li>`).join('')}
      </ul>
    </div>`;
  }

  const html = `
    <div id="morningBriefing" style="background: linear-gradient(135deg, #ff6b9d, #ff8e53); color: white; padding: 15px; border-radius: 12px; margin-bottom: 15px; box-shadow: 0 4px 10px rgba(255,107,157,0.3);">
      <h3 style="margin:0 0 10px 0; font-size:18px;">☀️ Доброе утро, Света!</h3>
      <p style="margin:0 0 10px 0; opacity:0.9; font-size:14px; text-transform:capitalize;">${briefing.date}</p>
      <div style="display:flex; justify-content:space-between; text-align:center;">
        <div><div style="font-size:20px; font-weight:bold;">${briefing.workCount}</div><div style="font-size:12px; opacity:0.8;">Записей</div></div>
        <div><div style="font-size:20px; font-weight:bold;">${briefing.income}₽</div><div style="font-size:12px; opacity:0.8;">Доход</div></div>
        <div><div style="font-size:20px; font-weight:bold;">${briefing.familyCount}</div><div style="font-size:12px; opacity:0.8;">Семья</div></div>
      </div>
      ${reminderHtml}
    </div>
  `;
  container.insertAdjacentHTML('afterbegin', html);
}
const _oldCalRender = CalendarView.render;
CalendarView.render = function() { _oldCalRender.apply(this, arguments); setTimeout(renderMorningBriefing, 200); };
BRIEFING

# 5. Отправка на GitHub
echo "📤 Отправляю изменения на GitHub..."
git add .
git commit -m "feat: Добавлен Магический модуль и Утренний брифинг"
git push origin main

# 6. Полная пересборка APK
echo "📦 Начинаю сборку нового APK (это займет время)..."
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
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_Magic.apk
  cd ..
  cp GdeSveta_Magic.apk ~/storage/downloads/GdeSveta_Magic.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "🎉 ВСЁ ГОТОВО! МАГИЯ СОЗДАНА И СОБРАНА!"
  echo "═══════════════════════════════════════════════"
  echo "✅ Код обновлен на GitHub"
  echo "✅ Новый APK с Утренним брифингом создан"
  echo "📁 Путь к файлу: ~/storage/downloads/GdeSveta_Magic.apk"
  echo ""
  echo "👉 ТЕПЕРЬ ПРОСТО:"
  echo "1. Открой файловый менеджер телефона"
  echo "2. Зайди в папку 'Загрузки' (Downloads)"
  echo "3. Удали старое приложение ГдеСвета"
  echo "4. Нажми на GdeSveta_Magic.apk и установи его"
  echo "═══════════════════════════════════════════════"
else
  echo "❌ ОШИБКА СБОРКИ. Напиши мне 'ошибка', я посмотрю логи."
  cd ..
fi
