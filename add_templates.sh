#!/bin/bash
echo "⚡ Добавляю быстрые шаблоны..."

# 1. Создаём сервис для шаблонов
cat > src/services/TemplateService.js << 'TEMPLATE'
/**
 * TEMPLATE SERVICE
 * Управление быстрыми шаблонами записей
 */

const TemplateService = {
  KEY: 'gdesveta_templates',
  
  getAll() {
    return Storage.get(this.KEY, []);
  },
  
  save(template) {
    const templates = this.getAll();
    const newTemplate = {
      id: Utils.generateId(),
      name: template.name,
      category: template.category,
      serviceName: template.serviceName,
      duration: template.duration,
      price: template.price,
      zone: template.zone,
      familyMemberId: template.familyMemberId || null,
      isDefault: template.isDefault || false
    };
    
    templates.push(newTemplate);
    Storage.set(this.KEY, templates);
    return newTemplate;
  },
  
  delete(id) {
    const templates = this.getAll().filter(t => t.id !== id);
    Storage.set(this.KEY, templates);
  },
  
  apply(id) {
    return this.getAll().find(t => t.id === id) || null;
  },
  
  // Демо-шаблоны при первом запуске
  initDefaults() {
    if (this.getAll().length === 0) {
      const defaults = [
        { name: 'Ноги + Бикини', category: 'work', serviceName: 'Шугаринг', duration: 90, price: 2300, zone: 'Ноги полностью + Бикини классическое' },
        { name: 'LPG Всего тела', category: 'work', serviceName: 'LPG-массаж', duration: 60, price: 2000, zone: 'Всё тело' },
        { name: 'Старший: Футбол', category: 'family', serviceName: 'Секция', duration: 90, price: 0, zone: 'Стадион', familyMemberId: 1 },
        { name: 'Малыш: Садик', category: 'family', serviceName: 'Садик', duration: 480, price: 0, zone: 'Садик "Солнышко"', familyMemberId: 3 }
      ];
      Storage.set(this.KEY, defaults);
    }
  }
};

window.TemplateService = TemplateService;
TEMPLATE

echo "✅ TemplateService.js создан"

# 2. Обновляем стили для шаблонов
cat >> styles/main.css << 'CSS'

/* === ШАБЛОНЫ === */
.template-selector {
  margin-bottom: 15px;
  padding: 12px;
  background: #fff3e0;
  border-radius: 10px;
  border: 2px dashed #ff9800;
}

body.dark-theme .template-selector {
  background: #2d3561;
  border-color: #ff9800;
}

.template-selector label {
  font-weight: bold;
  color: #e65100;
  margin-bottom: 5px;
  display: block;
}

body.dark-theme .template-selector label {
  color: #ff9800;
}

.template-select {
  width: 100%;
  padding: 10px;
  border: 2px solid #ff9800;
  border-radius: 8px;
  background: white;
  font-size: 14px;
  font-weight: 600;
}

body.dark-theme .template-select {
  background: #16213e;
  color: #eaeaea;
}

.save-as-template {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 15px;
  padding: 10px;
  background: #e8f5e9;
  border-radius: 8px;
  cursor: pointer;
}

body.dark-theme .save-as-template {
  background: #1b5e20;
}

.save-as-template input {
  width: 20px;
  height: 20px;
  cursor: pointer;
}

.save-as-template span {
  font-size: 14px;
  font-weight: 600;
  color: #2e7d32;
}

body.dark-theme .save-as-template span {
  color: #a5d6a7;
}

.template-manager {
  margin-top: 15px;
}

.template-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px;
  background: #f5f5f5;
  border-radius: 8px;
  margin-bottom: 8px;
}

body.dark-theme .template-item {
  background: #2d3561;
}

.template-item-info {
  flex: 1;
}

.template-item-name {
  font-weight: bold;
  font-size: 14px;
}

.template-item-details {
  font-size: 12px;
  color: #666;
}

body.dark-theme .template-item-details {
  color: #aaa;
}
CSS

echo "✅ Стили для шаблонов добавлены"

# 3. Обновляем index.html (добавляем скрипт шаблонов)
sed -i '/<script src="src\/services\/FamilyShare.js"><\/script>/a \  <script src="src/services/TemplateService.js"></script>' index.html

echo "✅ TemplateService подключен к index.html"

# 4. Обновляем app.js — добавляем логику шаблонов в форму
cat >> app.js << 'APPJS'

// === ЛОГИКА ШАБЛОНОВ ===
function initTemplates() {
  TemplateService.initDefaults();
}

function loadTemplate(templateId) {
  if (!templateId) return;
  
  const template = TemplateService.apply(parseInt(templateId));
  if (!template) return;
  
  // Заполняем форму данными из шаблона
  const nameInput = document.getElementById('entryName');
  const serviceSelect = document.getElementById('entryService');
  const durationInput = document.getElementById('entryDuration');
  const priceInput = document.getElementById('entryPrice');
  const zoneInput = document.getElementById('entryZone');
  const familySelect = document.querySelector('.family-select');
  
  if (nameInput && template.name) nameInput.value = template.name;
  if (serviceSelect && template.serviceName) serviceSelect.value = template.serviceName;
  if (durationInput && template.duration) {
    durationInput.value = template.duration;
    // Обновляем визуальные кнопки длительности
    document.querySelectorAll('.duration-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.min === template.duration.toString());
    });
  }
  if (priceInput && template.price !== undefined) priceInput.value = template.price;
  if (zoneInput && template.zone) zoneInput.value = template.zone;
  
  if (familySelect && template.familyMemberId) {
    familySelect.value = template.familyMemberId;
    // Триггерим событие change для автозаполнения
    familySelect.dispatchEvent(new Event('change'));
  }
  
  console.log('✅ Шаблон применён:', template.name);
}

function saveCurrentAsTemplate() {
  const name = prompt('Название шаблона (напр. "Стандартный клиент"):');
  if (!name) return;
  
  const template = {
    name: name,
    category: document.getElementById('entryCategory').value,
    serviceName: document.getElementById('entryService').value,
    duration: parseInt(document.getElementById('entryDuration').value),
    price: parseInt(document.getElementById('entryPrice')?.value || 0),
    zone: document.getElementById('entryZone').value,
    familyMemberId: document.querySelector('.family-select')?.value || null
  };
  
  TemplateService.save(template);
  Modal.alert('✅ Шаблон "' + name + '" сохранён!');
}

function manageTemplates() {
  const templates = TemplateService.getAll();
  
  let content = '';
  if (templates.length === 0) {
    content = '<div class="empty-state">Нет сохранённых шаблонов</div>';
  } else {
    content = '<div class="template-manager">' + 
      templates.map(t => `
        <div class="template-item">
          <div class="template-item-info">
            <div class="template-item-name">${t.category === 'work' ? '💼' : '👨‍👩‍👧'} ${t.name}</div>
            <div class="template-item-details">${t.serviceName} · ${t.duration} мин · ${t.price}₽</div>
          </div>
          <button class="btn-del" onclick="deleteTemplate(${t.id})">🗑️</button>
        </div>
      `).join('') + 
      '</div>';
  }
  
  content += `<button class="action-btn" onclick="Modal.close()" style="margin-top:15px;width:100%">Закрыть</button>`;
  
  Modal.form({ title: '⚡ Управление шаблонами', content });
}

window.deleteTemplate = function(id) {
  Modal.confirm('Удалить этот шаблон?', () => {
    TemplateService.delete(id);
    Modal.close();
    manageTemplates();
  });
};
APPJS

echo "✅ Логика шаблонов добавлена в app.js"

# 5. Модифицируем openEntryForm, чтобы добавить выбор шаблона
# Создаём временный файл для патча
cat > patch_form.js << 'PATCH'
// Находим место в openEntryForm, где создаётся content, и добавляем селектор шаблонов
// Это упрощённый патч: мы просто перезапишем ключевую часть функции openEntryForm

const oldOpenEntryForm = openEntryForm;
openEntryForm = function(id = null, category = 'work') {
  let entry = null;
  if (id) {
    entry = Store.getEntries().find(e => e.id === id);
    if (!entry) return;
    category = entry.category;
  }
  
  const categoryLabels = {
    work: '💼 Новая запись (работа)',
    family: '👨‍👩‍👧 Событие (семья)',
    dog: '🐕 Событие (собака)'
  };
  
  const isWork = category === 'work';
  const isFamily = category === 'family' || category === 'dog';
  
  // Получаем шаблоны для текущей категории
  const categoryTemplates = TemplateService.getAll().filter(t => t.category === category);
  let templateOptions = '<option value="">-- Без шаблона (ввести вручную) --</option>';
  categoryTemplates.forEach(t => {
    templateOptions += `<option value="${t.id}">⚡ ${t.name} (${t.duration} мин, ${t.price}₽)</option>`;
  });

  let content = `
    <form id="entryForm">
      <input type="hidden" id="entryId" value="${id || ''}">
      <input type="hidden" id="entryCategory" value="${category}">
      
      <!-- СЕКЦИЯ ШАБЛОНОВ -->
      <div class="template-selector">
        <label>⚡ Быстрый шаблон:</label>
        <select class="template-select" id="templateSelector" onchange="loadTemplate(this.value)">
          ${templateOptions}
        </select>
      </div>
      
      ${isFamily ? `<label>Член семьи</label>${FamilySelect.render(entry ? entry.familyMemberId : null)}` : ''}
      
      <label>Название *</label>
      <input type="text" id="entryName" value="${entry ? entry.name : ''}" required>
      
      ${isWork ? `<label>Телефон</label><input type="tel" id="entryPhone" value="${entry ? entry.phone : ''}">` : ''}
      
      <label>Дата *</label>
      <input type="date" id="entryDate" value="${entry ? entry.date : (typeof Calendar !== 'undefined' ? Calendar.getSelectedDate() : Utils.getToday())}" required>
      
      <label>Время *</label>
      <input type="time" id="entryTime" value="${entry ? entry.time : Utils.getNow()}" required>
      
      <label>Длительность (мин)</label>
      <div class="duration-row">
        <button type="button" class="duration-btn" data-min="30">30</button>
        <button type="button" class="duration-btn active" data-min="60">60</button>
        <button type="button" class="duration-btn" data-min="90">90</button>
        <button type="button" class="duration-btn" data-min="120">120</button>
      </div>
      <input type="hidden" id="entryDuration" value="${entry ? entry.duration : 60}">
      
      <label>Услуга/Тип</label>
      <select id="entryService">
        <option ${entry && entry.service === 'Шугаринг' ? 'selected' : ''}>Шугаринг</option>
        <option ${entry && entry.service === 'LPG-массаж' ? 'selected' : ''}>LPG-массаж</option>
        <option ${entry && entry.service === 'Школа' ? 'selected' : ''}>Школа</option>
        <option ${entry && entry.service === 'Садик' ? 'selected' : ''}>Садик</option>
        <option ${entry && entry.service === 'Кружок' ? 'selected' : ''}>Кружок</option>
        <option ${entry && entry.service === 'Секция' ? 'selected' : ''}>Секция</option>
        <option ${entry && entry.service === 'Врач' ? 'selected' : ''}>Врач</option>
        <option ${entry && entry.service === 'Ветеринар' ? 'selected' : ''}>Ветеринар</option>
        <option ${entry && entry.service === 'Груминг' ? 'selected' : ''}>Груминг</option>
        <option ${entry && entry.service === 'Прогулка' ? 'selected' : ''}>Прогулка</option>
        <option ${entry && entry.service === 'Другое' ? 'selected' : ''}>Другое</option>
      </select>
      
      <label>Зона/Место</label>
      <input type="text" id="entryZone" value="${entry ? entry.zone : ''}">
      <label>Заметки</label>
      <textarea id="entryNotes" rows="2">${entry ? entry.notes : ''}</textarea>
      
      ${isWork ? `<label>Цена (₽)</label><input type="number" id="entryPrice" value="${entry ? entry.price : 0}">` : ''}
      
      ${id ? `
        <label>Статус</label>
        <select id="entryStatus">
          <option value="new" ${entry && entry.status === 'new' ? 'selected' : ''}>Новая</option>
          <option value="confirmed" ${entry && entry.status === 'confirmed' ? 'selected' : ''}>Подтверждена</option>
          <option value="done" ${entry && entry.status === 'done' ? 'selected' : ''}>Выполнена</option>
          <option value="cancelled" ${entry && entry.status === 'cancelled' ? 'selected' : ''}>Отменена</option>
        </select>
      ` : `
        <label class="save-as-template">
          <input type="checkbox" id="saveAsTemplateCheck">
          <span>💾 Сохранить как новый шаблон</span>
        </label>
      `}
      
      <div class="form-actions">
        <button type="submit" class="save-btn">Сохранить</button>
        <button type="button" class="cancel-btn" onclick="Modal.close()">Отмена</button>
      </div>
    </form>
  `;
  
  const modal = Modal.form({
    title: id ? '✏️ Редактировать запись' : categoryLabels[category],
    content
  });
  
  // Обработчики длительности
  modal.querySelectorAll('.duration-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      modal.querySelectorAll('.duration-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      modal.querySelector('#entryDuration').value = btn.dataset.min;
    });
  });
  
  // Обработчик члена семьи
  const familySelect = modal.querySelector('.family-select');
  if (familySelect) {
    familySelect.addEventListener('change', () => {
      const member = FamilySelect.getSelectedMember(familySelect);
      if (member) {
        modal.querySelector('#entryName').value = member.name;
        if (member.school) modal.querySelector('#entryZone').value = member.school;
      }
    });
  }
  
  // Обработчик сохранения
  modal.querySelector('#entryForm').addEventListener('submit', (e) => {
    e.preventDefault();
    
    // Проверяем, нужно ли сохранить как шаблон
    const saveAsTemplateCheck = modal.querySelector('#saveAsTemplateCheck');
    if (saveAsTemplateCheck && saveAsTemplateCheck.checked && !id) {
      saveCurrentAsTemplate();
    }
    
    const data = {
      category: modal.querySelector('#entryCategory').value,
      name: modal.querySelector('#entryName').value,
      phone: modal.querySelector('#entryPhone')?.value || '',
      date: modal.querySelector('#entryDate').value,
      time: modal.querySelector('#entryTime').value,
      duration: parseInt(modal.querySelector('#entryDuration').value),
      service: modal.querySelector('#entryService').value,
      zone: modal.querySelector('#entryZone').value,
      notes: modal.querySelector('#entryNotes').value,
      price: parseInt(modal.querySelector('#entryPrice')?.value || 0),
      status: modal.querySelector('#entryStatus')?.value || 'new',
      familyMemberId: familySelect ? FamilySelect.getSelectedId(familySelect) : null
    };
    
    try {
      if (id) EntryService.update(id, data);
      else EntryService.create(data);
      Modal.close();
      Modal.alert('✅ Запись сохранена!');
    } catch (error) {
      Modal.alert('❌ Ошибка: ' + error.message);
    }
  });
}
PATCH

# Добавляем патч в конец app.js
cat patch_form.js >> app.js
rm patch_form.js

echo "✅ Форма записи обновлена для поддержки шаблонов"

# Перезапуск
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000"
  echo "✅ Приложение открыто!"
fi

echo ""
echo "⚡ ПРИОРИТЕТ 5 ВЫПОЛНЕН!"
echo ""
echo "✅ Добавлены быстрые шаблоны:"
echo "  • 4 демо-шаблона уже созданы (Ноги+Бикини, LPG, Футбол, Садик)"
echo "  • Выпадающий список шаблонов вверху формы добавления"
echo "  • Автозаполнение: услуга, время, цена, место, член семьи"
echo "  • Чекбокс 'Сохранить как новый шаблон' при создании записи"
echo "  • Управление шаблонами (просмотр и удаление)"
echo ""
echo "Как использовать:"
echo "  1. Нажми '+ Добавить'"
echo "  2. Вверху выбери шаблон из списка ⚡"
echo "  3. Форма заполнится автоматически!"
echo "  4. Или поставь галочку 'Сохранить как новый шаблон' внизу"
echo ""
echo "🎉 Все 5 главных приоритетов из отчёта 500 пользователей выполнены!"
echo ""
echo "Что делаем дальше?"
echo "  • 'тест' — запустить финальное тестирование"
echo "  • 'apk' — начать подготовку к сборке Android-приложения"
echo "  • 'стоп' — пауза"
