# Software Engineering Best Practices

A living reference for writing clean, maintainable, and reliable software.

---

## Table of Contents

1. [Code Quality & Readability](#1-code-quality--readability)
2. [Testing](#2-testing)
3. [Code Reuse & Modularity](#3-code-reuse--modularity)
4. [Version Control](#4-version-control)
5. [Error Handling & Logging](#5-error-handling--logging)
6. [Security](#6-security)
7. [Performance](#7-performance)
8. [Documentation](#8-documentation)
9. [Code Review](#9-code-review)
10. [Architecture & Design Principles](#10-architecture--design-principles)

---

## 1. Code Quality & Readability

> "Any fool can write code that a computer can understand. Good programmers write code that humans can understand." — Martin Fowler

### Naming Conventions
- Use **descriptive, intention-revealing names** for variables, functions, and classes.
- Avoid abbreviations unless universally understood (`id`, `url`, `http`).
- Be consistent with casing conventions in your language (`camelCase`, `snake_case`, `PascalCase`).

```js
// ❌ Bad
const d = new Date();
function calc(a, b) { return a * b * 0.1; }

// ✅ Good
const currentDate = new Date();
function calculateTax(price, quantity) { return price * quantity * TAX_RATE; }
```

### Function Design
- A function should **do one thing only** (Single Responsibility Principle).
- Keep functions **short** — if it doesn't fit on a screen, consider splitting it.
- Prefer **fewer parameters** (ideally ≤ 3); group related params into an object if needed.
- Avoid side effects where possible; prefer **pure functions**.

### Avoid Magic Numbers & Strings
```js
// ❌ Bad
if (user.role === 3) { ... }

// ✅ Good
const ROLE_ADMIN = 3;
if (user.role === ROLE_ADMIN) { ... }
```

### Keep Code DRY (Don't Repeat Yourself)
- Duplicate logic is a maintenance hazard. Extract shared logic into reusable functions or modules.
- Exception: premature abstraction can be worse than duplication — wait until you see a pattern repeat **at least twice**.

---

## 2. Testing

> "Code without tests is broken by design." — Jacob Kaplan-Moss

### Testing Pyramid

```
        /\
       /E2E\         ← Few, slow, high confidence (UI/integration tests)
      /------\
     /Integr. \      ← Some, moderate speed (API, DB, service tests)
    /----------\
   /  Unit Tests \   ← Many, fast, isolated (functions, classes)
  /--------------\
```

### Unit Tests
- Test **one unit of logic** in isolation.
- Mock external dependencies (DB, APIs, filesystem).
- Follow the **AAA pattern**: Arrange → Act → Assert.
- Aim for **fast execution** (milliseconds per test).

```python
# Example (Python/pytest)
def test_calculate_tax_returns_correct_amount():
    # Arrange
    price, quantity, expected = 100, 2, 20.0

    # Act
    result = calculate_tax(price, quantity)

    # Assert
    assert result == expected
```

### Integration Tests
- Test how multiple components work **together** (e.g., service + database).
- Use real or containerized dependencies where practical (e.g., Docker for Postgres).

### End-to-End (E2E) Tests
- Simulate real user flows through the full stack.
- Use tools like Playwright, Cypress, or Selenium.
- Keep these **few and focused** on critical paths (login, checkout, etc.).

### Test Best Practices
- ✅ Write tests **before fixing bugs** (regression tests).
- ✅ Aim for **meaningful coverage**, not 100% coverage for its own sake.
- ✅ Tests should be **deterministic** — no random data, no time-sensitive logic without mocking.
- ✅ Name tests clearly: `it("should return 401 when token is expired")`.
- ❌ Don't test implementation details — test **behavior**.
- ❌ Don't skip flaky tests — fix or delete them.

### Code Coverage
- Use coverage tools (`jest --coverage`, `pytest-cov`, `Istanbul`) to find untested paths.
- Coverage is a **signal, not a goal** — 80% meaningful coverage > 100% superficial coverage.

---

## 3. Code Reuse & Modularity

### Principles
- **DRY**: Extract repeated logic into shared utilities or modules.
- **YAGNI** (You Aren't Gonna Need It): Don't build abstractions for hypothetical future needs.
- **High cohesion, low coupling**: Modules should do one thing well and depend on as little as possible.

### How to Structure Reusable Code

| Type | When to Use | Example |
|------|-------------|---------|
| Utility function | Stateless logic used in multiple places | `formatDate()`, `slugify()` |
| Custom hook (React) | Stateful logic reused across components | `useAuth()`, `usePagination()` |
| Service/class | Business logic that encapsulates state or deps | `UserService`, `PaymentGateway` |
| Shared component | UI elements used across features | `<Button>`, `<Modal>`, `<Table>` |
| Library/package | Logic shared across multiple projects | Internal npm/PyPI packages |

### Dependency Management
- Prefer **small, focused dependencies** over large monolithic ones.
- Regularly audit and update packages (`npm audit`, `pip list --outdated`).
- Pin versions in production; use ranges carefully.

---

## 4. Version Control

### Commit Messages
Follow the **Conventional Commits** format:
```
<type>(scope): short description

[optional body]
[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

```
feat(auth): add JWT refresh token support
fix(cart): prevent duplicate item addition
docs(readme): update local setup instructions
```

### Branching Strategy
Use a consistent branching model, e.g. **Git Flow** or **trunk-based development**:

```
main          ← stable, production-ready
  └─ develop  ← integration branch
       └─ feature/user-auth
       └─ fix/login-redirect
       └─ chore/upgrade-dependencies
```

### Golden Rules
- ✅ **Commit early and often** — small, focused commits.
- ✅ **Never commit secrets** — use `.gitignore` and environment variables.
- ✅ **Use pull/merge requests** for all changes to main branches.
- ❌ Never force-push to shared branches.
- ❌ Don't commit commented-out code — use version history instead.

---

## 5. Error Handling & Logging

### Error Handling
- **Never silently swallow errors** — at minimum, log them.
- Distinguish between **expected errors** (user input, 404s) and **unexpected errors** (bugs, crashes).
- Return meaningful error messages to clients; never expose stack traces in production.

```js
// ❌ Bad
try {
  await saveUser(data);
} catch (e) {}  // Silent failure

// ✅ Good
try {
  await saveUser(data);
} catch (error) {
  logger.error('Failed to save user', { userId: data.id, error });
  throw new AppError('Could not save user. Please try again.', 500);
}
```

### Logging Best Practices
- Use **structured logging** (JSON) for machine-readable logs.
- Include **context**: user ID, request ID, timestamps.
- Use appropriate **log levels**: `DEBUG`, `INFO`, `WARN`, `ERROR`.
- Don't log sensitive data (passwords, tokens, PII).

```json
{
  "level": "error",
  "message": "Payment failed",
  "userId": "usr_123",
  "orderId": "ord_456",
  "timestamp": "2025-03-07T10:22:00Z"
}
```

---

## 6. Security

### Core Principles
- **Validate all input** — never trust data from users, APIs, or external systems.
- **Principle of Least Privilege** — services and users should only have the access they need.
- **Defense in depth** — layer multiple security controls.

### Common Vulnerabilities to Prevent

| Vulnerability | Prevention |
|---------------|------------|
| SQL Injection | Use parameterized queries / ORMs |
| XSS | Sanitize output; use Content Security Policy |
| CSRF | Use CSRF tokens or SameSite cookies |
| Broken Auth | Use proven auth libraries; enforce MFA |
| Sensitive Data Exposure | Encrypt at rest and in transit (HTTPS/TLS) |
| Insecure Dependencies | Run `npm audit` / `pip-audit` regularly |

### Secrets Management
- ✅ Use `.env` files locally; never commit them.
- ✅ Use secret managers in production (AWS Secrets Manager, Vault, etc.).
- ✅ Rotate secrets regularly.
- ❌ Never hardcode credentials in source code.

---

## 7. Performance

### Measure Before Optimizing
> "Premature optimization is the root of all evil." — Donald Knuth

- Profile first — find the actual bottleneck.
- Optimize **hot paths** (code that runs frequently), not edge cases.

### Common Optimizations

| Area | Technique |
|------|-----------|
| Database | Add indexes; avoid N+1 queries; paginate results |
| API | Cache responses (Redis, CDN); batch requests |
| Frontend | Lazy load; code split; compress assets |
| Computation | Use efficient data structures; memoize expensive calls |
| Concurrency | Use async/await, worker threads, or queues for I/O-bound work |

### Key Metrics to Track
- **Response time / latency** (p50, p95, p99)
- **Throughput** (requests per second)
- **Error rate**
- **Memory and CPU utilization**

---

## 8. Documentation

### What to Document
- **Why**, not just **what** — code shows what; comments explain why.
- Public APIs and interfaces.
- Complex algorithms and non-obvious decisions.
- Setup and deployment steps.

### README Essentials
Every project should have a `README.md` with:
- [ ] Project purpose (1–2 sentences)
- [ ] Prerequisites and setup instructions
- [ ] How to run tests
- [ ] How to deploy / release
- [ ] Links to further docs (architecture, API docs, runbooks)

### Code Comments
```js
// ❌ Redundant — the code says this already
// Increment i by 1
i++;

// ✅ Useful — explains a non-obvious decision
// We delay retry by 1s to avoid thundering herd on DB reconnect
await sleep(1000);
```

### API Documentation
- Use tools like **Swagger/OpenAPI**, **Postman**, or **Storybook** (for UI components).
- Document request/response shapes, error codes, and auth requirements.

---

## 9. Code Review

### As an Author
- Keep PRs **small and focused** — one concern per PR.
- Write a clear **PR description**: what changed, why, and how to test it.
- Self-review before requesting review.
- Respond promptly to feedback.

### As a Reviewer
- Review for **correctness, readability, security, and test coverage**.
- Be **specific and constructive** — suggest, don't just criticize.
- Distinguish between blocking issues and suggestions (`nit:` prefix for minor style notes).
- Approve when the code is **good enough**, not perfect.

### PR Checklist
- [ ] Does it solve the stated problem?
- [ ] Are edge cases handled?
- [ ] Are there tests?
- [ ] Are there any security concerns?
- [ ] Is it understandable to someone unfamiliar with the code?

---

## 10. Architecture & Design Principles

### SOLID Principles (OOP)
| Principle | Meaning |
|-----------|---------|
| **S**ingle Responsibility | A class/module should have one reason to change |
| **O**pen/Closed | Open for extension, closed for modification |
| **L**iskov Substitution | Subtypes must be substitutable for their base types |
| **I**nterface Segregation | Prefer small, specific interfaces over large general ones |
| **D**ependency Inversion | Depend on abstractions, not concretions |

### Common Patterns
- **Repository Pattern** — abstract data access behind an interface.
- **Service Layer** — isolate business logic from controllers/routes.
- **Dependency Injection** — pass dependencies in rather than hardcoding them.
- **CQRS** — separate read and write models for complex domains.
- **Event-Driven Architecture** — decouple components via events/queues.

### 12-Factor App Principles (for cloud-native apps)
Key factors: config in environment, stateless processes, dev/prod parity, treat logs as streams. See [12factor.net](https://12factor.net) for the full guide.

---

## Quick Reference Card

| Practice | Rule of Thumb |
|----------|---------------|
| Function length | ≤ 20–30 lines |
| PR size | ≤ 400 lines changed |
| Test coverage | Aim for 70–80% meaningful coverage |
| Commit frequency | At least once per logical unit of work |
| Code review turnaround | Within 1 business day |
| Secrets | Never in source code. Ever. |
| Comments | Explain *why*, not *what* |
| Dependencies | Audit monthly; update quarterly |

---

*Last updated: March 2025 · Maintained by your engineering team*
