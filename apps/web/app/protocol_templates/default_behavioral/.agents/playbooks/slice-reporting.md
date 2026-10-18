# Slice Reporting

Use this playbook for every formal implementation slice.
`.agents/REPORTING.md` owns the report requirement, canonical location,
metadata, sections, and content rules.

## Timing

1. Create or update the report while implementation context is current.
2. Set its status to `reviewing` before opening the pull request.
3. Include the report path in the pull-request `Changes` section.
4. After merge, set its status to `delivered`, record the pull-request number,
   and close the tracker state on `dev`.
