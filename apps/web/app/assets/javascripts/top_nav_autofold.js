(function() {
  const AUTO_FOLD_DELAY_MS = 1000;
  const PROXIMITY_PX = 18;
  const PIN_KEY = "rw.top_nav.pinned";

  function setupTopNavAutofold() {
    const nav = document.querySelector(".top-nav");
    if (!nav) return;
    if (nav.dataset.autofoldBound === "1") return;
    nav.dataset.autofoldBound = "1";

    const handle = nav.querySelector(".top-nav-handle");
    const pinButton = nav.querySelector(".top-nav-pin");
    let isCollapsed = false;
    let isPinned = sessionStorage.getItem(PIN_KEY) === "1";
    let isHoveringNav = false;
    let autoFoldTimer = null;

    function hasOpenMenu() {
      return Boolean(nav.querySelector(".top-nav-project-menu[open], .top-nav-user-menu[open]"));
    }

    function setCollapsed(nextCollapsed) {
      if (isPinned) nextCollapsed = false;
      if (hasOpenMenu()) nextCollapsed = false;
      isCollapsed = nextCollapsed;
      nav.dataset.navState = nextCollapsed ? "collapsed" : "expanded";
      if (handle) handle.setAttribute("aria-expanded", nextCollapsed ? "false" : "true");
    }

    function setPinned(nextPinned) {
      isPinned = nextPinned;
      sessionStorage.setItem(PIN_KEY, nextPinned ? "1" : "0");
      if (pinButton) pinButton.setAttribute("aria-pressed", nextPinned ? "true" : "false");
      if (nextPinned) {
        if (autoFoldTimer) window.clearTimeout(autoFoldTimer);
        setCollapsed(false);
      } else {
        scheduleAutoFold();
      }
    }

    function scheduleAutoFold() {
      if (isPinned) return;
      if (autoFoldTimer) window.clearTimeout(autoFoldTimer);
      autoFoldTimer = window.setTimeout(() => {
        if (isPinned || isHoveringNav || hasOpenMenu()) return;
        setCollapsed(true);
      }, AUTO_FOLD_DELAY_MS);
    }

    function unfold() {
      setCollapsed(false);
      scheduleAutoFold();
    }

    function fold() {
      if (isPinned) return;
      if (autoFoldTimer) window.clearTimeout(autoFoldTimer);
      setCollapsed(true);
    }

    nav.addEventListener("mouseenter", () => {
      isHoveringNav = true;
      unfold();
    });
    nav.addEventListener("mouseleave", () => {
      isHoveringNav = false;
      if (!isCollapsed) scheduleAutoFold();
    });

    if (handle) {
      handle.addEventListener("click", () => {
        if (isCollapsed) unfold();
        else fold();
      });
    }

    if (pinButton) {
      pinButton.addEventListener("click", () => {
        setPinned(!isPinned);
      });
    }

    nav.querySelectorAll(".top-nav-project-menu, .top-nav-user-menu").forEach((menu) => {
      menu.addEventListener("toggle", () => {
        if (menu.open) {
          setCollapsed(false);
        } else if (!isHoveringNav) {
          scheduleAutoFold();
        }
      });
    });

    document.addEventListener("mousemove", (event) => {
      if (event.clientY <= PROXIMITY_PX && isCollapsed && !isPinned) unfold();
    });

    if (pinButton) pinButton.setAttribute("aria-pressed", isPinned ? "true" : "false");
    setCollapsed(false);
    if (!isPinned) scheduleAutoFold();
  }

  document.addEventListener("turbo:load", setupTopNavAutofold);
  document.addEventListener("DOMContentLoaded", setupTopNavAutofold);
})();
