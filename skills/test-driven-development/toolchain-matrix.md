# Toolchain matrix — best-practice defaults per language (2025–2026)

Look up the row for the stack you're building in. These are the widely-adopted,
actively-maintained defaults a coding/QA agent should use unless the project
already has an established (non-legacy) choice. Pair with the stage policy in
`SKILL.md` ("Toolchain & pipeline — which tools, which stage").

Sources: verified via multi-source research (Vitest docs & State of JS 2025;
BrowserStack Playwright-vs-Cypress; Ruff FAQ/Astral; JUnit 6.0 GA + Spring Boot 4;
Stryker & Pact docs; modern-java-practices; OWASP). Re-check yearly — tooling moves.

## Master matrix

| Concern | Java | TypeScript (Node) | React | Python |
|---|---|---|---|---|
| **Unit / integration** | JUnit 6 *(JUnit 5 for existing; **JUnit 4 = legacy**)* + AssertJ + Mockito 5 + **Testcontainers** | **Vitest** *(**Jest = legacy**, keep for React-Native)* + Supertest + Testcontainers | **Vitest** + React Testing Library | **pytest** (+ fixtures, httpx) + Testcontainers-python |
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

Cross-stack engines: **Semgrep** and **CodeQL** cover most languages; **Trivy** covers deps + containers + IaC; **Dependabot** is the GitHub-native SCA default. Container/IaC: Trivy, Checkov, hadolint. Reference standard for the security review: **OWASP Top-10 + OWASP ASVS**.

## "Tell the agent" one-liners

- **Java:** JUnit 6 + AssertJ + Mockito 5 + Testcontainers; Playwright for E2E; Spotless + Checkstyle/PMD/SpotBugs; Find Security Bugs + CodeQL + OWASP Dependency-Check. *(JUnit 6 needs Java 17+; it's the Spring Boot 4 default. Use JUnit 5 if the project is Java 8–16.)*
- **TypeScript (Node):** Vitest (+ Supertest) + Testcontainers; Playwright for E2E; Biome (or ESLint+Prettier); tsc; Semgrep/CodeQL + Dependabot + gitleaks.
- **React:** Vitest + React Testing Library for component/unit; Playwright for E2E; same lint/type/security as TS.
- **Python:** pytest (+ Hypothesis for invariants) + Testcontainers-python; Playwright(Python) for E2E; **Ruff** (lint+format) + mypy/pyright; Bandit + Semgrep + pip-audit + gitleaks.

## Standard test types (what to run, all stacks)

- **Unit** — pure logic, no I/O. The base of the pyramid.
- **Integration** — real dependencies (DB, queue) via **Testcontainers** (or equivalent). Not mocks.
- **Component / UI** (frontend) — React Testing Library under Vitest.
- **E2E** — critical user paths via **Playwright** (default over Cypress: 3-browser incl. WebKit, free parallelism, multi-tab/context, ~5× Cypress's downloads).
- **Contract** — **Pact**, consumer-driven, for multi-service boundaries; gate deploys with `can-i-deploy`.
- **Property-based** — invariants across generated inputs (fast-check / Hypothesis / jqwik).
- **Mutation** — validates the *suite's* effectiveness; run tiered (changed-files on PR via `--since`, full sweep on a weekly cron), not on every commit.

## Coverage

Coverage is an **outcome, not a target** — chasing a % breeds assertion-free tests. A common floor is ~80% line/branch, but treat it as a smell detector (what's *untested*), never a goal to game. The lean, behavioral, AC-traceable suite (see `SKILL.md`) is what produces good coverage.

## Legacy / deprecation flags

- **Jest** → not deprecated (Jest 30, huge install base) but **Vitest is the default for new JS/TS/React**; keep Jest for React-Native or existing Jest suites.
- **JUnit 4** → legacy; **JUnit 5/6** for new work.
- **flake8 + black + isort** → superseded by **Ruff** (one tool, ~10–100× faster).
- **Cypress** → still GA/maintained (strong component testing, local debugging) but **Playwright is the default E2E recommendation** for cross-browser + CI scale.
- **Biome vs ESLint+Prettier** → genuinely a toss-up; Biome = one fast tool with auto-migration; ESLint+Prettier = larger plugin ecosystem. Either is an acceptable default.
