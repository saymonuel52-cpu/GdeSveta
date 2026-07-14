/**
 * MODAL COMPONENT v2.0
 * ИСПРАВЛЕННАЯ ВЕРСИЯ - inline onclick
 */
const Modal = {
  currentModal: null,
  
  create(options) {
    // Удаляем старую модалку если есть
    if (this.currentModal) {
      this.currentModal.remove();
    }
    
    const modal = document.createElement('div');
    modal.className = 'modal active';
    modal.id = 'currentModal';
    
    // ВАЖНО: onclick прямо в HTML - гарантированно работает!
    modal.innerHTML = `
      <div class="modal-content">
        <span class="close-modal" onclick="Modal.close()" style="cursor:pointer;">&times;</span>
        <h3>${options.title || ''}</h3>
        <div class="modal-body">${options.content || ''}</div>
      </div>
    `;
    
    document.body.appendChild(modal);
    this.currentModal = modal;
    
    // Закрытие по клику на фон
    modal.addEventListener('click', function(e) {
      if (e.target === modal) {
        Modal.close();
      }
    });
    
    return modal;
  },
  
  close() {
    console.log('🔴 Modal.close() вызван!');
    if (this.currentModal) {
      this.currentModal.remove();
      this.currentModal = null;
      console.log('✅ Модалка закрыта');
    }
  },
  
  alert(message, title = 'Внимание') {
    const modal = this.create({
      title,
      content: `<p>${message}</p><button class="save-btn" style="margin-top:15px;" onclick="Modal.close()">OK</button>`
    });
  },
  
  confirm(message, onConfirm, onCancel) {
    const modal = this.create({
      title: 'Подтверждение',
      content: `
        <p>${message}</p>
        <div style="display:flex;gap:10px;margin-top:15px;">
          <button class="save-btn" onclick="Modal._confirmYes()">Да</button>
          <button class="cancel-btn" onclick="Modal._confirmNo()">Нет</button>
        </div>
      `
    });
    
    // Сохраняем колбэки
    this._onConfirm = onConfirm;
    this._onCancel = onCancel;
  },
  
  _confirmYes() {
    this.close();
    if (this._onConfirm) this._onConfirm();
  },
  
  _confirmNo() {
    this.close();
    if (this._onCancel) this._onCancel();
  },
  
  form(options) {
    return this.create({
      title: options.title || 'Форма',
      content: options.content || ''
    });
  }
};

window.Modal = Modal;
