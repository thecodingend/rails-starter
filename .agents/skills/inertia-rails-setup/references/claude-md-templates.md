# CLAUDE.md Template Blocks

Assemble these blocks based on the **final** stack (detected + installed).

## Header (always)

```markdown
## Inertia Rails Stack

- **Frontend**: [React/Vue 3/Svelte] with @inertiajs/[react|vue3|svelte] [version]
```

## Serialization (pick ONE)

**alba-inertia:**
```markdown
- **Serialization**: alba-inertia convention-based rendering. Set instance variables — `Alba::Inertia::Controller` auto-detects resources. Do NOT use `render inertia: { ... }` directly. This overrides render patterns from other Inertia skills.
- **Shared props**: `SharedPropsResource` via `inertia_share { SharedPropsResource.new(self).to_inertia }`, NOT raw `inertia_share` with `as_json`.
- **Types**: Typelizer auto-generates TypeScript from Alba resources. Do NOT manually edit generated files.
```

**alba + typelizer (no alba-inertia):**
```markdown
- **Serialization**: Alba resources with Typelizer. Use `render inertia: { key: ResourceClass.new(data) }`.
- **Types**: Typelizer auto-generates TypeScript from Alba resources. Do NOT manually edit generated files.
```

**Neither:**
```markdown
- **Serialization**: `render inertia: { key: value }` with `as_json`. The `alba-inertia` skill does NOT apply — ignore it.
```

## UI (pick ONE per framework)

**React + shadcn/ui:**
```markdown
- **UI**: shadcn/ui adapted for Inertia. NEVER react-hook-form, zod, FormField, FormItem, or FormMessage — use Inertia `<Form>` with plain shadcn inputs.
```

**Vue + shadcn-vue:**
```markdown
- **UI**: shadcn-vue adapted for Inertia. Use Inertia `<Form>` with plain shadcn-vue inputs via `#default` scoped slot.
```

**Svelte + shadcn-svelte:**
```markdown
- **UI**: shadcn-svelte (bits-ui) adapted for Inertia. Use Inertia `<Form>` with plain shadcn-svelte inputs via `{#snippet}` syntax.
```

**Not present:**
```markdown
- **UI**: Custom components. The shadcn skills do NOT apply — ignore them.
```

## Pagination (if applicable)

**Pagy:** `- **Pagination**: Pagy. Use pagy helper in controllers, pass pagy_metadata as prop.`

**Kaminari:** `- **Pagination**: Kaminari. Use .page(params[:page]).per(25) in controllers.`

## Testing (pick ONE)

**RSpec:** `- **Testing**: RSpec with inertia_rails/rspec matchers. Use render_component, have_props, have_flash — NOT direct property access.`

**Minitest:** `- **Testing**: Minitest. Load references/minitest.md from inertia-rails-testing for assertions.`

## Routing (if applicable)

**js-routes:** `- **Routing**: js-routes for typed path helpers. Run rails js_routes:generate after changing routes.rb.`

## Authorization (if applicable)

`- **Authorization**: [GEM NAME]. Pass can hashes as props — see references/authorization.md in inertia-rails-controllers.`

## Footer (always)

```markdown
- **Architecture**: Server owns routing, data, and auth. [React/Vue/Svelte] renders only. See `inertia-rails-architecture` for the decision matrix.
```
