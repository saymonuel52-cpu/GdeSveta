/**
 * SERVICES INDEX
 * Экспорт всех сервисов
 */

const Services = {
  Entry: window.EntryService,
  Note: window.NoteService,
  Price: window.PriceService,
  Family: window.FamilyService,
  Conflict: window.ConflictChecker,
  Notification: window.NotificationService
};

window.Services = Services;
