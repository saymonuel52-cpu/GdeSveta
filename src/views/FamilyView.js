/**
 * FAMILY VIEW v3.0
 * С редактированием и красивыми карточками
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
    
    let members = Store.getFamilyMembers() || [];
    
    // Фильтрация по роли
    if (this.filter !== 'all') {
      const roleMap = {
        school: ['Сын', 'Дочь'],
        circles: ['Сын', 'Дочь'],
        doctor: ['Сын', 'Дочь', 'Муж', 'Жена'],
        dog: []
      };
      const allowed = roleMap[this.filter] || [];
      if (allowed.length > 0) {
        members = members.filter(m => allowed.includes(m.role));
      }
    }
    
    let html = `
      <div class="family-filters">
        <button class="family-filter ${this.filter === 'all' ? 'active' : ''}" data-filter="all">Все</button>
        <button class="family-filter ${this.filter === 'school' ? 'active' : ''}" data-filter="school"> Школа</button>
        <button class="family-filter ${this.filter === 'circles' ? 'active' : ''}" data-filter="circles"> Кружки</button>
        <button class="family-filter ${this.filter === 'doctor' ? 'active' : ''}" data-filter="doctor"> Врачи</button>
        <button class="family-filter ${this.filter === 'dog' ? 'active' : ''}" data-filter="dog">🐕 Собака</button>
      </div>
    `;
    
    if (members.length === 0) {
      html += '<div class="empty-state">Нет членов семьи</div>';
    } else {
      members.forEach(member => {
        if (typeof renderFamilyMemberCard === 'function') {
          html += renderFamilyMemberCard(member);
        } else {
          html += `<div style="padding:15px;background:white;border-radius:12px;margin:10px 0;">
            <b>${member.name}</b> - ${member.role || ''}
            <button onclick="editFamilyMember(${member.id})" style="margin-left:10px;">✏️</button>
          </div>`;
        }
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
  },
  
  setupListeners() {
    Events.on('family:updated', () => this.render());
  }
};

window.FamilyView = FamilyView;
console.log('✅ FamilyView v3.0 загружен');
