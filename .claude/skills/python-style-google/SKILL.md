---
name: python-style-google
description: Use when writing, editing, or reviewing Python code. Applies the Google Python Style Guide (pyguide) — imports, line length, naming, docstrings, type annotations, mutable defaults, exceptions, strings, logging, resources, and the main guard — plus a reviewer checklist (blocking vs nit) and common bug pitfalls. Defers to the repo's configured linter/formatter on conflict.
---

# Python Style (Google Python Style Guide)

Machine-local personalization: write and review Python to the
[Google Python Style Guide](https://google.github.io/styleguide/pyguide.html).

**The repo's configured linter/formatter is the source of truth where it disagrees**
(e.g. `ruff`/`black`, or `make check-format` in the `databricks` repo). Don't hand-flag
what a tool auto-fixes.

## Author-side rules

Highest-frequency rules when writing Python:

- **Imports** (§2.2, §2.2.4, §3.13) — `import` modules/packages, not individual functions or classes; never relative imports; group and lexically sort future → stdlib → third-party → first-party.
- **Line length** (§3.2) — 80 columns max; wrap inside parentheses, never with `\`.
- **Naming** (§3.16) — `lower_with_under` for modules/functions/vars, `CapWords` for classes/exceptions, `CAPS_WITH_UNDER` for constants; no single-char names except `i`/`j`/`k` loop indices and `e` for exceptions.
- **Docstrings** (§3.8.1, §3.8.3) — one-line summary, blank line, detail; public/non-trivial functions document `Args:`, `Returns:`/`Yields:`, `Raises:`.
- **Type annotations** (§2.21, §3.19) — annotate public APIs and error-prone code; prefer `X | None` over `Optional`; spaces around `=` only when a param has both an annotation *and* a default.
- **Mutable default args** (§2.12) — never `def f(x=[])`; default to `None` and build inside.
- **Exceptions** (§2.4) — no bare `except:`, don't catch `Exception` unless re-raising; keep `try` bodies minimal.
- **Strings** (§3.10) — f-strings/`.format()`/`%` for formatting; never accumulate with `+` in a loop (use `''.join()`).
- **Logging** (§3.10.1) — pass a `%`-style template plus args (`log.info("count=%s", n)`), not an f-string, so sampling/structured logging works.
- **Resources** (§3.11) — open files/sockets in a `with` block.
- **main guard** (§3.17) — executable scripts run under `if __name__ == '__main__':`.

## Reviewer checklist (blocking vs nit)

When reviewing (or self-reviewing) Python, scan against pyguide. Classify each as
blocking vs nit as noted:

- **Mutable default args** (§2.12) — no `[]`/`{}` defaults; expect `None` + init inside. *Blocking* — real bug source.
- **Broad exceptions** (§2.4) — no bare `except:` or catching `Exception` without re-raising; minimal `try` bodies. *Blocking* when it can swallow errors.
- **None / truthiness** (§2.14) — `if x is None:` for None checks, implicit false (`if not seq:`) elsewhere; no `== None` or `== True/False`. *Blocking* when `0`/`""`/`[]` could be conflated with missing.
- **Imports** (§2.2, §2.2.4, §3.13) — modules/packages imported (not individual symbols), no relative imports, grouped and lexically sorted. Nit.
- **Naming** (§3.16) — `lower_with_under` / `CapWords` / `CAPS_WITH_UNDER`; no cryptic single-char names. Nit.
- **Docstrings** (§3.8.1, §3.8.3) — public/non-trivial functions have a summary plus `Args:`/`Returns:`/`Raises:`. Nit.
- **Type annotations** (§2.21, §3.19) — public APIs annotated; `X | None` preferred; spaces around `=` only when annotated-with-default. Nit.
- **Logging** (§3.10.1) — `%`-style template + args (`log.info("x=%s", x)`), not f-strings, so sampling/structured logging works. Nit.
- **Resources** (§3.11) — files/sockets opened via `with`. *Blocking* under load (leaked handles).
- **TODOs** (§3.12) — `# TODO: <ticket/link> - description`, not a bare `# TODO`. Nit.
- **main guard** (§3.17) — scripts guarded by `if __name__ == '__main__':`. Nit.

## Bug pitfalls mapped to failure modes

Several pyguide rules exist precisely because violating them produces bugs. Enforcing
them with linting/type-checking is the cheapest prevention — it turns an "unknown
unknown" into a caught lint error before review.

| Pitfall (rule) | Bug type it causes | Prevention |
|----------------|--------------------|------------|
| Mutable default arg, `def f(x=[])` (§2.12) | Oversight — state leaks across calls | Default `None`, init inside |
| Bare `except:` / catch-all `Exception` (§2.4) | Oversight / Data Assumption — hides real errors | Catch specific types; re-raise or isolate |
| `== None` or truthiness on maybe-empty data (§2.14) | Edge Case — `0`/`""`/`[]` conflated with missing | `if x is None:` for None; implicit false only when empty is equivalent |
| Missing/ignored type annotations (§2.21) | Oversight — interface change breaks callers | Annotate public APIs; run the type checker |
| File/socket without `with` (§3.11) | Load / External Dep — leaked handles under volume | Always `with` or `contextlib.closing()` |
| Mutable global state (§2.5) | Oversight / Load — hidden coupling, races | Module constants (`CAPS_WITH_UNDER`); `_`-prefix internal mutables |
