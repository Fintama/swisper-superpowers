# Toolchain matrix — best-practice defaults per language (2025–2026)

Look up the row for the stack you're building in. These are the widely-adopted,
actively-maintained defaults; use them unless the project already has an
established, non-legacy choice. The stage policy (which stage runs what) is
below the matrix. Tooling moves: re-check the rows yearly.

## Master matrix

| Concern | Java | TypeScript (Node) | React | Python |
|---|---|---|---|---|
| **Unit / integration** | JUnit 6 *(JUnit 5 for existing; **JUnit 4 = legacy**)* + AssertJ + Mockito 5 + **Testcontainers** | **Vitest** *(Jest for existing suites and React-Native)* + Supertest + Testcontainers | **Vitest** + React Testing Library | **pytest** (+ fixtures, httpx) + Testcontainers-python |
| **End-to-end** | **Playwright** | **Playwright** | **Playwright** *(Cypress = conditional: quick setup / component-test maturity)* | **Playwright** (Python) |
| **Contract** | **Pact** (V4 = HTTP + async) | Pact | — | Pact |
| **Property-based** | jqwik | **fast-check** | fast-check | **Hypothesis** |
| **Mutation** *(nightly)* | PIT / Pitest | **StrykerJS** | StrykerJS | mutmut |
| **Coverage** | JaCoCo | Vitest (v8 / istanbul) | Vitest | coverage.py + pytest-cov |
| **Lint + format** | Spotless + google-java-format; Checkstyle + PMD + Modernizer | **Biome** *or* ESLint + Prettier | Biome *or* ESLint + Prettier | **Ruff** *(replaces flake8 + black + isort)* |
| **Type-check** | javac | **tsc** `--noEmit` | tsc | **mypy** *or* **pyright** |
| **SAST** | Find Security Bugs (SpotBugs) + **CodeQL** | **Semgrep** and/or **CodeQL** | Semgrep / CodeQL + eslint-plugin-security | **Bandit** + Semgrep / CodeQL |
| **Dependency scan (SCA)** | OWASP Dependency-Check | **Dependabot** / OSV-Scanner / Trivy / `npm audit` | (same as TS) | **pip-audit** / Dependabot / OSV |
| **Secrets** | **gitleaks** (or trufflehog) | gitleaks | gitleaks | gitleaks |

Notes: JUnit 6 needs Java 17+ (the Spring Boot 4 default); use JUnit 5 on Java 8–16. Jest is not deprecated (Jest 30), but Vitest is the default for new JS/TS/React work. Cypress is still maintained (strong component testing, local debugging); Playwright is the default for cross-browser and CI scale. Biome vs ESLint + Prettier is a toss-up: Biome is one fast tool with auto-migration, ESLint + Prettier has the larger plugin ecosystem.

Cross-stack engines: **Semgrep** and **CodeQL** cover most languages; **Trivy** covers deps + containers + IaC; **Dependabot** is the GitHub-native SCA default. Container/IaC: Trivy, Checkov, hadolint. Reference standard for the security review: **OWASP Top-10 + OWASP ASVS**.

## Standard test types (what to run, all stacks)

Which of these a test uses is decided by `SKILL.md` R1–R4: **the boundary first**
(route/API response, rendered UI, persisted state), a lower level only when the
boundary cannot reach the case. This list is the toolbox, not a quota.

- **E2E / browser** — business ACs with a UI, front to back, via **Playwright** (default over Cypress: 3-browser incl. WebKit, free parallelism, multi-tab/context).
- **Integration (route / service boundary)** — the default home of an AC test; real dependencies (DB, queue) via **Testcontainers** (or equivalent). Not mocks.
- **Component / UI** (frontend) — React Testing Library under Vitest, for a UI rule the browser test cannot reach cheaply; never as the proof of a B-AC.
- **Unit** — only the R3 exceptions: one table-driven or property test of a pure core, an invariant, a hard-to-reach failure mode.
- **Accessibility** — `axe-playwright` / `@axe-core/react` inside the browser test, not a separate suite.
- **Visual regression** — `toHaveScreenshot()` / Chromatic, sparingly; flake-prone unless deterministic.
- **Performance NFRs** — a benchmark compared to a committed baseline (a regression check, not an assertion).
- **Contract** — **Pact**, consumer-driven, for multi-service boundaries; gate deploys with `can-i-deploy`.
- **Property-based** — invariants across generated inputs (fast-check / Hypothesis / jqwik).
- **Mutation** — validates the *suite's* effectiveness; run tiered (changed-files on PR via `--since`, full sweep on a weekly cron), not on every commit. Always for invariant-critical code (security boundaries, billing, FSM transitions); skip for CRUD glue — it returns noise there. A survivor is answered by **strengthening** the test that claims the behaviour (`SKILL.md` R6), not by a new test.

## Contract tests — across the consumer boundary

A contract a PR produces is exercised by a **consumer** (or a fixture acting as one), not only the producer's own test.

- **Type-driven** — the consumer imports the producer's type and uses it where a shape change fails compilation. Strong in a monorepo.
- **Fixture-based** — the producer tests against a frozen example payload. Cheap; enough when the consumer is in the same repo.
- **Pact** — consumer-driven, verified in the producer's CI; for cross-repo or cross-team boundaries. Gate deploys with `can-i-deploy`.

## Which stage runs what

Each stage is a strictly cheaper filter than the next; a check runs as early as it can.

| Stage | Blocks? | Runs (cheapest-first) |
|---|---|---|
| **TDD inner loop** | no | format-on-save · lint the changed file · incremental type-check · the test you are writing + core smoke |
| **Pre-commit** | local | format `--write` · lint changed · **secrets scan** · type-check |
| **Task gate** — PR to the integration branch | **yes** | format `--check` → lint → type-check → secrets → SAST *on the diff* → dep-scan *if deps changed* → **`trace-check.sh`** → the gate test tier |
| **Feature gate** — PR to main/release | **yes** | all of the above + extended tests + full SAST + full dependency audit + human feature & security review |
| **Nightly** (on main) | no | full E2E matrix · mutation sweep · random-order run · full audits |
| **Deploy** | **yes** | green CI + contract gate where contracts exist |

**Two-gate rule:** the task gate is cheap and diff-scoped (it runs often); the feature gate is expensive and whole-feature (it runs once, last before prod) — the full security review and the extended tests land there, not on every task.

**Security review** (SAST + SCA + secrets against OWASP Top-10 / ASVS) sits alongside tests, weighted to the feature gate.

**Rolling onto an existing codebase:** baseline, then ratchet — format-write once, lint warn-only, SAST diff-aware (gate only *new* findings), tighten over time. `trace-check.sh` is already diff-scoped: it reads new tests only.

## Coverage

Coverage is an outcome, not a target (`SKILL.md`). A common floor is ~80% line/branch; treat it as a smell detector for what is untested.
