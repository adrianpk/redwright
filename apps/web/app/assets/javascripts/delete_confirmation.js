(() => {
  document.addEventListener('submit', (event) => {
    const form = event.target;
    if (event.defaultPrevented || form.querySelector('[name="_method"]')?.value.toLowerCase() !== 'delete') return;
    const message = form.dataset.deleteConfirm || form.dataset.turboConfirm;
    if (!message && !form.querySelector('.ticket-action-danger')) return;
    const confirmation = message || 'Delete this item? This cannot be undone.';
    if (window.Turbo && !form.closest('[data-turbo="false"]')) {
      form.dataset.turboConfirm = confirmation;
      return;
    }
    if (!window.confirm(confirmation)) {
      event.preventDefault();
      event.stopImmediatePropagation();
    }
  }, true);
})();
