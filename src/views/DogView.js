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
