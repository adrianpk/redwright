(function () {
  function installProtocolAutosave(form) {
    if (form.dataset.protocolAutosaveForm !== "true") return;
    var csrfToken = document.querySelector("meta[name='csrf-token']")?.content;
    var name = form.querySelector("[name='protocol_document[name]']");
    var description = form.querySelector("[name='protocol_document[description]']");
    var body = form.querySelector("[name='protocol_document[body]']");
    var submit = form.querySelector("[type='submit']");
    var sync = document.querySelector("[data-protocol-sync]");
    var savedName = name?.value;
    var savedDescription = description?.value;
    var dirty = false;
    var saving = false;

    function markDirty() {
      dirty = true;
    }

    function updateRevisions(payload) {
      form.querySelector("[name='protocol_document[revision]']").value = payload.revision;
      form.querySelector("[name='protocol_document[agents_revision]']").value = payload.agents_revision || "";
      form.querySelector("[name='protocol_document[index_revision]']").value = payload.index_revision || "";
      document.querySelectorAll("form[data-protocol-delete] input").forEach(function (field) {
        if (field.name === "protocol_document[revision]") field.value = payload.revision;
        if (field.name === "protocol_document[agents_revision]") field.value = payload.agents_revision || "";
        if (field.name === "protocol_document[index_revision]") field.value = payload.index_revision || "";
      });
    }

    async function syncReferences() {
      if (saving || form.dataset.submitting) return;
      saving = true;
      body.readOnly = true;
      submit.disabled = true;
      sync.disabled = true;
      window.showFlash("Syncing references…", "pending");

      try {
        var response = await fetch(sync.dataset.protocolSync, {
          method: "POST",
          headers: {"Accept": "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken},
          body: JSON.stringify({protocol_document: {
            body: body.value,
            revision: form.querySelector("[name='protocol_document[revision]']").value
          }}),
          credentials: "same-origin"
        });
        var payload = await response.json();
        if (!response.ok) throw new Error((payload.errors || ["Could not sync references. Try again."]).join(" "));
        body.value = payload.body;
        updateRevisions(payload);
        dirty = false;
        window.showFlash("References synced.");
      } catch (error) {
        window.showFlash(error.message, "alert");
      } finally {
        saving = false;
        body.readOnly = false;
        submit.disabled = false;
        sync.disabled = false;
      }
    }

    async function autosave() {
      if (!dirty || saving || form.dataset.submitting) return;
      // Renames and reference changes wait for an explicit Save.
      if (name?.value !== savedName || description?.value !== savedDescription) return;

      saving = true;
      var savedBody = body.value;
      submit.disabled = true;
      if (sync) sync.disabled = true;
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
        var payload = await response.json();
        if (!response.ok) throw new Error((payload.errors || ["Could not save. Try again."]).join(" "));
        updateRevisions(payload);
        dirty = body.value !== savedBody;
        window.showFlash("Saved");
      } catch (error) {
        window.showFlash(error.message, "alert");
      } finally {
        saving = false;
        submit.disabled = false;
        if (sync) sync.disabled = false;
      }
    }

    form.addEventListener("input", markDirty);
    form.addEventListener("submit", function () { form.dataset.submitting = "true"; });
    if (sync) sync.addEventListener("click", syncReferences);
    window.setInterval(autosave, 30000);
  }

  document.addEventListener("DOMContentLoaded", function () {
    var form = document.querySelector("[data-protocol-autosave-form]");
    if (form) installProtocolAutosave(form);
    document.querySelectorAll("form[data-protocol-delete]").forEach(function (deletion) {
      deletion.addEventListener("submit", function () {
        if (form) form.dataset.submitting = "true";
      });
    });
  });
}());
