(function() {
  function setupBoardInteractions() {
    const board = document.querySelector(".board-columns");
    if (board && board.dataset.jsBound !== "1") {
      board.dataset.jsBound = "1";
      bindBoardDragAndCardOpen(board);
    }
    bindModalLinks();
    bindTicketMarkdownEditors();
    bindTicketDocumentPickers();
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
    bindTicketMarkdownEditors();
    bindTicketDocumentPickers();
  }

  function bindTicketDocumentPickers() {
    document.querySelectorAll("[data-ticket-document-picker]").forEach((picker) => {
      if (picker.dataset.documentPickerBound === "1") return;
      picker.dataset.documentPickerBound = "1";
      const input = picker.querySelector("[data-ticket-document-search]");
      const addButton = picker.querySelector("[data-ticket-document-add]");
      const results = picker.querySelector("[data-ticket-document-results]");
      const chips = picker.querySelector("[data-ticket-document-chips]");
      if (!input || !addButton || !results || !chips) return;

      addButton.addEventListener("click", () => {
        addTicketDocumentChip(picker, input, chips);
      });
      input.addEventListener("input", () => {
        renderTicketDocumentResults(picker, input, results);
      });
      input.addEventListener("focus", () => {
        renderTicketDocumentResults(picker, input, results);
      });
      input.addEventListener("keydown", (event) => {
        if (event.key !== "Enter") return;
        event.preventDefault();
        addTicketDocumentChip(picker, input, chips);
      });
      results.addEventListener("click", (event) => {
        const option = event.target.closest("[data-ticket-document-result]");
        if (!option) return;
        input.value = option.dataset.ticketDocumentValue || "";
        addTicketDocumentChip(picker, input, chips);
        results.innerHTML = "";
      });
      chips.addEventListener("click", (event) => {
        const remove = event.target.closest("[data-ticket-document-remove]");
        if (!remove) return;
        const chip = remove.closest(".ticket-document-chip");
        if (chip) chip.remove();
      });
    });
  }

  function renderTicketDocumentResults(picker, input, results) {
    const query = input.value.trim().toLowerCase();
    if (query.length < 1) {
      results.innerHTML = "";
      return;
    }
    const attachedIds = new Set(Array.from(picker.querySelectorAll(".ticket-document-chip")).map((chip) => {
      return chip.dataset.documentId;
    }));
    const matches = Array.from(picker.querySelectorAll("datalist option"))
      .filter((option) => option.value.toLowerCase().includes(query))
      .filter((option) => !attachedIds.has(option.dataset.documentId))
      .slice(0, 6);

    if (matches.length === 0) {
      results.innerHTML = "<div class=\"ticket-document-result-empty\">No matching documents</div>";
      return;
    }

    results.innerHTML = matches.map((option) => {
      return [
        "<button type=\"button\" class=\"ticket-document-result\" data-ticket-document-result data-ticket-document-value=\"",
        escapeHtml(option.value),
        "\">",
        escapeHtml(option.value),
        "</button>"
      ].join("");
    }).join("");
  }

  function addTicketDocumentChip(picker, input, chips) {
    const option = Array.from(picker.querySelectorAll("datalist option")).find((candidate) => {
      return candidate.value === input.value;
    });
    if (!option || !option.dataset.documentId) return;
    const documentId = option.dataset.documentId;
    if (chips.querySelector("[data-document-id='" + CSS.escape(documentId) + "']")) {
      input.value = "";
      return;
    }

    const chip = document.createElement("span");
    chip.className = "ticket-document-chip";
    chip.dataset.documentId = documentId;
    chip.innerHTML = [
      "<input type=\"hidden\" name=\"ticket[document_ids][]\" value=\"" + escapeHtml(documentId) + "\">",
      "<span>" + escapeHtml(option.value) + "</span>",
      "<button type=\"button\" aria-label=\"Remove " + escapeHtml(option.value) + "\" data-ticket-document-remove>&times;</button>"
    ].join("");
    chips.appendChild(chip);
    input.value = "";
    const results = picker.querySelector("[data-ticket-document-results]");
    if (results) results.innerHTML = "";
  }

  function escapeHtml(value) {
    return String(value).replace(/[&<>"']/g, (char) => {
      return {
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        "\"": "&quot;",
        "'": "&#39;"
      }[char];
    });
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
    const headers = {
      "Content-Type": "application/json",
      "Accept": "text/vnd.turbo-stream.html"
    };
    if (tokenMeta) headers["X-CSRF-Token"] = tokenMeta.content;

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
    if (!response.ok) return;
    const stream = await response.text();
    if (window.Turbo && stream) {
      window.Turbo.renderStreamMessage(stream);
      setTimeout(setupBoardInteractions, 0);
    } else {
      window.location.reload();
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
