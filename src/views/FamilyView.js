/**
 * FAMILY VIEW v2.0
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
        <button class="family-filter ${this.filter === 'circle' ? 'active' : ''}" data-filter="circle"> Кружки</button>
        <button class="family-filter ${this.filter === 'doctor' ? 'active' : ''}" data-filter="doctor"> Врачи</button>
        <button class="family-filter ${this.filter === 'dog' ? 'active' : ''}" data-filter="dog"> Собака</button>
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
    
    this.container.querySelectorAll('.family-filter').forEach(btn => {
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

window.FamilyView = FamilyView;
