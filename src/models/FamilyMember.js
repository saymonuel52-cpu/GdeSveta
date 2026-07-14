/**
 * FAMILY MEMBER MODEL
 */
const FamilyMember = {
  create(data) {
    return {
      id: Utils.generateId(),
      name: data.name || '',
      role: data.role || 'child',
      age: data.age || null,
      phone: data.phone || '',
      school: data.school || '',
      circles: data.circles || [],
      breed: data.breed || '',
      photo: data.photo || null,
      active: data.active !== false,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
  },
  
  validate(member) {
    const errors = [];
    if (!member.name || member.name.trim() === '') errors.push('Имя обязательно');
    return { valid: errors.length === 0, errors };
  },
  
  getRoleIcon(role) {
    const icons = {
      child: '👶',
      adult: '👤',
      dog: ''
    };
    return icons[role] || '👤';
  },
  
  getRoleLabel(role) {
    const labels = {
      child: 'Ребёнок',
      adult: 'Взрослый',
      dog: 'Собака'
    };
    return labels[role] || role;
  },
  
  getCirclesText(circles) {
    if (!circles || circles.length === 0) return '';
    return circles.join(', ');
  }
};
window.FamilyMember = FamilyMember;
