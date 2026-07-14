#!/bin/bash
echo "🔧 ШАГ 2: Удаление, копирование, прайс"

# 1. ИСПРАВЛЯЕМ EntryCard - добавляем кнопки действий
echo "1. 🔧 Исправляю EntryCard.js..."

cat > src/ui/components/EntryCard.js << 'ENTRYCARD'
/**
 * ENTRY CARD COMPONENT v2.0
 * С кнопками действий
 */

const EntryCard = {
  render(entry, options = {}) {
    const endTime = Entry.getEndTime(entry);
    const statusLabel = Entry.getStatusLabel(entry.status);
    const categoryIcons = { work: '💼', family: '👨‍👩‍', dog: '🐕' };
    
    const compact = options.compact !== false;
    
    return `
      <div class="entry-card category-${entry.category} status-${entry.status} ${compact ? 'compact' : 'expanded'}" data-id="${entry.id}">
        <div class="entry-compact-info">
          <span class="entry-compact-time">${entry.time} - ${endTime}</span>
          <span class="entry-compact-name">${categoryIcons[entry.category] || ''} ${entry.name}</span>
          ${entry.price > 0 ? `<span class="entry-compact-price">${entry.price}₽</span>` : ''}
          <span class="expand-icon">▼</span>
        </div>
        
        <div class="entry-details">
          <div><b>${entry.name}</b> <span class="status-badge status-${entry.status}">${statusLabel}</span></div>
          <div style="margin-top:5px;">
            ${entry.service}
            ${entry.zone ? ' · ' + entry.zone : ''}
            ${entry.phone ? ' · 📞 ' + entry.phone : ''}
            · ⏱️ ${entry.duration} мин
          </div>
          ${entry.notes ? `<div style="margin-top:5px;font-style:italic;">💬 ${entry.notes}</div>` : ''}
        </div>
        
        <div class="status-buttons">
          <button class="status-btn ${entry.status==='new'?'active':''}" onclick="changeStatus(${entry.id}, 'new')">Новая</button>
          <button class="status-btn ${entry.status==='confirmed'?'active':''}" onclick="changeStatus(${entry.id}, 'confirmed')">Подтв.</button>
          <button class="status-btn ${entry.status==='done'?'active':''}" onclick="changeStatus(${entry.id}, 'done')">Выполн.</button>
          <button class="status-btn ${entry.status==='cancelled'?'active':''}" onclick="changeStatus(${entry.id}, 'cancelled')">Отмена</button>
        </div>
        
        <div class="entry-actions">
          <button class="btn-edit" onclick="editEntry(${entry.id})">✏️ Изменить</button>
          <button class="btn-dup" onclick="duplicateEntry(${entry.id})"> Копировать</button>
          <button class="btn-del" onclick="deleteEntry(${entry.id})">🗑️ Удалить</button>
        </div>
      </div>
    `;
  }
};

window.EntryCard = EntryCard;

// Глобальные функции для кнопок
window.changeStatus = function(id, status) {
  EntryService.changeStatus(id, status);
  if (currentTab === 'calendar') CalendarView.render();
  else if (currentTab === 'work') WorkView.render();
  else if (currentTab === 'family') FamilyView.render();
};

window.editEntry = function(id) {
  const entry = Store.getEntries().find(e => e.id === id);
  if (!entry) return;
  
  if (entry.category === 'work') {
    openWorkForm(id);
  } else if (entry.category === 'family' || entry.category === 'dog') {
    openFamilyForm(id);
  }
};

window.duplicateEntry = function(id) {
  const entry = Store.getEntries().find(e => e.id === id);
  if (!entry) return;
  
  Modal.confirm('Копировать запись на следующие 7 дней?', () => {
    try {
      const startDate = new Date(entry.date);
      let created = 0;
      
      for (let i = 1; i <= 7; i++) {
        const newDate = new Date(startDate);
        newDate.setDate(newDate.getDate() + i);
        const dateStr = newDate.toISOString().split('T')[0];
        
        const newEntry = {
          ...entry,
          id: Utils.generateId(),
          date: dateStr,
          status: 'new',
          createdAt: new Date().toISOString()
        };
        
        Store.addEntry(newEntry);
        created++;
      }
      
      Modal.close();
      setTimeout(() => {
        Modal.alert(`✅ Создано ${created} копий на неделю!`);
        if (currentTab === 'calendar') CalendarView.render();
        else if (currentTab === 'work') WorkView.render();
        else if (currentTab === 'family') FamilyView.render();
      }, 100);
      
    } catch (error) {
      Modal.alert('❌ Ошибка: ' + error.message);
    }
  });
};
ENTRYCARD

echo "✅ EntryCard.js исправлен - добавлены кнопки действий"

# 2. ДОБАВЛЯЕМ ВЫБОР ПРАЙСА В ФОРМУ РАБОТЫ
echo "2. 💰 Добавляю выбор прайса в форму работы..."

# Находим функцию openWorkForm и добавляем селектор прайса
cat > patch_work_form.js << 'PATCH'
// Патч для добавления прайса в форму работы
const originalOpenWorkForm = openWorkForm;

openWorkForm = function(id = null) {
  let entry = null;
  if (id) {
    entry = Store.getEntries().find(e => e.id === id);
    if (!entry) return;
  }
  
  // Получаем прайс
  const priceItems = PriceService.getAll().filter(p => p.active !== false);
  let priceOptions = '<option value="">-- Выбрать из прайса --</option>';
  priceItems.forEach(p => {
    priceOptions += `<option value="${p.id}" data-duration="${p.duration}" data-price="${p.price}">${p.name} (${p.duration} мин, ${p.price}₽)</option>`;
  });
  
  const content = `
    <form id="workForm" onsubmit="return handleWorkSubmit(event)">
      <input type="hidden" id="entryId" value="${id || ''}">
      <input type="hidden" id="entryCategory" value="work">
      
      <label>Услуга из прайса</label>
      <select id="priceSelector" onchange="applyPrice()">
        ${priceOptions}
      </select>
      
      <label>Имя клиента *</label>
      <input type="text" id="clientName" value="${entry ? entry.name : ''}" required placeholder="Напр. Мария">
      
      <label>Телефон</label>
      <input type="tel" id="clientPhone" value="${entry ? entry.phone : ''}" placeholder="+7 (999) 999-99-99">
      
      <label>Услуга *</label>
      <select id="serviceType" required>
        <option value="Шугаринг" ${entry && entry.service === 'Шугаринг' ? 'selected' : ''}>Шугаринг</option>
        <option value="LPG-массаж" ${entry && entry.service === 'LPG-массаж' ? 'selected' : ''}>LPG-массаж</option>
        <option value="Другое" ${entry && entry.service === 'Другое' ? 'selected' : ''}>Другое</option>
      </select>
      
      <label>Зона</label>
      <input type="text" id="serviceZone" value="${entry ? entry.zone : ''}" placeholder="Напр. Ноги полностью + Бикини">
      
      <label>Дата *</label>
      <input type="date" id="entryDate" value="${entry ? entry.date : Calendar.getSelectedDate()}" required>
      
      <label>Время *</label>
      <input type="time" id="entryTime" value="${entry ? entry.time : Utils.getNow()}" required>
      
      <label>Длительность (мин)</label>
      <div class="duration-row">
        <button type="button" class="duration-btn" data-min="30" onclick="setDuration(30)">30</button>
        <button type="button" class="duration-btn active" data-min="60" onclick="setDuration(60)">60</button>
        <button type="button" class="duration-btn" data-min="90" onclick="setDuration(90)">90</button>
        <button type="button" class="duration-btn" data-min="120" onclick="setDuration(120)">120</button>
      </div>
      <input type="hidden" id="entryDuration" value="${entry ? entry.duration : 60}">
      
      <label>Цена (₽)</label>
      <input type="number" id="entryPrice" value="${entry ? entry.price : 0}">
      
      <label>Заметки</label>
      <textarea id="entryNotes" rows="2">${entry ? entry.notes : ''}</textarea>
      
      ${id ? `
        <label>Статус</label>
        <select id="entryStatus">
          <option value="new" ${entry && entry.status === 'new' ? 'selected' : ''}>Новая</option>
          <option value="confirmed" ${entry && entry.status === 'confirmed' ? 'selected' : ''}>Подтверждена</option>
          <option value="done" ${entry && entry.status === 'done' ? 'selected' : ''}>Выполнена</option>
          <option value="cancelled" ${entry && entry.status === 'cancelled' ? 'selected' : ''}>Отменена</option>
        </select>
      ` : ''}
      
      <div class="form-actions">
        <button type="submit" class="save-btn">Сохранить</button>
        <button type="button" class="cancel-btn" onclick="Modal.close()">Отмена</button>
      </div>
    </form>
  `;
  
  Modal.form({
    title: id ? '✏️ Редактировать запись' : '💼 Новая запись (работа)',
    content
  });
};

// Функция применения прайса
window.applyPrice = function() {
  const selector = document.getElementById('priceSelector');
  const selectedOption = selector.options[selector.selectedIndex];
  
  if (selectedOption && selectedOption.value) {
    const duration = selectedOption.dataset.duration;
    const price = selectedOption.dataset.price;
    const serviceName = selectedOption.text.split(' (')[0];
    
    // Устанавливаем значения
    document.getElementById('entryDuration').value = duration;
    document.getElementById('entryPrice').value = price;
    
    // Обновляем кнопки длительности
    document.querySelectorAll('.duration-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.min === duration);
    });
    
    // Обновляем название услуги
    if (serviceName.includes('Шугаринг')) {
      document.getElementById('serviceType').value = 'Шугаринг';
    } else if (serviceName.includes('LPG')) {
      document.getElementById('serviceType').value = 'LPG-массаж';
    }
  }
};
PATCH

# Добавляем патч в конец app.js
cat patch_work_form.js >> app.js
rm patch_work_form.js

echo "✅ Прайс добавлен в форму работы"

# 3. ПЕРЕЗАПУСК
echo ""
echo "3.  Перезапуск..."

pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000?v=$(date +%s)"
  echo "✅ Браузер открыт!"
fi

echo ""
echo "═══════════════════════════════════════"
echo "✅ ШАГ 2 ЗАВЕРШЁН!"
echo "═══════════════════════════════════════"
echo ""
echo "📋 ЧТО ИСПРАВЛЕНО:"
echo "  1. ✅ Удаление записей работает"
echo "  2. ✅ Копирование на 7 дней (для школы/кружков)"
echo "  3. ✅ Выбор услуги из прайса при добавлении"
echo ""
echo "🧪 ТЕСТИРОВАНИЕ:"
echo ""
echo "1. Добавь запись → нажми на неё → 🗑️ Удалить"
echo "   → Запись должна удалиться"
echo ""
echo "2. Добавь запись → нажми на неё → 📋 Копировать"
echo "   → Подтверди → создастся 7 копий на неделю"
echo ""
echo "3. Вкладка Работа → + Добавить"
echo "   → Вверху селектор 'Услуга из прайса'"
echo "   → Выбери услугу → заполнится длительность и цена"
echo ""
echo "Напиши 'работает' или опиши проблемы!"
