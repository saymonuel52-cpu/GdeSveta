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
