#!/bin/bash
echo " СОЗДАЮ ОТДЕЛЬНУЮ ВКЛАДКУ 'СОБАКА'..."

# 1. Исправляем видимость кнопки на светлой теме
sed -i 's|background:linear-gradient(135deg,#10b981,#34d399)|background:linear-gradient(135deg,#059669,#10b981);box-shadow:0 4px 12px rgba(5,150,105,0.5);border:2px solid #047857|g' app.js

echo "✅ Кнопка 'Свободные окна' теперь видна на светлой теме"

# 2. Добавляем вкладку "Собака" в навигацию
sed -i 's|<button class="nav-item" data-tab="tasks">|<button class="nav-item" data-tab="dog">\n      <span class="material-icons-round">pets</span>\n      <span class="nav-label">Собака</span>\n    </button>\n    <button class="nav-item" data-tab="tasks">|' index.html

echo "✅ Вкладка 'Собака' добавлена в навигацию"

# 3. Добавляем контент вкладки
sed -i 's|<!-- Tasks Tab -->|<!-- Dog Tab -->\n    <div id="tab-dog" class="tab-content">\n      <div class="tab-header">\n        <h2><span class="material-icons-round">pets</span> Собака</h2>\n        <button class="btn-primary" onclick="openDogForm()">\n          <span class="material-icons-round">add</span> Событие\n        </button>\n      </div>\n      <div id="dogView"></div>\n    </div>\n\n    <!-- Tasks Tab -->|' index.html

echo "✅ Контент вкладки 'Собака' добавлен"

# 4. Создаём сервис для собаки
cat > src/services/DogService.js << 'DOGSERVICE'
/**
 * DOG SERVICE
 * Управление событиями собаки
 */

const DogService = {
  // Типы событий
  eventTypes: {
    groomer: { label: ' Грумер', color: '#f59e0b' },
    vet: { label: '🏥 Ветеринар', color: '#ef4444' },
    walk: { label: ' Прогулка', color: '#10b981' },
    training: { label: '🎓 Дрессировка', color: '#8b5cf6' },
    other: { label: '📌 Другое', color: '#6b7280' }
  },

  // Создать событие
  create: function(data) {
    const entry = {
      ...data,
      category: 'dog',
      id: Utils.generateId(),
      createdAt: new Date().toISOString()
    };
    Store.addEntry(entry);
    Events.emit('entry:created', entry);
    return entry;
  },

  // Получить все события собаки
  getAll: function() {
    return Store.getEntries().filter(e => e.category === 'dog');
  },

  // Получить события по дате
  getByDate: function(date) {
    return this.getAll().filter(e => e.date === date);
  },

  // Обновить событие
  update: function(id, data) {
    Store.updateEntry(id, data);
    Events.emit('entry:updated', id);
  },

  // Удалить событие
  delete: function(id) {
    Store.deleteEntry(id);
    Events.emit('entry:deleted', id);
  }
};

window.DogService = DogService;
console.log('✅ DogService загружен');
DOGSERVICE

echo "✅ DogService.js создан"

# 5. Добавляем сервис в index.html
sed -i '/<script src="src\/services\/Predictor.js"><\/script>/a \  <script src="src/services/DogService.js"></script>' index.html

# 6. Создаём View для собаки
cat > src/views/DogView.js << 'DOGVIEW'
/**
 * DOG VIEW
 * Отображение вкладки собаки
 */

const DogView = {
  container: null,
  filter: 'all',
  
  init(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) return;
    this.render();
    this.setupListeners();
  },
  
  render() {
    if (!this.container) return;
    
    let events = DogService.getAll();
    
    // Фильтрация по типу
    if (this.filter !== 'all') {
      const typeMap = {
        groomer: 'Грумер',
        vet: 'Ветеринар',
        walk: 'Прогулка',
        training: 'Дрессировка'
      };
      const filterType = typeMap[this.filter];
      if (filterType) {
        events = events.filter(e => e.service && e.service.includes(filterType));
      }
    }
    
    // Сортировка по дате и времени
    events.sort((a, b) => (a.date + a.time).localeCompare(b.date + b.time));
    
    let html = `
      <div class="dog-filters">
        <button class="dog-filter ${this.filter === 'all' ? 'active' : ''}" data-filter="all">Все</button>
        <button class="dog-filter ${this.filter === 'groomer' ? 'active' : ''}" data-filter="groomer">💅 Грумер</button>
        <button class="dog-filter ${this.filter === 'vet' ? 'active' : ''}" data-filter="vet">🏥 Ветеринар</button>
        <button class="dog-filter ${this.filter === 'walk' ? 'active' : ''}" data-filter="walk">🌳 Прогулка</button>
        <button class="dog-filter ${this.filter === 'training' ? 'active' : ''}" data-filter="training"> Дрессировка</button>
      </div>
    `;
    
    if (events.length === 0) {
      html += '<div class="empty-state">Нет событий 🐕</div>';
    } else {
      events.forEach(event => {
        const priority = getEventPriority(event);
        html += `
          <div class="entry-card category-dog priority-${priority.key.toLowerCase()}" data-id="${event.id}">
            <div class="entry-compact-info" onclick="toggleDogCard(${event.id})" style="cursor:pointer;">
              <span class="entry-compact-time">${event.time} - ${Entry.getEndTime(event)}</span>
              <span class="entry-compact-name">${event.name || 'Событие'}</span>
              ${event.price > 0 ? `<span class="entry-compact-price">${event.price}₽</span>` : ''}
              <span class="expand-icon">▼</span>
            </div>
            
            <div class="entry-details" id="dog-details-${event.id}" style="display:none;">
              <div><b>${event.name || 'Событие'}</b> <span class="status-badge status-${event.status || 'new'}">${Entry.getStatusLabel(event.status || 'new')}</span></div>
              <div style="margin-top:5px;">
                ${event.service || ''}
                ${event.zone ? ' · 📍 ' + event.zone : ''}
                ${event.notes ? ' · 💬 ' + event.notes : ''}
                · ⏱️ ${event.duration} мин
              </div>
            </div>
            
            <div class="entry-actions" id="dog-actions-${event.id}" style="display:none;">
              <button class="btn-edit" onclick="editDogEvent(${event.id})">✏️ Изменить</button>
              <button class="btn-del" onclick="deleteDogEvent(${event.id})">🗑️ Удалить</button>
            </div>
          </div>
        `;
      });
    }
    
    this.container.innerHTML = html;
    
    // Обработчики фильтров
    this.container.querySelectorAll('.dog-filter').forEach(btn => {
      btn.addEventListener('click', () => {
        this.filter = btn.dataset.filter;
        this.render();
      });
    });
  },
  
  setupListeners() {
    Events.on('entry:created', () => this.render());
    Events.on('entry:updated', () => this.render());
    Events.on('entry:deleted', () => this.render());
  }
};

window.DogView = DogView;
console.log('✅ DogView загружен');
DOGVIEW

echo "✅ DogView.js создан"

# 7. Добавляем View в index.html
sed -i '/<script src="src\/views\/TasksView.js"><\/script>/a \  <script src="src/views/DogView.js"></script>' index.html

# 8. Добавляем функции в app.js
cat >> app.js << 'DOGFUNCS'

// === ФУНКЦИИ ДЛЯ ВКЛАДКИ СОБАКА ===

// Открыть форму собаки
window.openDogForm = function(id = null) {
  const eventTypes = Object.entries(DogService.eventTypes).map(([key, val]) => 
    `<option value="${val.label}">${val.label}</option>`
  ).join('');
  
  const content = `
    <form id="dogForm" onsubmit="return saveDogEvent(event, ${id})">
      <label>Название события</label>
      <input type="text" id="dogName" placeholder="Напр. Стрижка" required 
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;">
      
      <label>Тип события</label>
      <select id="dogType" required 
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;">
        ${eventTypes}
      </select>
      
      <label>Дата</label>
      <input type="date" id="dogDate" required 
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;">
      
      <label>Время</label>
      <input type="time" id="dogTime" required 
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;">
      
      <label>Длительность (минут)</label>
      <input type="number" id="dogDuration" value="60" min="10" max="300" 
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;">
      
      <label>📍 Адрес / Место</label>
      <input type="text" id="dogAddress" placeholder="Напр. Грумерская 'Лапки', ул. Пушкина 10" 
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;">
      
      <label>💬 Примечания</label>
      <textarea id="dogNotes" placeholder="Напр. Боится уколов, взять любимый мячик" rows="3" 
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;"></textarea>
      
      <label> Стоимость (₽)</label>
      <input type="number" id="dogPrice" placeholder="Напр. 2000" min="0" 
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;">
      
      <div style="display:flex;gap:10px;margin-top:20px;">
        <button type="submit" 
          style="flex:1;padding:15px;background:linear-gradient(135deg,#f59e0b,#fbbf24);color:white;border:none;border-radius:12px;font-weight:700;cursor:pointer;">
          💾 Сохранить
        </button>
        <button type="button" onclick="Modal.close()" 
          style="flex:1;padding:15px;background:#e0e0e0;color:#333;border:none;border-radius:12px;font-weight:700;cursor:pointer;">
          Отмена
        </button>
      </div>
    </form>
  `;
  
  Modal.form({ title: id ? '✏️ Редактировать событие' : '🐕 Добавить событие', content });
  
  // Установить сегодняшнюю дату по умолчанию
  setTimeout(() => {
    document.getElementById('dogDate').value = new Date().toISOString().split('T')[0];
    document.getElementById('dogTime').value = '10:00';
  }, 100);
};

// Сохранить событие собаки
window.saveDogEvent = function(e, id) {
  e.preventDefault();
  
  const data = {
    name: document.getElementById('dogName').value,
    service: document.getElementById('dogType').value,
    date: document.getElementById('dogDate').value,
    time: document.getElementById('dogTime').value,
    duration: parseInt(document.getElementById('dogDuration').value),
    zone: document.getElementById('dogAddress').value,
    notes: document.getElementById('dogNotes').value,
    price: parseInt(document.getElementById('dogPrice').value || 0),
    status: 'new'
  };
  
  if (id) {
    DogService.update(id, data);
  } else {
    DogService.create(data);
  }
  
  Modal.close();
  Modal.alert(id ? '✅ Событие обновлено!' : '✅ Событие создано!');
  setTimeout(() => {
    if (typeof DogView !== 'undefined') DogView.render();
    if (typeof CalendarView !== 'undefined') CalendarView.render();
  }, 200);
  
  return false;
};

// Редактировать событие собаки
window.editDogEvent = function(id) {
  const event = Store.getEntries().find(e => e.id === id);
  if (!event) return;
  
  openDogForm(id);
  
  setTimeout(() => {
    document.getElementById('dogName').value = event.name || '';
    document.getElementById('dogType').value = event.service || '';
    document.getElementById('dogDate').value = event.date;
    document.getElementById('dogTime').value = event.time;
    document.getElementById('dogDuration').value = event.duration;
    document.getElementById('dogAddress').value = event.zone || '';
    document.getElementById('dogNotes').value = event.notes || '';
    document.getElementById('dogPrice').value = event.price || 0;
  }, 100);
};

// Удалить событие собаки
window.deleteDogEvent = function(id) {
  Modal.confirm('Удалить это событие?', () => {
    DogService.delete(id);
    Modal.close();
    Modal.alert('✅ Событие удалено!');
    setTimeout(() => {
      if (typeof DogView !== 'undefined') DogView.render();
      if (typeof CalendarView !== 'undefined') CalendarView.render();
    }, 200);
  });
};

// Переключение карточки собаки
window.toggleDogCard = function(id) {
  const details = document.getElementById(`dog-details-${id}`);
  const actions = document.getElementById(`dog-actions-${id}`);
  
  if (details && actions) {
    const isHidden = details.style.display === 'none';
    details.style.display = isHidden ? 'block' : 'none';
    actions.style.display = isHidden ? 'block' : 'none';
  }
};

// Инициализация вкладки собаки при переключении
const _origSwitchTab = window.switchTab;
window.switchTab = function(tabName) {
  if (_origSwitchTab) _origSwitchTab(tabName);
  
  if (tabName === 'dog') {
    setTimeout(() => {
      if (typeof DogView !== 'undefined') {
        DogView.init('dogView');
      }
    }, 100);
  }
};

console.log('✅ Функции вкладки "Собака" загружены');
DOGFUNCS

echo "✅ Функции вкладки 'Собака' добавлены"

# 9. Добавляем стили для собаки
cat >> styles/main.css << 'DOGSTYLES'

/* Вкладка собаки */
.dog-filters {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 15px;
}

.dog-filter {
  padding: 8px 16px;
  border: 2px solid var(--border, #e0e0e0);
  background: var(--bg-secondary, #f5f5f5);
  color: var(--text-secondary, #666);
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 14px;
  font-weight: 600;
}

.dog-filter:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}

.dog-filter.active {
  background: linear-gradient(135deg, #f59e0b, #fbbf24);
  color: white;
  border-color: #f59e0b;
}

/* Карточки собаки */
.category-dog {
  border-left: 4px solid #f59e0b;
}

/* Иконка собаки в навигации */
.nav-item[data-tab="dog"] .material-icons-round {
  color: #f59e0b;
}

.nav-item[data-tab="dog"].active .material-icons-round {
  color: white;
}
DOGSTYLES

echo "✅ Стили для собаки добавлены"

# Git + сборка
echo ""
echo " Отправка на GitHub и сборка..."

git add .
git commit -m "feat: Добавлена отдельная вкладка 'Собака' с фильтрами и формами"
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
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_DogTab.apk
  cd ..
  cp GdeSveta_DogTab.apk ~/storage/downloads/GdeSveta_DogTab.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo " ОТДЕЛЬНАЯ ВКЛАДКА 'СОБАКА' ГОТОВА!"
  echo "═══════════════════════════════════════════════"
  echo "📁 APK: ~/storage/downloads/GdeSveta_DogTab.apk"
  echo ""
  echo "✅ ЧТО ДОБАВЛЕНО:"
  echo "• Новая вкладка 'Собака' в навигации (иконка 🐾)"
  echo "• Фильтры: Все, Грумер, Ветеринар, Прогулка, Дрессировка"
  echo "• Специальная форма с полями:"
  echo "  - Тип события (выпадающий список)"
  echo "  - Адрес/место (где грумерская или клиника)"
  echo "  - Примечания (боится уколов, взять мячик)"
  echo "  - Стоимость"
  echo "• Кнопка 'Свободные окна' теперь видна на светлой теме!"
  echo ""
  echo "📱 ТЕСТИРОВАНИЕ:"
  echo "1. Установи GdeSveta_DogTab.apk"
  echo "2. Нажми на вкладку 'Собака' (иконка с собакой)"
  echo "3. Нажми '+ Событие'"
  echo "4. Заполни: 'Стрижка', тип 'Грумер', адрес, примечания"
  echo "5. Сохрани — увидишь карточку с оранжевой полоской"
  echo "═══════════════════════════════════════════════"
else
  echo "❌ Ошибка сборки"
  cd ..
fi
