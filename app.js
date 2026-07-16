/**
 * ГдеСвета v11.0 - Полная пересборка
 * Архитектура: Модульная, без конфликтов
 */

console.log('🚀 ГдеСвета загружается...');

// ============================================
// ГЛОБАЛЬНОЕ СОСТОЯНИЕ
// ============================================
window.AppState = {
  currentTab: 'calendar',
  isInitialized: false
};

// ============================================
// ИНИЦИАЛИЗАЦИЯ ПРИЛОЖЕНИЯ
// ============================================
function initApp() {
  if (AppState.isInitialized) {
    console.log('⚠️ Приложение уже инициализировано');
    return;
  }

  console.log('✅ Инициализация...');
  
  // Проверяем наличие необходимых модулей
  if (typeof Storage === 'undefined') {
    console.error('❌ Storage не найден!');
    return;
  }
  
  if (typeof Store === 'undefined') {
    console.error('❌ Store не найден!');
    return;
  }

  // Инициализация завершена
  AppState.isInitialized = true;
  console.log('✅ Приложение готово!');
  
  // Открываем первую вкладку
  setTimeout(() => {
    switchTab('calendar');
  }, 300);
}

// ============================================
// ПЕРЕКЛЮЧЕНИЕ ВКЛАДОК
// ============================================
window.switchTab = function(tabName) {
  console.log('🔄 Вкладка:', tabName);
  
  AppState.currentTab = tabName;
  
  // 1. Убираем active со всех кнопок
  document.querySelectorAll('.nav-item').forEach(btn => {
    btn.classList.remove('active');
  });
  
  // 2. Активируем нужную кнопку
  const activeBtn = document.querySelector(`.nav-item[data-tab="${tabName}"]`);
  if (activeBtn) {
    activeBtn.classList.add('active');
  }
  
  // 3. Скрываем все вкладки
  document.querySelectorAll('.tab-content').forEach(tab => {
    tab.style.display = 'none';
    tab.classList.remove('active');
  });
  
  // 4. Показываем нужную вкладку
  const targetTab = document.getElementById(`tab-${tabName}`);
  if (targetTab) {
    targetTab.style.display = 'block';
    targetTab.classList.add('active');
    
    // 5. Инициализируем контент вкладки
    setTimeout(() => {
      renderTabContent(tabName);
    }, 100);
  } else {
    console.error(' Вкладка не найдена:', tabName);
  }
};

// ============================================
// ОТРИСОВКА КОНТЕНТА ВКЛАДОК
// ============================================
function renderTabContent(tabName) {
  console.log('📄 Рендеринг вкладки:', tabName);
  
  switch(tabName) {
    case 'calendar':
      if (typeof CalendarView !== 'undefined' && CalendarView.render) {
        CalendarView.render();
      } else {
        console.warn('⚠️ CalendarView не загружен, показываем заглушку');
        renderCalendarFallback();
      }
      break;
      
    case 'work':
      if (typeof WorkView !== 'undefined' && WorkView.render) {
        WorkView.render();
      } else {
        console.warn('️ WorkView не загружен');
        renderWorkFallback();
      }
      break;
      
    case 'family':
      if (typeof FamilyView !== 'undefined' && FamilyView.render) {
        FamilyView.render();
      } else {
        renderFamilyFallback();
      }
      break;
      
    case 'notes':
      if (typeof NotesView !== 'undefined' && NotesView.render) {
        NotesView.render();
      } else {
        renderNotesFallback();
      }
      break;
      
    case 'tasks':
      renderTasksFallback();
      break;
      
    case 'stats':
      if (typeof StatsView !== 'undefined' && StatsView.render) {
        StatsView.render();
      } else {
        renderStatsFallback();
      }
      break;
      
    default:
      console.warn('⚠️ Неизвестная вкладка:', tabName);
  }
}

// ============================================
// ЗАГЛУШКИ ДЛЯ ВКЛАДОК (если View не загружены)
// ============================================
function renderCalendarFallback() {
  const container = document.getElementById('calendarView');
  if (!container) return;
  
  const today = new Date();
  const monthNames = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
  
  container.innerHTML = `
    <div style="padding:20px;">
      <h3 style="text-align:center;margin-bottom:20px;color:#1e293b;">
        ${monthNames[today.getMonth()]} ${today.getFullYear()}
      </h3>
      <div style="background:white;padding:30px;border-radius:16px;box-shadow:0 2px 12px rgba(0,0,0,0.08);">
        <p style="text-align:center;font-size:18px;color:#64748b;">
          📅 ${today.getDate()} ${monthNames[today.getMonth()]}
        </p>
        <p style="text-align:center;margin-top:20px;color:#94a3b8;font-size:14px;">
          Календарь загружен
        </p>
      </div>
    </div>
  `;
}

function renderWorkFallback() {
  const container = document.getElementById('workView');
  if (!container) return;
  
  const entries = Store.getEntries().filter(e => e.category === 'work');
  
  let html = `
    <div style="padding:20px;">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px;">
        <h3 style="margin:0;color:#1e293b;">💼 Работа</h3>
        <button onclick="openWorkForm()" style="padding:10px 20px;background:linear-gradient(135deg,#ff6b9d,#ff8e53);color:white;border:none;border-radius:12px;font-weight:600;cursor:pointer;">
          + Добавить
        </button>
      </div>
  `;
  
  if (entries.length === 0) {
    html += `
      <div style="background:#f8fafc;padding:40px;border-radius:16px;text-align:center;">
        <p style="color:#94a3b8;margin:0;">Нет записей</p>
        <button onclick="openWorkForm()" style="margin-top:15px;padding:12px 30px;background:linear-gradient(135deg,#ff6b9d,#ff8e53);color:white;border:none;border-radius:12px;font-weight:600;cursor:pointer;">
          + Добавить первую запись
        </button>
      </div>
    `;
  } else {
    html += `<div style="display:flex;flex-direction:column;gap:12px;">`;
    entries.forEach(entry => {
      html += `
        <div style="background:white;padding:16px;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);border-left:4px solid #ff6b9d;">
          <div style="display:flex;justify-content:space-between;align-items:center;">
            <div>
              <div style="font-weight:600;color:#1e293b;margin-bottom:5px;">${entry.name || 'Клиент'}</div>
              <div style="font-size:13px;color:#64748b;">
                 ${entry.time} • ${entry.duration} мин
                ${entry.service ? ' • ' + entry.service : ''}
              </div>
            </div>
            ${entry.price ? `<div style="font-weight:700;color:#ff6b9d;">${entry.price}₽</div>` : ''}
          </div>
        </div>
      `;
    });
    html += `</div>`;
  }
  
  html += `</div>`;
  container.innerHTML = html;
}

function renderFamilyFallback() {
  const container = document.getElementById('familyView');
  if (!container) return;
  
  container.innerHTML = `
    <div style="padding:20px;">
      <h3 style="margin-bottom:20px;color:#1e293b;">👨👩‍👧 Семья</h3>
      <div style="background:#f8fafc;padding:40px;border-radius:16px;text-align:center;">
        <p style="color:#94a3b8;">Нет членов семьи</p>
      </div>
    </div>
  `;
}

function renderNotesFallback() {
  const container = document.getElementById('notesView');
  if (!container) return;
  
  container.innerHTML = `
    <div style="padding:20px;">
      <h3 style="margin-bottom:20px;color:#1e293b;">📝 Заметки</h3>
      <div style="background:#f8fafc;padding:40px;border-radius:16px;text-align:center;">
        <p style="color:#94a3b8;">Нет заметок</p>
      </div>
    </div>
  `;
}

function renderTasksFallback() {
  const container = document.getElementById('tasksView');
  if (!container) return;
  
  container.innerHTML = `
    <div style="padding:20px;">
      <h3 style="margin-bottom:20px;color:#1e293b;">✅ Задачи</h3>
      <div style="background:#f8fafc;padding:40px;border-radius:16px;text-align:center;">
        <p style="color:#94a3b8;">Нет задач</p>
      </div>
    </div>
  `;
}

function renderStatsFallback() {
  const container = document.getElementById('statsView');
  if (!container) return;
  
  const entries = Store.getEntries();
  const workEntries = entries.filter(e => e.category === 'work');
  const totalIncome = workEntries.reduce((sum, e) => sum + (parseInt(e.price) || 0), 0);
  
  container.innerHTML = `
    <div style="padding:20px;">
      <h3 style="margin-bottom:20px;color:#1e293b;">📊 Статистика</h3>
      <div style="background:linear-gradient(135deg,#667eea,#764ba2);color:white;padding:24px;border-radius:16px;margin-bottom:16px;">
        <div style="font-size:32px;font-weight:700;margin-bottom:8px;">${totalIncome}₽</div>
        <div style="opacity:0.9;">Общий доход</div>
      </div>
      <div style="background:white;padding:20px;border-radius:16px;">
        <div style="margin-bottom:12px;">
          <div style="color:#64748b;font-size:14px;">Всего записей</div>
          <div style="font-size:24px;font-weight:700;color:#1e293b;">${entries.length}</div>
        </div>
        <div>
          <div style="color:#64748b;font-size:14px;">Рабочих записей</div>
          <div style="font-size:24px;font-weight:700;color:#1e293b;">${workEntries.length}</div>
        </div>
      </div>
    </div>
  `;
}

// ============================================
// ОТКРЫТИЕ ФОРМЫ ДОБАВЛЕНИЯ
// ============================================
window.openQuickAdd = function() {
  console.log('➕ Кнопка + нажата, текущая вкладка:', AppState.currentTab);
  
  const tabName = AppState.currentTab;
  
  if (tabName === 'calendar' || tabName === 'work') {
    if (typeof window.openWorkForm === 'function') {
      window.openWorkForm();
    } else {
      alert('Форма добавления записи будет здесь');
    }
  } else if (tabName === 'family') {
    if (typeof window.openFamilyForm === 'function') {
      window.openFamilyForm();
    } else {
      alert('Форма добавления члена семьи');
    }
  } else if (tabName === 'notes') {
    if (typeof window.openNoteForm === 'function') {
      window.openNoteForm();
    } else {
      alert('Форма добавления заметки');
    }
  } else {
    alert('Выберите вкладку и нажмите + для добавления');
  }
};

// ============================================
// НАСТРОЙКА НАВИГАЦИИ
// ============================================
function setupNavigation() {
  console.log('🔧 Настройка навигации...');
  
  document.querySelectorAll('.nav-item').forEach(btn => {
    btn.addEventListener('click', function() {
      const tabName = this.dataset.tab;
      switchTab(tabName);
    });
  });
  
  console.log('✅ Навигация настроена');
}

// ============================================
// ЗАПУСК ПРИ ЗАГРУЗКЕ
// ============================================
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', function() {
    console.log('📄 DOM загружен, запускаем...');
    setupNavigation();
    initApp();
  });
} else {
  console.log('📄 DOM уже загружен, запускаем...');
  setupNavigation();
  initApp();
}

console.log('✅ app.js загружен и готов к работе');

// === ФОРМА ДОБАВЛЕНИЯ ЗАПИСИ ===
window.openWorkForm = function(entryId = null, presetDate = null) {
  console.log('📝 Открытие формы записи');
  
  const isEdit = entryId !== null;
  let entry = null;
  
  if (isEdit) {
    entry = Store.getEntries().find(e => e.id === entryId);
  }
  
  const dateValue = presetDate || (entry ? entry.date : new Date().toISOString().split('T')[0]);
  const timeValue = entry ? entry.time : '10:00';
  const durationValue = entry ? entry.duration : 60;
  const nameValue = entry ? entry.name : '';
  const serviceValue = entry ? entry.service : '';
  const priceValue = entry ? entry.price : '';
  const phoneValue = entry ? entry.phone : '';
  const notesValue = entry ? entry.notes : '';
  
  const html = `
    <div style="padding:20px;">
      <h3 style="margin:0 0 20px 0;color:#1e293b;">${isEdit ? '✏️ Редактировать запись' : '➕ Новая запись'}</h3>
      
      <form id="workEntryForm" onsubmit="return saveWorkEntry(event, ${entryId})">
        <label style="display:block;margin-bottom:5px;font-weight:600;color:#1e293b;">Имя клиента *</label>
        <input type="text" id="entryName" value="${nameValue}" required 
          style="width:100%;padding:12px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
        
        <label style="display:block;margin-bottom:5px;font-weight:600;color:#1e293b;">Телефон</label>
        <input type="tel" id="entryPhone" value="${phoneValue}" 
          style="width:100%;padding:12px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
        
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:15px;">
          <div>
            <label style="display:block;margin-bottom:5px;font-weight:600;color:#1e293b;">Дата *</label>
            <input type="date" id="entryDate" value="${dateValue}" required 
              style="width:100%;padding:12px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
          </div>
          <div>
            <label style="display:block;margin-bottom:5px;font-weight:600;color:#1e293b;">Время *</label>
            <input type="time" id="entryTime" value="${timeValue}" required 
              style="width:100%;padding:12px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
          </div>
        </div>
        
        <label style="display:block;margin-bottom:5px;font-weight:600;color:#1e293b;">Длительность (мин) *</label>
        <input type="number" id="entryDuration" value="${durationValue}" min="15" max="480" required 
          style="width:100%;padding:12px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
        
        <label style="display:block;margin-bottom:5px;font-weight:600;color:#1e293b;">Услуга</label>
        <input type="text" id="entryService" value="${serviceValue}" 
          style="width:100%;padding:12px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
        
        <label style="display:block;margin-bottom:5px;font-weight:600;color:#1e293b;">Цена (₽)</label>
        <input type="number" id="entryPrice" value="${priceValue}" min="0" 
          style="width:100%;padding:12px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
        
        <label style="display:block;margin-bottom:5px;font-weight:600;color:#1e293b;">Заметки</label>
        <textarea id="entryNotes" rows="3" 
          style="width:100%;padding:12px;margin-bottom:20px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">${notesValue}</textarea>
        
        <div style="display:flex;gap:10px;">
          <button type="submit" 
            style="flex:1;padding:15px;background:linear-gradient(135deg,#ff6b9d,#ff8e53);color:white;border:none;border-radius:12px;font-weight:700;font-size:16px;cursor:pointer;">
            💾 Сохранить
          </button>
          <button type="button" onclick="closeModal()" 
            style="flex:1;padding:15px;background:#e0e0e0;color:#333;border:none;border-radius:12px;font-weight:700;font-size:16px;cursor:pointer;">
            Отмена
          </button>
        </div>
      </form>
    </div>
  `;
  
  showModal(html);
};

// Сохранение записи
window.saveWorkEntry = function(e, entryId) {
  e.preventDefault();
  console.log('💾 Сохранение записи...');
  
  const entryData = {
    name: document.getElementById('entryName').value,
    phone: document.getElementById('entryPhone').value,
    date: document.getElementById('entryDate').value,
    time: document.getElementById('entryTime').value,
    duration: parseInt(document.getElementById('entryDuration').value),
    service: document.getElementById('entryService').value,
    price: parseInt(document.getElementById('entryPrice').value) || 0,
    notes: document.getElementById('entryNotes').value,
    category: 'work',
    status: 'new'
  };
  
  if (entryId) {
    // Редактирование
    Store.updateEntry(entryId, entryData);
    console.log('✅ Запись обновлена:', entryId);
  } else {
    // Новая запись
    Store.addEntry(entryData);
    console.log('✅ Запись создана');
  }
  
  closeModal();
  
  // Обновляем текущую вкладку
  setTimeout(() => {
    const currentTab = AppState.currentTab;
    if (currentTab === 'calendar') {
      CalendarView.render();
    } else if (currentTab === 'work') {
      WorkView.render();
    }
  }, 200);
  
  return false;
};

// Модальное окно
window.showModal = function(content) {
  const modal = document.createElement('div');
  modal.id = 'modalOverlay';
  modal.style.cssText = 'position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.5);z-index:2000;display:flex;align-items:center;justify-content:center;padding:20px;';
  
  const modalContent = document.createElement('div');
  modalContent.style.cssText = 'background:white;border-radius:20px;max-width:500px;width:100%;max-height:90vh;overflow-y:auto;box-shadow:0 10px 40px rgba(0,0,0,0.3);';
  modalContent.innerHTML = content;
  
  modal.appendChild(modalContent);
  document.body.appendChild(modal);
  
  modal.addEventListener('click', function(e) {
    if (e.target === modal) {
      closeModal();
    }
  });
};

window.closeModal = function() {
  const modal = document.getElementById('modalOverlay');
  if (modal) {
    modal.remove();
  }
};

console.log('✅ Форма добавления записей загружена');
