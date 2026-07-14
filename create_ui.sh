#!/bin/bash
echo " Создаю UI компоненты..."

mkdir -p src/ui/components
mkdir -p src/views

# 1. Базовый компонент Modal
cat > src/ui/components/Modal.js << 'MODAL'
/**
 * MODAL COMPONENT
 * Базовый компонент модального окна
 */

const Modal = {
  currentModal: null,
  
  /**
   * Создать модальное окно
   */
  create(options) {
    const modal = document.createElement('div');
    modal.className = 'modal active';
    modal.innerHTML = `
      <div class="modal-content">
        <span class="close-modal">&times;</span>
        <h3>${options.title || ''}</h3>
        <div class="modal-body">${options.content || ''}</div>
      </div>
    `;
    
    document.body.appendChild(modal);
    this.currentModal = modal;
    
    // Закрытие по крестику
    modal.querySelector('.close-modal').addEventListener('click', () => this.close());
    
    // Закрытие по клику на фон
    modal.addEventListener('click', (e) => {
      if (e.target === modal) this.close();
    });
    
    return modal;
  },
  
  /**
   * Закрыть модальное окно
   */
  close() {
    if (this.currentModal) {
      this.currentModal.remove();
      this.currentModal = null;
    }
  },
  
  /**
   * Показать alert
   */
  alert(message, title = 'Внимание') {
    const modal = this.create({
      title,
      content: `<p>${message}</p><button class="save-btn" style="margin-top:15px;">OK</button>`
    });
    
    modal.querySelector('button').addEventListener('click', () => this.close());
  },
  
  /**
   * Показать подтверждение
   */
  confirm(message, onConfirm, onCancel) {
    const modal = this.create({
      title: 'Подтверждение',
      content: `
        <p>${message}</p>
        <div style="display:flex;gap:10px;margin-top:15px;">
          <button class="save-btn" id="confirmYes">Да</button>
          <button class="cancel-btn" id="confirmNo">Нет</button>
        </div>
      `
    });
    
    modal.querySelector('#confirmYes').addEventListener('click', () => {
      this.close();
      if (onConfirm) onConfirm();
    });
    
    modal.querySelector('#confirmNo').addEventListener('click', () => {
      this.close();
      if (onCancel) onCancel();
    });
  },
  
  /**
   * Показать форму
   */
  form(options) {
    const modal = this.create({
      title: options.title || 'Форма',
      content: options.content || ''
    });
    
    return modal;
  }
};

window.Modal = Modal;
MODAL

echo "✅ ui/components/Modal.js создан"

# 2. Компонент Calendar
cat > src/ui/components/Calendar.js << 'CALENDAR'
/**
 * CALENDAR COMPONENT
 * Компонент календаря
 */

const Calendar = {
  currentDate: new Date(),
  selectedDate: Utils.getToday(),
  container: null,
  
  /**
   * Инициализировать календарь
   */
  init(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) {
      console.error('[Calendar] Контейнер не найден');
      return;
    }
    
    this.render();
    this.setupControls();
  },
  
  /**
   * Отрендерить календарь
   */
  render() {
    if (!this.container) return;
    
    const year = this.currentDate.getFullYear();
    const month = this.currentDate.getMonth();
    
    const monthNames = ['Январь','Февраль','Март','Апрель','Май','Июнь','Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'];
    
    let html = `
      <div class="calendar-controls">
        <button id="prevMonth">‹</button>
        <h2>${monthNames[month]} ${year}</h2>
        <button id="nextMonth">›</button>
        <button id="todayBtn" class="small-btn">Сегодня</button>
      </div>
      <div class="calendar-grid">
    `;
    
    // Дни недели
    const dayNames = ['Пн','Вт','Ср','Чт','Пт','Сб','Вс'];
    dayNames.forEach(day => {
      html += `<div class="day-header">${day}</div>`;
    });
    
    // Первый день месяца
    const firstDay = new Date(year, month, 1);
    const startOffset = (firstDay.getDay() + 6) % 7;
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const prevMonthDays = new Date(year, month, 0).getDate();
    
    const today = Utils.getToday();
    const entries = Store.getEntries();
    
    // Предыдущий месяц
    for (let i = startOffset - 1; i >= 0; i--) {
      html += `<div class="day-cell other-month">${prevMonthDays - i}</div>`;
    }
    
    // Текущий месяц
    for (let d = 1; d <= daysInMonth; d++) {
      const dateStr = `${year}-${String(month+1).padStart(2,'0')}-${String(d).padStart(2,'0')}`;
      const classes = ['day-cell'];
      
      if (dateStr === today) classes.push('today');
      if (dateStr === this.selectedDate) classes.push('selected');
      
      // Проверяем наличие записей
      const hasEntries = entries.some(e => e.date === dateStr && e.status !== 'cancelled');
      if (hasEntries) {
        const workEntries = entries.filter(e => e.date === dateStr && e.category === 'work' && e.status !== 'cancelled');
        const familyEntries = entries.filter(e => e.date === dateStr && e.category === 'family' && e.status !== 'cancelled');
        
        if (workEntries.length > 0) classes.push('has-work');
        if (familyEntries.length > 0) classes.push('has-family');
      }
      
      html += `<div class="${classes.join(' ')}" data-date="${dateStr}">${d}</div>`;
    }
    
    html += `</div>`;
    this.container.innerHTML = html;
    
    // Обработчики кликов по дням
    this.container.querySelectorAll('.day-cell[data-date]').forEach(cell => {
      cell.addEventListener('click', () => {
        this.selectedDate = cell.dataset.date;
        this.render();
        Events.emit('date:selected', this.selectedDate);
      });
    });
  },
  
  /**
   * Настроить кнопки управления
   */
  setupControls() {
    const prevBtn = document.getElementById('prevMonth');
    const nextBtn = document.getElementById('nextMonth');
    const todayBtn = document.getElementById('todayBtn');
    
    if (prevBtn) {
      prevBtn.addEventListener('click', () => {
        this.currentDate.setMonth(this.currentDate.getMonth() - 1);
        this.render();
      });
    }
    
    if (nextBtn) {
      nextBtn.addEventListener('click', () => {
        this.currentDate.setMonth(this.currentDate.getMonth() + 1);
        this.render();
      });
    }
    
    if (todayBtn) {
      todayBtn.addEventListener('click', () => {
        this.currentDate = new Date();
        this.selectedDate = Utils.getToday();
        this.render();
        Events.emit('date:selected', this.selectedDate);
      });
    }
  },
  
  /**
   * Получить выбранную дату
   */
  getSelectedDate() {
    return this.selectedDate;
  },
  
  /**
   * Перейти к дате
   */
  goToDate(date) {
    this.selectedDate = date;
    this.currentDate = new Date(date);
    this.render();
  }
};

window.Calendar = Calendar;
CALENDAR

echo "✅ ui/components/Calendar.js создан"

# 3. Компонент EntryCard
cat > src/ui/components/EntryCard.js << 'ENTRYCARD'
/**
 * ENTRY CARD COMPONENT
 * Компонент карточки записи
 */

const EntryCard = {
  /**
   * Создать HTML карточки записи
   */
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
          <button class="status-btn ${entry.status==='new'?'active':''}" data-status="new">Новая</button>
          <button class="status-btn ${entry.status==='confirmed'?'active':''}" data-status="confirmed">Подтв.</button>
          <button class="status-btn ${entry.status==='done'?'active':''}" data-status="done">Выполн.</button>
          <button class="status-btn ${entry.status==='cancelled'?'active':''}" data-status="cancelled">Отмена</button>
        </div>
        
        <div class="entry-actions">
          <button class="btn-edit" data-action="edit">✏️ Изменить</button>
          <button class="btn-dup" data-action="duplicate">📋 Копия</button>
          <button class="btn-del" data-action="delete">🗑️ Удалить</button>
        </div>
      </div>
    `;
  },
  
  /**
   * Добавить обработчики событий
   */
  attachEvents(card, callbacks = {}) {
    // Раскрытие/сворачивание
    card.addEventListener('click', (e) => {
      if (e.target.closest('.status-btn') || e.target.closest('.entry-actions button')) return;
      card.classList.toggle('expanded');
      card.classList.toggle('compact');
    });
    
    // Смена статуса
    card.querySelectorAll('.status-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        if (callbacks.onStatusChange) {
          callbacks.onStatusChange(parseInt(card.dataset.id), btn.dataset.status);
        }
      });
    });
    
    // Действия
    card.querySelectorAll('.entry-actions button').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const action = btn.dataset.action;
        const id = parseInt(card.dataset.id);
        
        if (action === 'edit' && callbacks.onEdit) {
          callbacks.onEdit(id);
        } else if (action === 'duplicate' && callbacks.onDuplicate) {
          callbacks.onDuplicate(id);
        } else if (action === 'delete' && callbacks.onDelete) {
          callbacks.onDelete(id);
        }
      });
    });
  }
};

window.EntryCard = EntryCard;
ENTRYCARD

echo "✅ ui/components/EntryCard.js создан"

# 4. Компонент NoteCard
cat > src/ui/components/NoteCard.js << 'NOTECARD'
/**
 * NOTE CARD COMPONENT
 * Компонент карточки заметки
 */

const NoteCard = {
  render(note) {
    const icon = Note.getCategoryIcon(note.category);
    
    return `
      <div class="note-card ${note.category} ${note.completed ? 'completed' : ''}" data-id="${note.id}">
        <div class="note-title">${icon} ${note.title}</div>
        ${note.text ? `<div class="note-text">${note.text}</div>` : ''}
        <div class="note-meta">
          <span>${note.date ? Utils.formatDate(note.date, 'short') : 'Без даты'}</span>
          <span>${icon}</span>
        </div>
        <div class="note-actions">
          <button class="btn-edit" data-action="edit">✏️</button>
          <button class="btn-del" data-action="delete">️</button>
        </div>
      </div>
    `;
  },
  
  attachEvents(card, callbacks = {}) {
    card.querySelectorAll('.note-actions button').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const action = btn.dataset.action;
        const id = parseInt(card.dataset.id);
        
        if (action === 'edit' && callbacks.onEdit) {
          callbacks.onEdit(id);
        } else if (action === 'delete' && callbacks.onDelete) {
          callbacks.onDelete(id);
        }
      });
    });
  }
};

window.NoteCard = NoteCard;
NOTECARD

echo "✅ ui/components/NoteCard.js создан"

# 5. Компонент FamilySelect
cat > src/ui/components/FamilySelect.js << 'FAMILYSELECT'
/**
 * FAMILY SELECT COMPONENT
 * Компонент выбора члена семьи
 */

const FamilySelect = {
  /**
   * Создать HTML селекта
   */
  render(selectedId = null) {
    const members = FamilyService.getAll();
    
    if (members.length === 0) {
      return '<div class="empty-state">Нет членов семьи</div>';
    }
    
    let html = '<select class="family-select">';
    html += '<option value="">-- Выберите --</option>';
    
    members.forEach(member => {
      const icon = FamilyMember.getRoleIcon(member.role);
      const selected = member.id === selectedId ? 'selected' : '';
      html += `<option value="${member.id}" ${selected}>${icon} ${member.name}</option>`;
    });
    
    html += '</select>';
    return html;
  },
  
  /**
   * Получить выбранный ID
   */
  getSelectedId(selectElement) {
    return selectElement.value ? parseInt(selectElement.value) : null;
  },
  
  /**
   * Получить выбранного члена семьи
   */
  getSelectedMember(selectElement) {
    const id = this.getSelectedId(selectElement);
    return id ? FamilyService.getById(id) : null;
  }
};

window.FamilySelect = FamilySelect;
FAMILYSELECT

echo "✅ ui/components/FamilySelect.js создан"

# 6. View: CalendarView
cat > src/views/CalendarView.js << 'CALENDARVIEW'
/**
 * CALENDAR VIEW
 * Страница календаря
 */

const CalendarView = {
  container: null,
  
  init(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) return;
    
    this.render();
    this.setupListeners();
  },
  
  render() {
    if (!this.container) return;
    
    const selectedDate = Calendar.getSelectedDate();
    const entries = EntryService.getByDate(selectedDate);
    const notes = NoteService.getByDate(selectedDate);
    
    let html = `
      <div id="calendarContainer"></div>
      <div class="legend">
        <span class="legend-item"><span class="legend-color work"></span>Работа</span>
        <span class="legend-item"><span class="legend-color family"></span>Семья</span>
        <span class="legend-item"><span class="legend-color note"></span>Заметки</span>
      </div>
      <h3 style="margin:15px 0 10px;">${Utils.formatDate(selectedDate, 'long')}</h3>
    `;
    
    // Заметки
    notes.forEach(note => {
      html += NoteCard.render(note);
    });
    
    // Записи
    if (entries.length === 0 && notes.length === 0) {
      html += '<div class="empty-state">Нет записей на этот день</div>';
    } else {
      entries.forEach(entry => {
        html += EntryCard.render(entry);
      });
    }
    
    this.container.innerHTML = html;
    
    // Инициализируем календарь
    Calendar.init('calendarContainer');
    
    // Добавляем обработчики к карточкам
    this.container.querySelectorAll('.entry-card').forEach(card => {
      EntryCard.attachEvents(card, {
        onStatusChange: (id, status) => {
          EntryService.changeStatus(id, status);
          this.render();
        },
        onEdit: (id) => {
          Events.emit('entry:edit', id);
        },
        onDuplicate: (id) => {
          EntryService.duplicate(id);
          this.render();
        },
        onDelete: (id) => {
          Modal.confirm('Удалить запись?', () => {
            EntryService.delete(id);
            this.render();
          });
        }
      });
    });
    
    this.container.querySelectorAll('.note-card').forEach(card => {
      NoteCard.attachEvents(card, {
        onEdit: (id) => {
          Events.emit('note:edit', id);
        },
        onDelete: (id) => {
          Modal.confirm('Удалить заметку?', () => {
            NoteService.delete(id);
            this.render();
          });
        }
      });
    });
  },
  
  setupListeners() {
    Events.on('date:selected', () => {
      this.render();
    });
    
    Events.on('entry:created', () => {
      this.render();
    });
    
    Events.on('entry:updated', () => {
      this.render();
    });
    
    Events.on('entry:deleted', () => {
      this.render();
    });
  }
};

window.CalendarView = CalendarView;
CALENDARVIEW

echo "✅ views/CalendarView.js создан"

# 7. View: WorkView
cat > src/views/WorkView.js << 'WORKVIEW'
/**
 * WORK VIEW
 * Страница работы
 */

const WorkView = {
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
    
    let entries = EntryService.getByCategory('work');
    
    const today = Utils.getToday();
    const weekLater = new Date();
    weekLater.setDate(weekLater.getDate() + 7);
    const weekLaterStr = weekLater.toISOString().split('T')[0];
    
    if (this.filter === 'today') {
      entries = entries.filter(e => e.date === today);
    } else if (this.filter === 'week') {
      entries = entries.filter(e => e.date >= today && e.date <= weekLaterStr);
    }
    
    entries.sort((a, b) => (a.date + a.time).localeCompare(b.date + b.time));
    
    let html = `
      <div class="filter-bar">
        <select id="workFilter">
          <option value="all" ${this.filter === 'all' ? 'selected' : ''}>Все</option>
          <option value="today" ${this.filter === 'today' ? 'selected' : ''}>Сегодня</option>
          <option value="week" ${this.filter === 'week' ? 'selected' : ''}>Неделя</option>
        </select>
      </div>
    `;
    
    if (entries.length === 0) {
      html += '<div class="empty-state">Нет рабочих записей</div>';
    } else {
      entries.forEach(entry => {
        html += EntryCard.render(entry);
      });
    }
    
    this.container.innerHTML = html;
    
    // Обработчик фильтра
    const filterSelect = document.getElementById('workFilter');
    if (filterSelect) {
      filterSelect.addEventListener('change', (e) => {
        this.filter = e.target.value;
        this.render();
      });
    }
    
    // Обработчики карточек
    this.container.querySelectorAll('.entry-card').forEach(card => {
      EntryCard.attachEvents(card, {
        onStatusChange: (id, status) => {
          EntryService.changeStatus(id, status);
          this.render();
        },
        onEdit: (id) => Events.emit('entry:edit', id),
        onDuplicate: (id) => {
          EntryService.duplicate(id);
          this.render();
        },
        onDelete: (id) => {
          Modal.confirm('Удалить запись?', () => {
            EntryService.delete(id);
            this.render();
          });
        }
      });
    });
  },
  
  setupListeners() {
    Events.on('entry:created', () => this.render());
    Events.on('entry:updated', () => this.render());
    Events.on('entry:deleted', () => this.render());
  }
};

window.WorkView = WorkView;
WORKVIEW

echo "✅ views/WorkView.js создан"

# 8. View: FamilyView
cat > src/views/FamilyView.js << 'FAMILYVIEW'
/**
 * FAMILY VIEW
 * Страница семьи
 */

const FamilyView = {
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
    
    let entries = EntryService.getByCategory('family');
    const dogEntries = EntryService.getByCategory('dog');
    entries = [...entries, ...dogEntries];
    
    if (this.filter !== 'all') {
      const filterMap = {
        school: ['Школа', 'Садик'],
        circle: ['Кружок', 'Секция'],
        doctor: ['Врач'],
        dog: ['Ветеринар', 'Груминг', 'Прогулка']
      };
      const allowed = filterMap[this.filter] || [];
      entries = entries.filter(e => allowed.includes(e.service));
    }
    
    entries.sort((a, b) => (a.date + a.time).localeCompare(b.date + b.time));
    
    let html = `
      <div class="family-filters">
        <button class="family-filter ${this.filter === 'all' ? 'active' : ''}" data-filter="all">Все</button>
        <button class="family-filter ${this.filter === 'school' ? 'active' : ''}" data-filter="school">🏫 Школа</button>
        <button class="family-filter ${this.filter === 'circle' ? 'active' : ''}" data-filter="circle">🎨 Кружки</button>
        <button class="family-filter ${this.filter === 'doctor' ? 'active' : ''}" data-filter="doctor">🏥 Врачи</button>
        <button class="family-filter ${this.filter === 'dog' ? 'active' : ''}" data-filter="dog">🐕 Собака</button>
      </div>
    `;
    
    if (entries.length === 0) {
      html += '<div class="empty-state">Нет семейных событий</div>';
    } else {
      entries.forEach(entry => {
        html += EntryCard.render(entry);
      });
    }
    
    this.container.innerHTML = html;
    
    // Обработчики фильтров
    this.container.querySelectorAll('.family-filter').forEach(btn => {
      btn.addEventListener('click', () => {
        this.filter = btn.dataset.filter;
        this.render();
      });
    });
    
    // Обработчики карточек
    this.container.querySelectorAll('.entry-card').forEach(card => {
      EntryCard.attachEvents(card, {
        onStatusChange: (id, status) => {
          EntryService.changeStatus(id, status);
          this.render();
        },
        onEdit: (id) => Events.emit('entry:edit', id),
        onDuplicate: (id) => {
          EntryService.duplicate(id);
          this.render();
        },
        onDelete: (id) => {
          Modal.confirm('Удалить запись?', () => {
            EntryService.delete(id);
            this.render();
          });
        }
      });
    });
  },
  
  setupListeners() {
    Events.on('entry:created', () => this.render());
    Events.on('entry:updated', () => this.render());
    Events.on('entry:deleted', () => this.render());
  }
};

window.FamilyView = FamilyView;
FAMILYVIEW

echo "✅ views/FamilyView.js создан"

# 9. View: NotesView
cat > src/views/NotesView.js << 'NOTESVIEW'
/**
 * NOTES VIEW
 * Страница заметок
 */

const NotesView = {
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
    
    let notes = NoteService.getAll();
    
    if (this.filter !== 'all') {
      notes = notes.filter(n => n.category === this.filter);
    }
    
    notes.sort((a, b) => (b.date || '').localeCompare(a.date || ''));
    
    let html = `
      <div class="note-filters">
        <button class="note-filter ${this.filter === 'all' ? 'active' : ''}" data-filter="all">Все</button>
        <button class="note-filter ${this.filter === 'important' ? 'active' : ''}" data-filter="important">⭐ Важное</button>
        <button class="note-filter ${this.filter === 'shopping' ? 'active' : ''}" data-filter="shopping"> Покупки</button>
        <button class="note-filter ${this.filter === 'ideas' ? 'active' : ''}" data-filter="ideas">💡 Идеи</button>
      </div>
    `;
    
    if (notes.length === 0) {
      html += '<div class="empty-state">Нет заметок</div>';
    } else {
      notes.forEach(note => {
        html += NoteCard.render(note);
      });
    }
    
    this.container.innerHTML = html;
    
    // Обработчики фильтров
    this.container.querySelectorAll('.note-filter').forEach(btn => {
      btn.addEventListener('click', () => {
        this.filter = btn.dataset.filter;
        this.render();
      });
    });
    
    // Обработчики карточек
    this.container.querySelectorAll('.note-card').forEach(card => {
      NoteCard.attachEvents(card, {
        onEdit: (id) => Events.emit('note:edit', id),
        onDelete: (id) => {
          Modal.confirm('Удалить заметку?', () => {
            NoteService.delete(id);
            this.render();
          });
        }
      });
    });
  },
  
  setupListeners() {
    Events.on('note:created', () => this.render());
    Events.on('note:updated', () => this.render());
    Events.on('note:deleted', () => this.render());
  }
};

window.NotesView = NotesView;
NOTESVIEW

echo "✅ views/NotesView.js создан"

# 10. View: StatsView
cat > src/views/StatsView.js << 'STATSVIEW'
/**
 * STATS VIEW
 * Страница статистики
 */

const StatsView = {
  container: null,
  
  init(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) return;
    
    this.render();
    this.setupListeners();
  },
  
  render() {
    if (!this.container) return;
    
    const today = Utils.getToday();
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    const weekAgoStr = weekAgo.toISOString().split('T')[0];
    
    const stats = EntryService.getStats(weekAgoStr, today);
    const priceStats = PriceService.getPopularServices(5);
    
    let html = `
      <div class="stats-box">
        <h3 style="margin-bottom:10px;">📊 За неделю</h3>
        <div class="stat-row"><span>Всего записей</span><span><b>${stats.total}</b></span></div>
        <div class="stat-row"><span> Работа</span><span><b>${stats.work}</b></span></div>
        <div class="stat-row"><span>👨‍‍👧 Семья</span><span><b>${stats.family}</b></span></div>
        <div class="stat-row"><span>✅ Выполнено</span><span><b style="color:#4caf50">${stats.done}</b></span></div>
        <div class="stat-row"><span>❌ Отменено</span><span><b style="color:#f44336">${stats.cancelled}</b></span></div>
      </div>
      
      <div class="stats-box">
        <h3 style="margin-bottom:10px;">💰 Доходы</h3>
        <div class="stat-row"><span>За неделю</span><span><b style="color:#ff6b9d">${stats.income}₽</b></span></div>
        <div class="stat-row"><span>Средний чек</span><span><b>${stats.work > 0 ? Math.round(stats.income / stats.work) : 0}₽</b></span></div>
      </div>
    `;
    
    if (priceStats.length > 0) {
      html += `
        <div class="stats-box">
          <h3 style="margin-bottom:10px;"> Популярные услуги</h3>
          ${priceStats.map(ps => `
            <div class="stat-row">
              <span>${ps.service}</span>
              <span><b>${ps.count} раз</b></span>
            </div>
          `).join('')}
        </div>
      `;
    }
    
    this.container.innerHTML = html;
  },
  
  setupListeners() {
    Events.on('entry:created', () => this.render());
    Events.on('entry:updated', () => this.render());
    Events.on('entry:deleted', () => this.render());
  }
};

window.StatsView = StatsView;
STATSVIEW

echo "✅ views/StatsView.js создан"

echo ""
echo "✅ Все UI компоненты созданы!"
