(function() {
  function setupBoardInteractions() {
    const board = document.querySelector(".board-columns");
    if (board && board.dataset.jsBound !== "1") {
      board.dataset.jsBound = "1";
      bindBoardDragAndCardOpen(board);
    }
    bindModalLinks();
    bindTicketMarkdownEditors();
  }

  function bindBoardDragAndCardOpen(board) {
    const dropZones = document.getElementById("drag-drop-zones");
    let draggingTicketId = null;
    let pointerDown = null;
    let suppressCardClick = false;
    function startTicketDrag(card) {
      if (!card) return;
      draggingTicketId = card.dataset.ticketId || null;
      card.classList.add("dragging");
      if (dropZones && draggingTicketId) dropZones.classList.add("visible");
    }

    function finishTicketDrag() {
      board.querySelectorAll(".drag-active").forEach((el) => el.classList.remove("drag-active"));
      board.querySelectorAll(".dragging").forEach((el) => el.classList.remove("dragging"));
      if (dropZones) {
        dropZones.classList.remove("visible");
        dropZones.querySelectorAll(".drop-zone.drag-active").forEach((el) => el.classList.remove("drag-active"));
      }
      draggingTicketId = null;
      setTimeout(() => {
        suppressCardClick = false;
      }, 0);
    }

    function armCard(card) {
      if (!card) return;
      card.setAttribute("draggable", "true");
      card.style.userSelect = "none";
      card.style.webkitUserSelect = "none";
      if (card.dataset.dragBound === "1") return;
      card.dataset.dragBound = "1";
      card.addEventListener("dragstart", handleDragStart);
      card.addEventListener("dragend", finishTicketDrag);
    }

    function handleDragStart(event) {
      const card = event.currentTarget && event.currentTarget.classList && event.currentTarget.classList.contains("ticket-card")
        ? event.currentTarget
        : event.target.closest(".ticket-card");
      if (!card || !event.dataTransfer) return;
      suppressCardClick = true;
      event.dataTransfer.setData("ticket-id", card.dataset.ticketId);
      event.dataTransfer.setData("text/plain", card.dataset.ticketId);
      event.dataTransfer.effectAllowed = "move";
      try {
        event.dataTransfer.setDragImage(card, 24, 20);
      } catch (_) {}
      startTicketDrag(card);
    }

    board.querySelectorAll(".ticket-card").forEach(armCard);

    board.addEventListener("pointerdown", (event) => {
      const card = event.target.closest(".ticket-card");
      if (!card) return;
      pointerDown = { x: event.clientX, y: event.clientY };
      suppressCardClick = false;
    });

    board.addEventListener("pointermove", (event) => {
      if (!pointerDown) return;
      const dx = Math.abs(event.clientX - pointerDown.x);
      const dy = Math.abs(event.clientY - pointerDown.y);
      if (dx > 4 || dy > 4) suppressCardClick = true;
    });

    board.addEventListener("pointerup", () => {
      pointerDown = null;
    });

    board.addEventListener("dragstart", handleDragStart);

    board.addEventListener("dragend", () => {
      finishTicketDrag();
    });

    board.addEventListener("dragover", (event) => {
      const stack = event.target.closest(".ticket-stack");
      if (!stack) return;
      event.preventDefault();
      stack.classList.add("drag-active");
    });

    board.addEventListener("dragleave", (event) => {
      const stack = event.target.closest(".ticket-stack");
      if (stack) stack.classList.remove("drag-active");
    });

    board.addEventListener("drop", async (event) => {
      const stack = event.target.closest(".ticket-stack");
      if (!stack) return;
      event.preventDefault();
      stack.classList.remove("drag-active");
      const ticketId = (event.dataTransfer && (event.dataTransfer.getData("ticket-id") || event.dataTransfer.getData("text/plain"))) || draggingTicketId;
      const columnId = stack.dataset.columnId;
      if (!ticketId || !columnId) return;
      await sendTurbo("/tickets/" + ticketId + "/move", "PATCH", { column_id: columnId });
    });

    if (dropZones) {
      dropZones.querySelectorAll(".drop-zone").forEach((zone) => {
        zone.addEventListener("dragover", (event) => {
          if (!draggingTicketId) return;
          event.preventDefault();
          zone.classList.add("drag-active");
        });

        zone.addEventListener("dragleave", () => {
          zone.classList.remove("drag-active");
        });

        zone.addEventListener("drop", async (event) => {
          if (!draggingTicketId) return;
          event.preventDefault();
          zone.classList.remove("drag-active");
          const action = zone.dataset.dropAction;
          const ticketId = (event.dataTransfer && (event.dataTransfer.getData("ticket-id") || event.dataTransfer.getData("text/plain"))) || draggingTicketId;
          if (!ticketId || !action) return;

          if (action === "archive") {
            await sendTurbo("/tickets/" + ticketId + "/archive", "PATCH", {});
          } else if (action === "delete") {
            await sendTurbo("/tickets/" + ticketId, "DELETE", {});
          }
        });
      });
    }

    board.addEventListener("click", async (event) => {
      const card = event.target.closest(".ticket-card");
      if (!card) return;
      if (event.target.closest("a,button,form,input,select,textarea")) return;
      if (suppressCardClick) {
        suppressCardClick = false;
        return;
      }
      const url = card.dataset.editUrl;
      const modal = document.getElementById("modal");
      if (!url || !modal) return;
      event.preventDefault();
      await openModal(url, modal);
    });
  }

  function bindModalLinks() {
    document.querySelectorAll("a[data-turbo-frame='modal']").forEach((link) => {
      if (link.dataset.modalBound === "1") return;
      link.dataset.modalBound = "1";
      link.addEventListener("click", async (event) => {
        event.preventDefault();
        const modal = document.getElementById("modal");
        if (!modal) return;
        await openModal(link.href, modal);
      });
    });
  }

  async function openModal(url, modal) {
    const response = await fetch(url, {
      headers: {
        "Accept": "text/html",
        "X-Requested-With": "XMLHttpRequest"
      },
      credentials: "same-origin"
    });

    if (response.redirected) {
      window.location.href = response.url;
      return;
    }

    if (!response.ok) return;
    const html = await response.text();
    const doc = new DOMParser().parseFromString(html, "text/html");
    const frame = doc.querySelector("turbo-frame#modal");
    modal.innerHTML = frame ? frame.innerHTML : html;
    bindModalLinks();
    bindTicketMarkdownEditors();
  }

  function bindTicketMarkdownEditors() {
    document.querySelectorAll(".ticket-description-editor").forEach((editor) => {
      if (editor.dataset.markdownBound === "1") return;
      editor.dataset.markdownBound = "1";
      const preview = editor.querySelector(".ticket-description-preview");
      const textarea = editor.querySelector("textarea[data-markdown-editor='textarea']");
      if (!preview || !textarea) return;

      preview.addEventListener("click", () => {
        editor.classList.add("is-editing");
        textarea.focus();
      });
      preview.addEventListener("keydown", (event) => {
        if (event.key !== "Enter" && event.key !== " ") return;
        event.preventDefault();
        editor.classList.add("is-editing");
        textarea.focus();
      });

      textarea.addEventListener("blur", async () => {
        await refreshTicketMarkdownPreview(editor, textarea, preview);
      });
    });
  }

  async function refreshTicketMarkdownPreview(editor, textarea, preview) {
    const url = editor.dataset.markdownPreviewUrl;
    if (!url) return;
    const value = textarea.value || "";
    if (value.trim() === "") {
      preview.innerHTML = "";
      return;
    }

    const tokenMeta = document.querySelector("meta[name='csrf-token']");
    const headers = {
      "Content-Type": "application/json",
      "Accept": "text/html"
    };
    if (tokenMeta) headers["X-CSRF-Token"] = tokenMeta.content;

    const response = await fetch(url, {
      method: "POST",
      headers: headers,
      body: JSON.stringify({ text: value }),
      credentials: "same-origin"
    });
    if (!response.ok) return;
    preview.innerHTML = await response.text();
    editor.classList.remove("is-editing");
  }

  async function sendTurbo(url, method, body) {
    const tokenMeta = document.querySelector("meta[name='csrf-token']");
    // Without Turbo, let Rails redirect and deliver its normal flash message.
    if (!window.Turbo) {
      const form = document.createElement("form");
      form.method = "post";
      form.action = url;
      form.hidden = true;
      if (method === "DELETE") form.dataset.deleteConfirm = "Delete this ticket? This cannot be undone.";
      Object.entries({ ...body, _method: method, authenticity_token: tokenMeta?.content || "" }).forEach(([name, value]) => {
        const field = document.createElement("input");
        field.type = "hidden";
        field.name = name;
        field.value = value;
        form.append(field);
      });
      document.body.append(form);
      form.requestSubmit();
      return;
    }
    if (method === "DELETE" && !window.confirm("Delete this ticket? This cannot be undone.")) return;
    const headers = {
      "Content-Type": "application/json",
      "Accept": "text/vnd.turbo-stream.html"
    };
    if (tokenMeta) headers["X-CSRF-Token"] = tokenMeta.content;

    window.showFlash("Saving…", "pending");
    try {
      const response = await fetch(url, {
        method: method,
        headers: headers,
        body: JSON.stringify(body),
        credentials: "same-origin"
      });
      if (response.redirected) {
        window.location.href = response.url;
        return;
      }
      if (!response.ok) throw new Error("Could not save the board change.");
      const stream = await response.text();
      window.Turbo.renderStreamMessage(stream);
      setTimeout(setupBoardInteractions, 0);
      window.showFlash("Saved");
    } catch (failure) {
      window.showFlash(failure.message, "alert");
    }
  }

  document.addEventListener("turbo:load", setupBoardInteractions);
  document.addEventListener("DOMContentLoaded", setupBoardInteractions);

  document.addEventListener("click", (event) => {
    const sizeToggle = event.target.closest(".modal-size-toggle");
    if (sizeToggle) {
      const modalCard = sizeToggle.closest(".modal-card");
      if (!modalCard) return;
      const maximized = modalCard.classList.toggle("is-maximized");
      modalCard.querySelectorAll("[data-ticket-comments]").forEach((comments) => {
        comments.open = !maximized;
      });
      sizeToggle.setAttribute("aria-pressed", maximized ? "true" : "false");
      sizeToggle.setAttribute("aria-label", maximized ? "Restore modal size" : "Maximize modal");
      return;
    }

    if (event.target.closest(".modal-close") || event.target.classList.contains("modal-backdrop")) {
      const modalFrame = document.getElementById("modal");
      if (modalFrame) modalFrame.innerHTML = "";
    }
  });
})();
