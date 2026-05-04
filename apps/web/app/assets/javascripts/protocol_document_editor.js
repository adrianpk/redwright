(function () {
  function formatTimestamp(timestamp) {
    if (!timestamp) return "Not saved yet";

    var date = new Date(timestamp);
    if (Number.isNaN(date.getTime())) return "Saved";

    return "Last saved " + date.toLocaleString();
  }

  function installProtocolAutosave(form) {
    var statusNode = document.querySelector("[data-protocol-save-status]");
    if (!statusNode) return;

    var csrfToken = document.querySelector("meta[name='csrf-token']")?.content;
    var dirty = false;
    var saving = false;

    function setStatus(message) {
      statusNode.textContent = message;
    }

    function markDirty() {
      dirty = true;
      if (!saving) setStatus("Unsaved changes");
    }

    async function autosave() {
      if (!dirty || saving) return;

      saving = true;
      setStatus("Autosaving...");

      try {
        var response = await fetch(form.action, {
          method: "PATCH",
          headers: {
            "Accept": "application/json",
            "X-CSRF-Token": csrfToken,
            "X-Requested-With": "XMLHttpRequest"
          },
          body: new FormData(form),
          credentials: "same-origin"
        });

        if (!response.ok) throw new Error("autosave_failed");

        var payload = await response.json();
        dirty = false;
        setStatus(formatTimestamp(payload.updated_at));
      } catch (_error) {
        setStatus("Autosave failed");
      } finally {
        saving = false;
      }
    }

    form.addEventListener("input", markDirty);
    window.setInterval(autosave, 30000);
    setStatus(formatTimestamp(form.dataset.lastSavedAt));
  }

  document.addEventListener("DOMContentLoaded", function () {
    var form = document.querySelector("[data-protocol-autosave-form]");
    if (form) installProtocolAutosave(form);
  });
}());
