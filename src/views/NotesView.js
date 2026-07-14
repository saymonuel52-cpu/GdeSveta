/**
 * NOTES VIEW v2.0
 * Без attachEvents — используем inline onclick
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
        <button class="note-filter ${this.filter === 'shopping' ? 'active' : ''}" data-filter="shopping">🛒 Покупки</button>
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
    
    // Фильтры
    this.container.querySelectorAll('.note-filter').forEach(btn => {
      btn.addEventListener('click', () => {
        this.filter = btn.dataset.filter;
        this.render();
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
