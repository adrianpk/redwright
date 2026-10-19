(() => {
  function initialize() {
    document.querySelectorAll('[data-dump-document], [data-spec-document]').forEach((root) => {
      if (root.dataset.editorReady) return;
      const spec = root.hasAttribute('data-spec-document');
      const model = spec ? 'document' : 'dump';
      const view = root.querySelector('[data-dump-view], [data-spec-view]');
      const form = root.querySelector('[data-dump-editor], [data-spec-editor]');
      if (!form) return;
      root.dataset.editorReady = 'true';
      const body = form.querySelector(`[name="${model}[body]"]`);
      const state = form.querySelector(spec ? '[name="approval"]' : '[name="dump[status]"]');
      const revision = form.querySelector(`[name="${model}[revision]"]`);
      const statusControl = root.querySelector('[data-artifact-status-control]');
      const statusOptions = [...statusControl.querySelectorAll('[data-artifact-status-option]')];
      let savedBody = body.value;
      let savedState = state.value;
      let pending;
      const dirty = () => body.value !== savedBody || state.value !== savedState;
      const close = () => { form.hidden = true; view.hidden = false; };
      const open = () => {
        view.hidden = true;
        form.hidden = false;
        body.focus();
      };
      async function save() {
        if (pending) return pending;
        if (!dirty()) { close(); return true; }
        const values = new FormData(form);
        window.showFlash('Saving…', 'pending');
        const controls = [...form.elements, ...statusOptions];
        controls.forEach((control) => { control.disabled = true; });
        pending = (async () => {
          try {
            const response = await fetch(form.action, {
              method: 'PATCH', body: values, credentials: 'same-origin',
              headers: {Accept: 'application/json', 'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content}
            });
            const result = await response.json();
            if (!response.ok) throw new Error((result.errors || ['Could not save the document.']).join(' '));
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
            statusControl.dataset.state = result.status;
            statusOptions.forEach((option) => { option.checked = option.value === result.status; });
            const slicing = root.querySelector('[data-spec-slice]');
            if (slicing) slicing.hidden = result.status === 'draft';
            root.querySelectorAll('input[name="revision"]').forEach((field) => { field.value = result.revision; });
            close();
            window.showFlash('Saved');
            return true;
          } catch (failure) {
            window.showFlash(failure.message, 'alert');
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
      root.querySelectorAll('form').forEach((actionForm) => {
        if (actionForm === form) return;
        actionForm.addEventListener('submit', async (event) => {
          event.preventDefault();
          if (!(await save())) return;
          actionForm.querySelector('button').disabled = true;
          window.showFlash(actionForm.dataset.documentAction || 'Curating…', 'pending');
          actionForm.submit();
        });
      });
      form.addEventListener('submit', (event) => { event.preventDefault(); save(); });
      statusOptions.forEach((option) => option.addEventListener('change', async () => {
        if (!option.checked || (pending && !(await pending))) return;
        state.value = option.value;
        statusControl.dataset.state = option.value;
        if (!(await save())) {
          state.value = savedState;
          statusControl.dataset.state = savedState;
          statusOptions.forEach((radio) => { radio.checked = radio.value === savedState; });
        }
      }));
      const saveOnLeave = () => {
        setTimeout(() => {
          if (!form.hidden && !form.contains(document.activeElement) && !statusControl.contains(document.activeElement) && !pending) save();
        }, 0);
      };
      form.addEventListener('focusout', saveOnLeave);
      statusControl.addEventListener('focusout', saveOnLeave);
      // Complete the save before navigation; conflicts keep the editor and its text open.
      document.addEventListener('click', async (event) => {
        const link = event.target.closest('a[href]');
        if (!link || !dirty() || link.target || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
        event.preventDefault();
        event.stopImmediatePropagation();
        if (await save()) window.location.assign(link.href);
      }, true);
      window.addEventListener('beforeunload', (event) => {
        if (dirty()) { event.preventDefault(); event.returnValue = ''; }
      });
    });
  }
  document.addEventListener('DOMContentLoaded', initialize);
  document.addEventListener('turbo:load', initialize);
})();
