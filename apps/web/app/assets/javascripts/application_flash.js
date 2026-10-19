(() => {
  let dismissTimer;

  function scheduleDismiss(flash) {
    clearTimeout(dismissTimer);
    if (flash.dataset.kind === 'notice' && !flash.hidden) {
      dismissTimer = setTimeout(() => { flash.hidden = true; }, 4500);
    }
  }

  // AJAX saves use the same element that the layout renders from Rails flash.
  window.showFlash = (message, kind = 'notice') => {
    const flash = document.getElementById('application-flash');
    if (!flash) return;
    flash.dataset.kind = kind;
    flash.setAttribute('role', kind === 'alert' ? 'alert' : 'status');
    flash.querySelector('[data-flash-message]').textContent = message;
    flash.hidden = false;
    scheduleDismiss(flash);
  };

  function initialize() {
    const flash = document.getElementById('application-flash');
    if (!flash || flash.dataset.bound) return;
    flash.dataset.bound = 'true';
    flash.querySelector('button').addEventListener('click', () => { flash.hidden = true; });
    const nav = document.querySelector('.top-nav');
    if (nav) {
      const position = () => { flash.style.top = `${nav.getBoundingClientRect().bottom + 12}px`; };
      new ResizeObserver(position).observe(nav);
      position();
    }
    scheduleDismiss(flash);
  }

  document.addEventListener('submit', (event) => {
    const form = event.target;
    if (event.defaultPrevented || form.method.toLowerCase() === 'get') return;
    window.showFlash(form.dataset.documentAction || form.dataset.quizProcessingMessage || 'Saving…', 'pending');
  });
  document.addEventListener('DOMContentLoaded', initialize);
  document.addEventListener('turbo:load', initialize);
  window.addEventListener('pageshow', (event) => {
    const flash = document.getElementById('application-flash');
    if (event.persisted && flash?.dataset.kind === 'pending') flash.hidden = true;
  });
})();
