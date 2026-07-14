/**
 * FAMILY SERVICE
 * Бизнес-логика для управления семьёй
 */

const FamilyService = {
  getAll() {
    return Store.getFamilyMembers();
  },
  
  getById(id) {
    return Store.getFamilyMembers().find(m => m.id === id);
  },
  
  getChildren() {
    return Store.getFamilyMembers().filter(m => m.role === 'child' && m.active);
  },
  
  getAdults() {
    return Store.getFamilyMembers().filter(m => m.role === 'adult' && m.active);
  },
  
  getDogs() {
    return Store.getFamilyMembers().filter(m => m.role === 'dog' && m.active);
  },
  
  create(data) {
    const member = FamilyMember.create(data);
    const validation = FamilyMember.validate(member);
    
    if (!validation.valid) {
      throw new Error(validation.errors.join(', '));
    }
    
    Store.addFamilyMember(member);
    Events.emit('family:created', member);
    return member;
  },
  
  update(id, updates) {
    const member = this.getById(id);
    if (!member) throw new Error('Член семьи не найден');
    
    const updated = { ...member, ...updates, updatedAt: new Date().toISOString() };
    const validation = FamilyMember.validate(updated);
    
    if (!validation.valid) {
      throw new Error(validation.errors.join(', '));
    }
    
    const members = Store.getFamilyMembers();
    const index = members.findIndex(m => m.id === id);
    members[index] = updated;
    Storage.set('gdesveta_store', { ...Storage.get('gdesveta_store'), familyMembers: members });
    
    Events.emit('family:updated', updated);
    return updated;
  },
  
  delete(id) {
    Store.deleteFamilyMember(id);
    Events.emit('family:deleted', id);
  },
  
  getCirclesForMember(memberId) {
    const member = this.getById(memberId);
    return member ? member.circles : [];
  },
  
  getScheduleForMember(memberId, date) {
    const entries = EntryService.getByDate(date);
    return entries.filter(e => e.familyMemberId === memberId);
  },
  
  getNextEventForMember(memberId) {
    const today = Utils.getToday();
    const entries = EntryService.getAll()
      .filter(e => e.familyMemberId === memberId && e.date >= today && e.status !== 'cancelled')
      .sort((a, b) => (a.date + a.time).localeCompare(b.date + b.time));
    
    return entries[0] || null;
  }
};

window.FamilyService = FamilyService;
