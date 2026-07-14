/**
 * ENTRY CARD COMPONENT v7.0 - ИСПРАВЛЕННАЯ
 */

const EntryCard = {
  render(entry, options = {}) {
    const endTime = Entry.getEndTime(entry);
    const statusLabel = Entry.getStatusLabel(entry.status);
    const categoryIcons = { work: '💼', family: '👨‍👩‍👧', dog: '🐕' };
    
    return `
      <div class="entry-card category-${entry.category} status-${entry.status}" data-id="${entry.id}">
        <div class="entry-compact-info" onclick="window.toggleEntryCard(${entry.id})" style="cursor:pointer;">
          <span class="entry-compact-time">${entry.time} - ${endTime}</span>
          <span class="entry-compact-name">${categoryIcons[entry.category] || ''} ${entry.name}</span>
          ${entry.price > 0 ? `<span class="entry-compact-price">${entry.price}₽</span>` : ''}
          <span class="expand-icon" id="expand-${entry.id}">▼</span>
        </div>
        
        <div class="entry-details" id="details-${entry.id}" style="display:none;">
          <div><b>${entry.name}</b> <span class="status-badge status-${entry.status}">${statusLabel}</span></div>
          <div style="margin-top:5px;">
            ${entry.service}
            ${entry.zone ? ' · ' + entry.zone : ''}
            ${entry.phone ? ' · 📞 ' + entry.phone : ''}
            · ⏱️ ${entry.duration} мин
          </div>
          ${entry.notes ? `<div style="margin-top:5px;font-style:italic;">💬 ${entry.notes}</div>` : ''}
        </div>
        
        <div class="status-buttons" id="status-${entry.id}" style="display:none;">
          <button class="status-btn ${entry.status==='new'?'active':''}" onclick="window.changeStatus(${entry.id}, 'new')">Новая</button>
          <button class="status-btn ${entry.status==='confirmed'?'active':''}" onclick="window.changeStatus(${entry.id}, 'confirmed')">Подтв.</button>
          <button class="status-btn ${entry.status==='done'?'active':''}" onclick="window.changeStatus(${entry.id}, 'done')">Выполн.</button>
          <button class="status-btn ${entry.status==='cancelled'?'active':''}" onclick="window.changeStatus(${entry.id}, 'cancelled')">Отмена</button>
        </div>
        
        <div class="entry-actions" id="actions-${entry.id}" style="display:none;">
          <button class="btn-edit" onclick="window.editEntry(${entry.id})">️ Изменить</button>
          <button class="btn-dup" onclick="window.duplicateEntryWithDays(${entry.id})">📋 Копия</button>
          <button class="btn-del" onclick="window.deleteEntry(${entry.id})">️ Удалить</button>
        </div>
      </div>
    `;
  }
};

window.EntryCard = EntryCard;

// Глобальная функция для раскрытия карточки
window.toggleEntryCard = function(id) {
  console.log('toggleEntryCard:', id);
  const details = document.getElementById(`details-${id}`);
  const status = document.getElementById(`status-${id}`);
  const actions = document.getElementById(`actions-${id}`);
  const expand = document.getElementById(`expand-${id}`);
  
  if (details && status && actions) {
    const isHidden = details.style.display === 'none' || details.style.display === '';
    details.style.display = isHidden ? 'block' : 'none';
    status.style.display = isHidden ? 'block' : 'none';
    actions.style.display = isHidden ? 'block' : 'none';
    if (expand) expand.textContent = isHidden ? '▲' : '▼';
    console.log('Карточка', isHidden ? 'раскрыта' : 'скрыта');
  }
};
