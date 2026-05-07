(function () {
  function setupQuizProcessingFeedback() {
    document.querySelectorAll("[data-quiz-processing-form]").forEach(function (form) {
      if (form.dataset.quizProcessingBound === "1") return;
      form.dataset.quizProcessingBound = "1";

      form.addEventListener("submit", function () {
        var targetId = form.dataset.quizProcessingTarget;
        var feedback = targetId ? document.getElementById(targetId) : null;
        var surface = form.closest("[data-quiz-processing-surface]");

        if (feedback) feedback.hidden = false;

        if (surface) surface.classList.add("is-processing");
      });
    });
  }

  document.addEventListener("DOMContentLoaded", setupQuizProcessingFeedback);
  window.addEventListener("pageshow", setupQuizProcessingFeedback);
}());
