# Quiz Procedure

Use this playbook for an authorized structured quiz. `.agents/DISCOVERY.md`
owns the quiz protocol and artifact contract.

1. Establish the quiz topic and sufficient-understanding criterion.
2. Prepare a finite candidate question set grouped by topic, within the limits
   defined by `.agents/DISCOVERY.md`.
3. Initialize the question count, remaining budget, active topic, follow-up
   depth, and coverage state.
4. Ask one question and wait for the answer.
5. After each answer, choose the next planned question, a permitted follow-up,
   a topic change, or termination according to information gain.
6. Maintain `files/raw.md` during a long session, preserving enough context to
   recover the user's meaning.
7. Stop at the first termination condition defined by
   `.agents/DISCOVERY.md`.
8. Curate the findings into `artifact.md`; do not reproduce the conversation
   as a transcript.
9. Report the bundle path, covered topics, settled decisions, open questions,
   and any separately authorized next artifact.
