---
layout: article
title: The briefing is part of the codebase
date: 2026-07-22
description: Give the same prompt to the same model in two different repositories and you get two different engineers. Why this starter commits its agent instructions next to the code they govern.
---

Give the same prompt to the same model in two different repositories and you get
two different engineers. In one, the agent writes a service object, wraps it in a
form object, adds a `try/rescue` around code that cannot fail, and reaches for
`react-hook-form` because that's what most of the internet does. In the other, it
writes a fat model, a thin controller, and a page component that reads like the
one next to it.

The difference isn't the model. It's what the repository told the model before it
started typing.

## What gets committed

This starter treats agent instructions as part of the codebase, versioned and
reviewed like everything else:

- **`CLAUDE.md` / `AGENTS.md`** at the repo root. The house rules — coding style,
  Rails preferences, React preferences, testing philosophy. An agent loads them
  with every task.
- **Nine project skills** in `.claude/skills` and `.agents/skills`, pinned by
  `skills-lock.json`. A skill is a focused instruction set the agent loads when
  the work matches: building a form loads the Inertia form patterns, writing a
  controller test loads the Minitest matchers.

The rules are short, opinionated, and blunt on purpose. A few, verbatim:

> Accept duplication when it keeps the code obvious. Do not extract for neatness
> alone.

> Helpers are near-banned.

> Prefer failing loudly over adding protection against programmer errors or
> impossible states.

Blunt matters. An instruction like "write clean code" does nothing; an
instruction like "no service objects, put it in the model" is a decision the
agent can actually follow — and one a reviewer no longer has to make in every
pull request.

## What it looks like in practice

Ask an agent in this repo for a page that lists projects and it produces the
shape the conventions describe — explicit props from the controller, React as a
renderer, nothing in between:

```ruby
class ProjectsController < ApplicationController
  def index
    render inertia: {
      projects: Current.user.projects.order(created_at: :desc)
        .as_json(only: [ :id, :name, :created_at ])
    }
  end
end
```

No serializer class, no API namespace, no client-side store to keep in sync. The
interesting thing is not that this code is clever — it's that it's boring in
exactly the way the rest of the codebase is boring, and it came out of the agent
that way on the first pass.

## Rules you can disagree with

Committed instructions have one more property worth naming: they're editable.
If your team likes service objects, delete the rule and every diff after that
follows your version. The point isn't this particular set of opinions — it's
that the opinions live in one reviewable file instead of being re-argued,
prompt by prompt, in every session.

That's the bet this starter makes. Models keep getting better on their own.
The codebase that briefs them is the part you control.

If you want to try it: [clone the starter](https://github.com/thecodingend/rails-starter),
run `bin/dev`, and point your agent at it.
