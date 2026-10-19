(() => {
  function initialize() {
    document.querySelectorAll('[data-dump-document]').forEach((root) => {
      if (root.dataset.editorReady) return;
      root.dataset.editorReady = 'true';
      const view = root.querySelector('[data-dump-view]');
      const form = root.querySelector('[data-dump-editor]');
      const body = form.querySelector('[name="dump[body]"]');
      const state = form.querySelector('[name="dump[status]"]');
      const revision = form.querySelector('[name="dump[revision]"]');
      const error = form.querySelector('[data-dump-error]');
      const feedback = root.querySelector('[data-dump-feedback]');
      let savedBody = body.value;
      let savedState = state.value;
      let pending;
      const dirty = () => body.value !== savedBody || state.value !== savedState;
      const close = () => { form.hidden = true; view.hidden = false; };
      const open = () => {
        view.hidden = true;
        form.hidden = false;
        feedback.textContent = '';
        body.focus();
      };
      async function save() {
        if (pending) return pending;
        if (!dirty()) { close(); return true; }
        const values = new FormData(form);
        error.hidden = true;
        feedback.textContent = 'Saving…';
        const controls = [...form.elements];
        controls.forEach((control) => { control.disabled = true; });
        pending = (async () => {
          try {
            const response = await fetch(form.action, {
              method: 'PATCH', body: values, credentials: 'same-origin',
              headers: {Accept: 'application/json', 'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content}
            });
            const result = await response.json();
            if (!response.ok) throw new Error((result.errors || ['Could not save the dump.']).join(' '));
            revision.value = result.revision;
            savedBody = body.value;
            savedState = state.value;
            view.innerHTML = result.rendered_body;
            if (!savedBody.trim()) {
              const placeholder = document.createElement('p');
              placeholder.className = 'dump-document-placeholder';
              placeholder.textContent = 'Click to write.';
              view.append(placeholder);
            }
            root.querySelector('[data-dump-state]').dataset.state = result.status;
            root.querySelector('[data-dump-state-label]').textContent = result.status_label;
            close();
            feedback.textContent = 'Saved';
            return true;
          } catch (failure) {
            error.textContent = failure.message;
            error.hidden = false;
            feedback.textContent = '';
            return false;
          } finally {
            controls.forEach((control) => { control.disabled = false; });
          }
        })();
        const result = await pending;
        pending = null;
        return result;
      }
      view.addEventListener('click', (event) => { if (!event.target.closest('a')) open(); });
      view.addEventListener('keydown', (event) => {
        if (event.target === view && ['Enter', ' '].includes(event.key)) { event.preventDefault(); open(); }
      });
      const curateForm = root.querySelector('[data-dump-curate]');
      curateForm.addEventListener('submit', async (event) => {
        event.preventDefault();
        if (!form.hidden && !(await save())) return;
        curateForm.querySelector('[name="revision"]').value = revision.value;
        curateForm.querySelector('button').disabled = true;
        feedback.textContent = 'Curating…';
        curateForm.submit();
      });
      form.addEventListener('submit', (event) => { event.preventDefault(); save(); });
      form.addEventListener('focusout', () => {
        setTimeout(() => { if (!form.hidden && !form.contains(document.activeElement) && !pending) save(); }, 0);
      });
      // Complete the save before navigation; conflicts keep the editor and its text open.
      document.addEventListener('click', async (event) => {
        const link = event.target.closest('a[href]');
        if (!link || form.hidden || !dirty() || link.target || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
        event.preventDefault();
        event.stopImmediatePropagation();
        if (await save()) window.location.assign(link.href);
      }, true);
      window.addEventListener('beforeunload', (event) => {
        if (!form.hidden && dirty()) { event.preventDefault(); event.returnValue = ''; }
      });
    });
  }
  document.addEventListener('DOMContentLoaded', initialize);
  document.addEventListener('turbo:load', initialize);
})();
