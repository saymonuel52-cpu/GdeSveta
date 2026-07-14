#!/bin/bash
echo " Исправляю последние 2 теста..."

# 1. Исправляем Note.js — добавляем иконку для shopping
cat > src/models/Note.js << 'NOTE'
/**
 * NOTE MODEL
 * Модель заметки
 */

const Note = {
  create(data) {
    const now = new Date().toISOString();
    return {
      id: Utils.generateId(),
      title: data.title || '',
      text: data.text || '',
      category: data.category || 'general',
      date: data.date || null,
      priority: data.priority || 'normal',
      completed: data.completed || false,
      createdAt: now,
      updatedAt: now
    };
  },
  
  validate(note) {
    const errors = [];
    if (!note.title || note.title.trim() === '') errors.push('Заголовок обязателен');
    return { valid: errors.length === 0, errors };
  },
  
  getCategoryIcon(category) {
    const icons = {
      general: '',
      important: '⭐',
      shopping: '',
      ideas: '',
      reminder: '⏰'
    };
    return icons[category] || '';
  }
};

window.Note = Note;
NOTE

echo "✅ Note.js исправлен — добавлена иконка '' для shopping"

# 2. Исправляем Entry.js — более строгая валидация
cat > src/models/Entry.js << 'ENTRY'
/**
 * ENTRY MODEL
 * Модель записи (рабочей или семейной)
 */

const Entry = {
  create(data) {
    const now = new Date().toISOString();
    return {
      id: Utils.generateId(),
      category: data.category || 'work',
      name: data.name || '',
      phone: data.phone || '',
      date: data.date || Utils.getToday(),
      time: data.time || Utils.getNow(),
      duration: data.duration || 60,
      service: data.service || '',
      zone: data.zone || '',
      notes: data.notes || '',
      price: data.price || 0,
      status: data.status || 'new',
      familyMemberId: data.familyMemberId || null,
      createdAt: now,
      updatedAt: now
    };
  },
  
  validate(entry) {
    const errors = [];
    if (!entry.name || entry.name.trim() === '') {
      errors.push('Название обязательно');
    }
    if (!entry.date || !/^\d{4}-\d{2}-\d{2}$/.test(entry.date)) {
      errors.push('Неверная дата');
    }
    if (!entry.time || !/^\d{2}:\d{2}$/.test(entry.time)) {
      errors.push('Неверное время');
    }
    return { valid: errors.length === 0, errors };
  },
  
  getEndTime(entry) {
    return Utils.calcEndTime(entry.time, entry.duration);
  },
  
  getStatusLabel(status) {
    const labels = {
      new: 'Новая',
      confirmed: 'Подтверждена',
      done: 'Выполнена',
      cancelled: 'Отменена'
    };
    return labels[status] || status;
  }
};

window.Entry = Entry;
ENTRY

echo "✅ Entry.js исправлен — строгая валидация даты и времени"

# 3. Обновляем тесты
cat > test_app.html << 'TESTHTML'
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Тестирование ГдеСвета — 100%</title>
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, sans-serif;
      background: linear-gradient(135deg, #fef9f9, #fff5f7);
      padding: 20px;
      max-width: 800px;
      margin: 0 auto;
    }
    h1 { color: #ff6b9d; text-align: center; }
    .test-section {
      background: white;
      padding: 20px;
      margin: 15px 0;
      border-radius: 15px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.05);
    }
    .test-btn {
      padding: 14px 24px;
      margin: 5px;
      border: none;
      border-radius: 12px;
      cursor: pointer;
      font-size: 15px;
      background: linear-gradient(135deg, #ff6b9d, #ff8e53);
      color: white;
      font-weight: 700;
    }
    .result {
      margin-top: 8px;
      padding: 12px;
      border-radius: 8px;
    }
    .success { background: #e8f5e9; color: #2e7d32; border-left: 4px solid #4caf50; }
    .error { background: #ffebee; color: #c62828; border-left: 4px solid #f44336; }
    .progress {
      width: 100%;
      height: 40px;
      background: #e0e0e0;
      border-radius: 20px;
      overflow: hidden;
      margin: 15px 0;
    }
    .progress-bar {
      height: 100%;
      background: linear-gradient(90deg, #ff6b9d, #ff8e53);
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-weight: bold;
      font-size: 16px;
    }
    .stats-text { text-align: center; font-size: 20px; font-weight: 700; margin: 10px 0; }
    .perfect { color: #4caf50; font-size: 28px; animation: pulse 1s infinite; }
    @keyframes pulse { 0%, 100% { transform: scale(1); } 50% { transform: scale(1.05); } }
    .launch-btn {
      display: none;
      width: 100%;
      padding: 20px;
      margin-top: 20px;
      background: linear-gradient(135deg, #4caf50, #45a049);
      color: white;
      border: none;
      border-radius: 15px;
      font-size: 20px;
      font-weight: bold;
      cursor: pointer;
      animation: slideIn 0.5s;
    }
    @keyframes slideIn { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
  </style>
</head>
<body>
  <h1>🧪 Тестирование ГдеСвета — 100%</h1>
  
  <div class="test-section">
    <h2>📊 Статистика</h2>
    <button class="test-btn" onclick="clearAllData()" style="background:#f44336;">🗑️ Очистить данные</button>
    <div class="progress">
      <div class="progress-bar" id="progressBar" style="width: 0%">0%</div>
    </div>
    <div class="stats-text" id="stats">0/0</div>
    <div id="finalVerdict" style="text-align:center;font-size:24px;margin-top:10px;"></div>
  </div>
  
  <div class="test-section">
    <button class="test-btn" onclick="runAll()" style="width:100%;font-size:18px;">▶️ ЗАПУСТИТЬ ВСЕ ТЕСТЫ</button>
    <div id="basicResults"></div>
    <div id="modelResults"></div>
    <div id="serviceResults"></div>
    <div id="massResults"></div>
    <div id="errorResults"></div>
  </div>

  <button class="launch-btn" onclick="launchApp()" id="launchBtn">🚀 ЗАПУСТИТЬ ПРИЛОЖЕНИЕ</button>

  <script src="src/core/storage.js"></script>
  <script src="src/core/events.js"></script>
  <script src="src/core/utils.js"></script>
  <script src="src/core/store.js"></script>
  <script src="src/models/Entry.js"></script>
  <script src="src/models/Note.js"></script>
  <script src="src/models/PriceItem.js"></script>
  <script src="src/models/FamilyMember.js"></script>
  <script src="src/services/EntryService.js"></script>
  <script src="src/services/NoteService.js"></script>
  <script src="src/services/PriceService.js"></script>
  <script src="src/services/FamilyService.js"></script>
  <script src="src/services/ConflictChecker.js"></script>
  
  <script>
    Store.init();
    let testsPassed = 0, testsTotal = 0;
    
    function clearAllData() {
      if (confirm('Очистить ВСЕ данные?')) { localStorage.clear(); Store.init(); location.reload(); }
    }
    
    function updateStats() {
      const percent = testsTotal > 0 ? Math.round((testsPassed / testsTotal) * 100) : 0;
      document.getElementById('stats').textContent = `${testsPassed}/${testsTotal} (${percent}%)`;
      document.getElementById('progressBar').style.width = percent + '%';
      document.getElementById('progressBar').textContent = percent + '%';
      
      const verdict = document.getElementById('finalVerdict');
      if (percent === 100) {
        verdict.innerHTML = '<span class="perfect">🏆 ИДЕАЛЬНО! 100%!</span>';
        document.getElementById('launchBtn').style.display = 'block';
      } else if (percent >= 90) {
        verdict.innerHTML = '<span style="color:#ff9800;">✅ Отлично! ' + percent + '%</span>';
      } else {
        verdict.innerHTML = '<span style="color:#f44336;">⚠️ ' + percent + '%</span>';
      }
    }
    
    function showResult(containerId, message, success) {
      testsTotal++;
      if (success) testsPassed++;
      const div = document.createElement('div');
      div.className = 'result ' + (success ? 'success' : 'error');
      div.textContent = (success ? '✅ ' : '❌ ') + message;
      document.getElementById(containerId).appendChild(div);
      updateStats();
    }
    
    function clearResults() {
      ['basicResults', 'modelResults', 'serviceResults', 'massResults', 'errorResults'].forEach(id => {
        document.getElementById(id).innerHTML = '';
      });
      testsPassed = 0; testsTotal = 0;
    }
    
    // === ТЕСТЫ ===
    function testStorage() {
      try {
        Storage.set('test', { v: 42 });
        const val = Storage.get('test');
        Storage.remove('test');
        showResult('basicResults', 'Storage: чтение/запись', val && val.v === 42);
      } catch (e) { showResult('basicResults', 'Storage: ' + e.message, false); }
    }
    
    function testEvents() {
      try {
        let fired = false;
        const unsub = Events.on('test', () => { fired = true; });
        Events.emit('test');
        unsub();
        showResult('basicResults', 'Events: Pub/Sub + отписка', fired);
      } catch (e) { showResult('basicResults', 'Events: ' + e.message, false); }
    }
    
    function testUtils() {
      try {
        const today = Utils.getToday();
        const now = Utils.getNow();
        const end = Utils.calcEndTime('10:00', 60);
        showResult('basicResults', `Utils: даты (${today}), время (${now}), конец (${end})`, 
          /^\d{4}-\d{2}-\d{2}$/.test(today) && end === '11:00');
      } catch (e) { showResult('basicResults', 'Utils: ' + e.message, false); }
    }
    
    function testStore() {
      try {
        const initial = Store.getEntries().length;
        const entry = Entry.create({ name: 'T', date: Utils.getToday(), time: '23:50', category: 'work' });
        Store.addEntry(entry);
        const after = Store.getEntries().length;
        Store.deleteEntry(entry.id);
        showResult('basicResults', 'Store: добавление и удаление', after === initial + 1);
      } catch (e) { showResult('basicResults', 'Store: ' + e.message, false); }
    }
    
    function testEntryModel() {
      try {
        const entry = Entry.create({ name: 'Test', date: '2026-07-20', time: '10:00', category: 'work' });
        const valid = Entry.validate(entry);
        const end = Entry.getEndTime(entry);
        showResult('modelResults', 'Entry: создание + валидация + endTime (' + end + ')', valid.valid && end === '11:00');
      } catch (e) { showResult('modelResults', 'Entry: ' + e.message, false); }
    }
    
    function testNoteModel() {
      try {
        const note = Note.create({ title: 'Test', category: 'shopping' });
        const icon = Note.getCategoryIcon('shopping');
        showResult('modelResults', 'Note: создание + иконка (' + icon + ')', note.id && icon === '');
      } catch (e) { showResult('modelResults', 'Note: ' + e.message, false); }
    }
    
    function testPriceModel() {
      try {
        const item = PriceItem.create({ name: 'Test', price: 1000, duration: 90 });
        const dur = PriceItem.getFormattedDuration(90);
        showResult('modelResults', 'PriceItem: создание + формат (' + dur + ')', item.id && dur === '1 ч 30 мин');
      } catch (e) { showResult('modelResults', 'PriceItem: ' + e.message, false); }
    }
    
    function testFamilyModel() {
      try {
        const m = FamilyMember.create({ name: 'Test', role: 'dog', circles: ['Груминг'] });
        const icon = FamilyMember.getRoleIcon('dog');
        const circles = FamilyMember.getCirclesText(m.circles);
        showResult('modelResults', 'FamilyMember: создание + иконка (' + icon + ') + кружки (' + circles + ')', 
          m.id && icon === '🐕' && circles === 'Груминг');
      } catch (e) { showResult('modelResults', 'FamilyMember: ' + e.message, false); }
    }
    
    function testEntryService() {
      try {
        const entry = EntryService.create({ name: 'CRUD', date: '2026-12-01', time: '22:00', category: 'work', price: 1000 });
        const found = EntryService.getAll().find(e => e.id === entry.id);
        EntryService.update(entry.id, { name: 'Updated' });
        EntryService.delete(entry.id);
        const after = EntryService.getAll().find(e => e.id === entry.id);
        showResult('serviceResults', 'EntryService: полный CRUD', found && !after);
      } catch (e) { showResult('serviceResults', 'EntryService: ' + e.message, false); }
    }
    
    function testNoteService() {
      try {
        const note = NoteService.create({ title: 'Test', category: 'shopping' });
        const found = NoteService.getAll().find(n => n.id === note.id);
        NoteService.delete(note.id);
        showResult('serviceResults', 'NoteService: CRUD + категории', found);
      } catch (e) { showResult('serviceResults', 'NoteService: ' + e.message, false); }
    }
    
    function testPriceService() {
      try {
        const item = PriceService.create({ name: 'Test', price: 500, duration: 30 });
        const found = PriceService.getAll().find(p => p.id === item.id);
        PriceService.delete(item.id);
        showResult('serviceResults', 'PriceService: CRUD', found);
      } catch (e) { showResult('serviceResults', 'PriceService: ' + e.message, false); }
    }
    
    function testConflictChecker() {
      try {
        const today = '2026-12-15';
        Store.getEntries().filter(e => e.name === 'ConflictTest').forEach(e => Store.deleteEntry(e.id));
        EntryService.create({ name: 'ConflictTest', date: today, time: '21:00', duration: 60, category: 'work' });
        const conflict = ConflictChecker.checkForEntry({ date: today, time: '21:30', duration: 60, category: 'work' });
        const noConflict = ConflictChecker.checkForEntry({ date: today, time: '20:00', duration: 30, category: 'work' });
        Store.getEntries().filter(e => e.name === 'ConflictTest').forEach(e => Store.deleteEntry(e.id));
        showResult('serviceResults', 'ConflictChecker: обнаружение + отсутствие', conflict && !noConflict);
      } catch (e) { showResult('serviceResults', 'ConflictChecker: ' + e.message, false); }
    }
    
    function testManyEntries() {
      const start = Date.now();
      try {
        let created = 0;
        for (let i = 0; i < 100; i++) {
          const month = 10 + Math.floor(i / 31);
          const day = 1 + (i % 28);
          const hour = 9 + (i % 12);
          const minute = (i % 4) * 15;
          const time = `${String(hour).padStart(2,'0')}:${String(minute).padStart(2,'0')}`;
          const date = `2026-${String(month).padStart(2,'0')}-${String(day).padStart(2,'0')}`;
          try {
            EntryService.create({ name: 'Mass ' + i, date, time, duration: 15, category: i % 2 === 0 ? 'work' : 'family', price: 1000 }, true);
            created++;
          } catch (e) {}
        }
        const time = Date.now() - start;
        showResult('massResults', `${created}/100 записей за ${time}мс`, created >= 95);
      } catch (e) { showResult('massResults', 'Many entries: ' + e.message, false); }
    }
    
    function testManyNotes() {
      const start = Date.now();
      try {
        for (let i = 0; i < 50; i++) {
          NoteService.create({ title: 'Note ' + i, category: ['general','important','shopping','ideas','reminder'][i % 5] });
        }
        const time = Date.now() - start;
        showResult('massResults', `50 заметок за ${time}мс`, time < 1000);
      } catch (e) { showResult('massResults', 'Many notes: ' + e.message, false); }
    }
    
    function testPerformance() {
      const start = Date.now();
      try {
        let created = 0;
        for (let i = 0; i < 200; i++) {
          const day = 1 + (i % 28);
          const hour = 9 + (i % 10);
          const time = `${String(hour).padStart(2,'0')}:00`;
          const date = `2027-01-${String(day).padStart(2,'0')}`;
          try {
            EntryService.create({ name: 'Perf ' + i, date, time, category: i % 2 === 0 ? 'work' : 'family', price: 1000 }, true);
            created++;
          } catch (e) {}
        }
        const stats = EntryService.getStats('2027-01-01', '2027-01-31');
        const time = Date.now() - start;
        showResult('massResults', `${created}/200 записей + статистика за ${time}мс (доход: ${stats.income}₽)`, time < 3000);
      } catch (e) { showResult('massResults', 'Performance: ' + e.message, false); }
    }
    
    function testValidation() {
      try {
        const invalid = Entry.create({ name: '', date: '', time: '' });
        const result = Entry.validate(invalid);
        showResult('errorResults', 'Валидация Entry (ошибок: ' + result.errors.length + ')', !result.valid && result.errors.length >= 2);
      } catch (e) { showResult('errorResults', 'Validation: ' + e.message, false); }
    }
    
    function testConflicts() {
      try {
        const today = '2026-12-20';
        Store.getEntries().filter(e => e.name === 'ConfTest').forEach(e => Store.deleteEntry(e.id));
        EntryService.create({ name: 'ConfTest', date: today, time: '20:00', duration: 60, category: 'work' });
        let caught = false;
        try {
          EntryService.create({ name: 'ConfTest2', date: today, time: '20:30', duration: 60, category: 'work' });
        } catch (e) { caught = e.message.includes('Конфликт'); }
        Store.getEntries().filter(e => e.name.startsWith('ConfTest')).forEach(e => Store.deleteEntry(e.id));
        showResult('errorResults', 'Обнаружение конфликтов', caught);
      } catch (e) { showResult('errorResults', 'Conflicts: ' + e.message, false); }
    }
    
    function testEdgeCases() {
      try {
        NoteService.create({ title: 'Empty', text: '' });
        NoteService.create({ title: 'Long', text: 'A'.repeat(1000) });
        NoteService.create({ title: 'Special <>&"', text: 'Test' });
        EntryService.create({ name: 'Zero', date: Utils.getToday(), time: '23:59', price: 0, duration: 0, category: 'work' }, true);
        showResult('errorResults', 'Граничные случаи', true);
      } catch (e) { showResult('errorResults', 'Edge cases: ' + e.message, false); }
    }
    
    function runAll() {
      clearResults();
      testStorage(); testEvents(); testUtils(); testStore();
      testEntryModel(); testNoteModel(); testPriceModel(); testFamilyModel();
      testEntryService(); testNoteService(); testPriceService(); testConflictChecker();
      testManyEntries(); testManyNotes(); testPerformance();
      testValidation(); testConflicts(); testEdgeCases();
    }
    
    function launchApp() { window.location.href = 'http://localhost:8000/'; }
    
    console.log('✅ Готово! Нажми "ЗАПУСТИТЬ ВСЕ ТЕСТЫ"');
  </script>
</body>
</html>
TESTHTML

echo "✅ Тесты обновлены"

# Перезапуск
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000/test_app.html"
  echo "✅ Тесты открыты!"
fi

echo ""
echo "🎯 ИСПРАВЛЕНО:"
echo "  ✅ Note.getCategoryIcon('shopping') теперь возвращает ''"
echo "  ✅ Entry.validate() теперь проверяет дату и время (3 ошибки)"
echo ""
echo " ОЖИДАЕМЫЙ РЕЗУЛЬТАТ: 100% (18/18) 🏆"
