# Angular Architecture

This document describes Angular repository structure and feature boundaries.

- Group components, templates, styles, and tests by feature. Follow the installed
  Angular version's standalone or NgModule conventions.
- Keep components responsible for presentation and interaction. Put reusable
  data access and orchestration in injectable services with explicit ownership.
- Provide services at the narrowest scope that matches their lifetime; do not
  make every service application-global by default.
- Model navigation with the router and load feature routes lazily when useful.
- Use signals for synchronous reactive state and RxJS for streams as appropriate
  to the existing application. Derive state instead of storing duplicate copies.
- Use shared UI code only for actual reuse; avoid broad `core` or `shared`
  directories that become unrelated collections.

Reference: [Angular style guide](https://angular.dev/style-guide).
