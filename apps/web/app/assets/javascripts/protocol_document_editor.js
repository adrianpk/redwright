(function () {
  function installProtocolAutosave(form) {
    if (form.dataset.protocolAutosaveForm !== "true") return;
    var csrfToken = document.querySelector("meta[name='csrf-token']")?.content;
    var name = form.querySelector("[name='protocol_document[name]']");
    var description = form.querySelector("[name='protocol_document[description]']");
    var savedName = name?.value;
    var savedDescription = description?.value;
    var dirty = false;
    var saving = false;

    function markDirty() {
      dirty = true;
    }

    async function autosave() {
      if (!dirty || saving || form.dataset.submitting) return;
      // Renames and reference changes wait for an explicit Save.
      if (name?.value !== savedName || description?.value !== savedDescription) return;

      saving = true;
      var body = form.querySelector("[name='protocol_document[body]']");
      var savedBody = body.value;
      var submit = form.querySelector("[type='submit']");
      submit.disabled = true;
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
        form.querySelector("[name='protocol_document[revision]']").value = payload.revision;
        form.querySelector("[name='protocol_document[agents_revision]']").value = payload.agents_revision || "";
        document.querySelectorAll("form[data-protocol-delete] input").forEach(function (field) {
          if (field.name === "protocol_document[revision]") field.value = payload.revision;
          if (field.name === "protocol_document[agents_revision]") field.value = payload.agents_revision || "";
        });
        dirty = body.value !== savedBody;
        window.showFlash("Saved");
      } catch (error) {
        window.showFlash(error.message, "alert");
      } finally {
        saving = false;
        submit.disabled = false;
      }
    }

    form.addEventListener("input", markDirty);
    form.addEventListener("submit", function () { form.dataset.submitting = "true"; });
    window.setInterval(autosave, 30000);
  }

  document.addEventListener("DOMContentLoaded", function () {
    var form = document.querySelector("[data-protocol-autosave-form]");
    if (form) installProtocolAutosave(form);
    document.querySelectorAll("form[data-protocol-delete]").forEach(function (deletion) {
      deletion.addEventListener("submit", function (event) {
        if (!window.confirm("Delete this document and its reference from AGENTS?")) {
          event.preventDefault();
          return;
        }
        if (form) form.dataset.submitting = "true";
      });
    });
  });
}());
