# Work Modes

Use this playbook when work may cross a mode boundary. `.agents/ROUTING.md`
owns mode classification and authorization. `.agents/LIFECYCLE.md` owns work
state and completion.

## Procedure

1. Classify the current request under `.agents/ROUTING.md`.
2. Identify the current authorized mode and any explicitly authorized
   transition.
3. For planning, define scope, exclusions, validation, delivery mode, and
   whether formal slices are required. Use `.agents/DOCUMENTING.md` for any
   authorized persistent artifact.
4. For implementation, select the smallest applicable delivery playbook and
   verify its entry conditions.
5. During a technical pause, report current scope, state, validation, and
   blockers without changing the authorized mode.
6. Close the work through `.agents/LIFECYCLE.md` and the selected delivery
   playbook.
