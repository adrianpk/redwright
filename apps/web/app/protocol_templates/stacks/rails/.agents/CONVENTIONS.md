# Rails Conventions

- Use routing, resource naming, Active Record relations, and framework helpers
  consistently with the installed Rails version.
- Permit request parameters deliberately and authorize the resource being used.
  Keep user-controlled values out of interpolated SQL and HTML.
- Keep queries composable. Load associations deliberately to avoid N+1 queries,
  and use batching for large datasets instead of loading all records at once.
- Choose bang persistence methods when failure must stop the operation; otherwise
  inspect the result and render validation errors clearly.
- Remember that application uniqueness validation alone does not prevent races;
  use a matching unique constraint when uniqueness is an invariant.
- Keep secrets in the configured credentials or environment mechanism.
- Return consistent HTTP responses and use Rails flash feedback for navigation.

Reference: [Active Record validations](https://guides.rubyonrails.org/active_record_validations.html).
