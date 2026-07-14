/**
 * TASKS VIEW
 * Страница семейных задач
 */

const TasksView = {
  container: null,
  filter: 'active',
  
  init(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) return;
    this.render();
    this.setupListeners();
  },
  
  render() {
    if (!this.container) return;
    
    const tasks = this.filter === 'active' ? 
      FamilyShare.getActiveTasks() : 
      this.filter === 'completed' ? 
        FamilyShare.getCompletedTasks() : 
        FamilyShare.getTasks();
    
    let html = `
      <div class="task-filters">
        <button class="task-filter ${this.filter === 'active' ? 'active' : ''}" data-filter="active">
          Активные (${FamilyShare.getActiveTasks().length})
        </button>
        <button class="task-filter ${this.filter === 'completed' ? 'active' : ''}" data-filter="completed">
          Выполненные (${FamilyShare.getCompletedTasks().length})
        </button>
        <button class="task-filter ${this.filter === 'all' ? 'active' : ''}" data-filter="all">
          Все (${FamilyShare.getTasks().length})
        </button>
      </div>
    `;
    
    if (tasks.length === 0) {
      html += '<div class="empty-state">Нет задач</div>';
    } else {
      html += tasks.map(task => {
        const categoryIcons = {
          general: '📋',
          shopping: '🛒',
          home: '🏠',
          kids: '',
          dog: '',
          important: '⭐'
        };
        const icon = categoryIcons[task.category] || '📋';
        
        return `
          <div class="task-card ${task.completed ? 'completed' : ''}" data-id="${task.id}">
            <div class="task-checkbox ${task.completed ? 'checked' : ''}" onclick="toggleTask(${task.id})">
              ${task.completed ? '✓' : ''}
            </div>
            <div class="task-text">${icon} ${task.text}</div>
            ${task.assignedTo ? `<div class="task-category">${task.assignedTo}</div>` : ''}
            <button class="task-delete" onclick="deleteTask(${task.id})">🗑️</button>
          </div>
        `;
      }).join('');
    }
    
    this.container.innerHTML = html;
    
    this.container.querySelectorAll('.task-filter').forEach(btn => {
      btn.addEventListener('click', () => {
        this.filter = btn.dataset.filter;
        this.render();
      });
    });
  },
  
  setupListeners() {
    Events.on('task:added', () => this.render());
    Events.on('task:toggled', () => this.render());
    Events.on('task:deleted', () => this.render());
  }
};

window.TasksView = TasksView;

// Глобальные функции для задач
window.toggleTask = function(id) {
  FamilyShare.toggleTask(id);
};

window.deleteTask = function(id) {
  Modal.confirm('Удалить задачу?', () => {
    FamilyShare.deleteTask(id);
  });
};

window.openTaskForm = function() {
  const content = `
    <form id="taskForm">
      <label>Задача *</label>
      <input type="text" id="taskText" required placeholder="Что нужно сделать?">
      
      <label>Категория</label>
      <select id="taskCategory">
        <option value="general">📋 Обычная</option>
        <option value="shopping">🛒 Покупки</option>
        <option value="home">🏠 Дом</option>
        <option value="kids">👶 Дети</option>
        <option value="dog">🐕 Собака</option>
        <option value="important">⭐ Важная</option>
      </select>
      
      <label>Кому поручить (необязательно)</label>
      <input type="text" id="taskAssigned" placeholder="Напр. Муж, Старший">
      
      <div class="form-actions">
        <button type="submit" class="save-btn">Сохранить</button>
        <button type="button" class="cancel-btn" onclick="Modal.close()">Отмена</button>
      </div>
    </form>
  `;
  
  const modal = Modal.form({
    title: '✅ Новая задача',
    content
  });
  
  modal.querySelector('#taskForm').addEventListener('submit', (e) => {
    e.preventDefault();
    const data = {
      text: modal.querySelector('#taskText').value,
      category: modal.querySelector('#taskCategory').value,
      assignedTo: modal.querySelector('#taskAssigned').value || null
    };
    FamilyShare.addTask(data);
    Modal.close();
    Modal.alert('✅ Задача добавлена!');
  });
};
