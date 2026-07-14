/**
 * WORK VIEW v2.0
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
    
    const filterSelect = document.getElementById('workFilter');
    if (filterSelect) {
      filterSelect.addEventListener('change', (e) => {
        this.filter = e.target.value;
        this.render();
      });
    }
  },
  
  setupListeners() {
    Events.on('entry:created', () => this.render());
    Events.on('entry:updated', () => this.render());
    Events.on('entry:deleted', () => this.render());
  }
};

window.WorkView = WorkView;
