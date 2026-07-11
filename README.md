# Rails Starter

A Rails starter built for AI-assisted development, battle-tested with Claude
Code and Codex. Agent instructions (`AGENTS.md` / `CLAUDE.md`), project
skills, and a curated set of coding conventions come pre-wired, on top of a
modern monolith with a React frontend, authentication, background jobs, CI,
and deployment ready to go. Clone it, point your agent at it, and start
shipping features.

## What's Inside

- **Rails 8.1** on Ruby 4.0 with PostgreSQL
- **Inertia.js + React 19 + TypeScript**: the server owns routing, data, and
  auth, React owns rendering. No separate API to maintain.
- **Vite, Tailwind CSS 4, and shadcn/ui** for fast builds and a solid UI kit
- **Devise + OmniAuth (Google) + Pundit** for sign-in, OAuth, and
  authorization out of the box
- **Solid Queue / Solid Cache / Solid Cable** for database-backed jobs,
  caching, and websockets, with Solid Queue running in development too
- **pnpm** for JavaScript dependencies
- **GitHub Actions CI** running RuboCop, Brakeman, bundler-audit, tests, and
  system tests with built Vite assets
- **Kamal + Thruster** for containerized deploys

## Start a New Project

1. Clone this repository for the new project.
2. Change the default Git remote to the new project repository:

```sh
git remote set-url origin git@github.com:YOUR_USER_OR_ORG/YOUR_NEW_REPO.git
git remote -v
```

3. Install dependencies and start the app:

```sh
bundle install
pnpm install
docker compose up -d
bin/rails db:prepare
bin/dev
```

## Skills

Project skills ship with the repository (in `.agents/skills` and
`.claude/skills`):

- [inertia-rails/skills](https://github.com/inertia-rails/skills) — Inertia
  Rails patterns for controllers, forms, pages, testing, TypeScript, and
  shadcn/ui
- [impeccable](https://impeccable.style/) — frontend design and UI quality
