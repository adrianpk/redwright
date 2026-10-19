(function () {
  function setupQuizProcessingFeedback() {
    document.querySelectorAll("[data-quiz-processing-form]").forEach(function (form) {
      if (form.dataset.quizProcessingBound === "1") return;
      form.dataset.quizProcessingBound = "1";

      form.addEventListener("submit", function () {
        var surface = form.closest("[data-quiz-processing-surface]");

        if (surface) surface.classList.add("is-processing");
      });
    });
  }

  document.addEventListener("DOMContentLoaded", setupQuizProcessingFeedback);
  window.addEventListener("pageshow", setupQuizProcessingFeedback);
}());
