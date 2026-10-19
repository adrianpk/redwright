(function () {
  function installProtocolAutosave(form) {
    var csrfToken = document.querySelector("meta[name='csrf-token']")?.content;
    var dirty = false;
    var saving = false;

    function markDirty() {
      dirty = true;
    }

    async function autosave() {
      if (!dirty || saving) return;

      saving = true;
      window.showFlash("Saving…", "pending");

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

        if (response.status === 409) {
          window.showFlash("File changed elsewhere. Reload before saving.", "alert");
          return;
        }
        if (!response.ok) throw new Error("autosave_failed");

        var payload = await response.json();
        form.querySelector("[name='protocol_document[revision]']").value = payload.revision;
        dirty = false;
        window.showFlash("Saved");
      } catch (_error) {
        window.showFlash("Could not save. Try again.", "alert");
      } finally {
        saving = false;
      }
    }

    form.addEventListener("input", markDirty);
    window.setInterval(autosave, 30000);
  }

  document.addEventListener("DOMContentLoaded", function () {
    var form = document.querySelector("[data-protocol-autosave-form]");
    if (form) installProtocolAutosave(form);
  });
}());
