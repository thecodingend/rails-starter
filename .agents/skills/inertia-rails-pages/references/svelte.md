# Svelte Page Patterns

Svelte 5 equivalents for every pattern in the parent SKILL.md. Svelte 4 syntax
is noted in parentheses where it differs. All concepts, NEVER rules, and decision
matrices from the parent apply unchanged — only syntax differs.

## Page Component Structure

Pages are default exports receiving controller props via `$props()`.

```svelte
<!-- Svelte 5 -->
<script lang="ts">
  let { posts }: { posts: Post[] } = $props()
</script>

{#each posts as post (post.id)}
  <PostCard {post} />
{/each}
```

Svelte 4: `export let posts: Post[]` instead of `$props()`.

## Persistent Layouts

### Single Layout

Use a module-level script to export the layout:

```svelte
<!-- Svelte 5 -->
<script module lang="ts">
  import AppLayout from '@/layouts/AppLayout.svelte'
  export { AppLayout as layout }
</script>

<script lang="ts">
  let { course }: { course: Course } = $props()
</script>

<CourseContent {course} />
```

Svelte 4: `<script context="module">` instead of `<script module>`.

### Nested Layouts

```svelte
<script module lang="ts">
  import AppLayout from '@/layouts/AppLayout.svelte'
  import SettingsLayout from '@/layouts/SettingsLayout.svelte'
  export const layout = [AppLayout, SettingsLayout]
</script>
```

### Default Layout in createInertiaApp

```ts
// app/frontend/entrypoints/inertia.ts
import AppLayout from '@/layouts/AppLayout.svelte'

createInertiaApp({
  resolve: async (name) => {
    const pages = import.meta.glob('../pages/**/*.svelte', { eager: false })
    const page = await pages[`../pages/${name}.svelte`]()
    return {
      default: page.default,
      layout: page.layout || AppLayout,
    }
  },
  // ...
})
```

### Opting Out of Default Layout

```svelte
<script module lang="ts">
  export const layout = false
</script>
```

### Conditional Layouts

```ts
resolve: async (name) => {
  const page = await pages[`../pages/${name}.svelte`]()
  let layout = page.layout

  if (!layout) {
    if (name.startsWith('admin/')) layout = AdminLayout
    else if (name.startsWith('auth/')) layout = AuthLayout
    else layout = AppLayout
  }

  return { default: page.default, layout }
}
```

## Page Store (`$page`)

Svelte uses a store instead of `usePage()`:

```svelte
<script lang="ts">
  import { page } from '@inertiajs/svelte'
  // $page.props.auth — typed via InertiaConfig
  // $page.flash.notice — typed via InertiaConfig
</script>

<span>{$page.props.auth.user?.name}</span>
```

**Do NOT use `usePage()`** — Svelte uses `page` store with `$page` syntax.

## NO `<Head>` Component

Svelte uses native `<svelte:head>` instead of an Inertia `<Head>` component.
There is no title callback and no `head-key` deduplication.

```svelte
<svelte:head>
  <title>Dashboard</title>
  <meta name="description" content="App dashboard" />
</svelte:head>
```

## Flash Access

Flash is top-level on the page object, NOT inside props:

```svelte
<script lang="ts">
  import { page } from '@inertiajs/svelte'
  // GOOD: $page.flash.notice
  // BAD:  $page.props.flash  ← WRONG
</script>

{#if $page.flash.notice}
  <div class="alert">{$page.flash.notice}</div>
{/if}
```

## Shared Props

Typed globally via InertiaConfig (see `inertia-rails-typescript`). Page
components only type their own props:

```svelte
<script lang="ts">
  import { page } from '@inertiajs/svelte'

  let { users }: { users: User[] } = $props()
  // users is page-specific — auth comes from $page.props.auth via InertiaConfig
</script>
```

## `<Deferred>` Component

Svelte 5 uses `{#snippet}` for named slots:

```svelte
<script lang="ts">
  import { Deferred } from '@inertiajs/svelte'

  let { basic_stats }: { basic_stats: Stats } = $props()
</script>

<QuickStats data={basic_stats} />
<Deferred data="detailed_stats">
  {#snippet fallback()}
    <Spinner />
  {/snippet}
  <DetailedStats />
</Deferred>
```

Svelte 4: `<svelte:fragment slot="fallback"><Spinner /></svelte:fragment>`.

The child component reads the deferred prop via `$page.props` — same
as other frameworks, the slot receives no arguments.

## `<InfiniteScroll>` Component

```svelte
<script lang="ts">
  import { InfiniteScroll } from '@inertiajs/svelte'

  let { posts }: { posts: Post[] } = $props()
</script>

<InfiniteScroll data="posts">
  {#each posts as post (post.id)}
    <PostCard {post} />
  {/each}
  {#snippet loading()}
    <Spinner />
  {/snippet}
</InfiniteScroll>
```

Svelte 4: `<div slot="loading"><Spinner /></div>`.

Props: `data`, `manual`, `manualAfter`, `preserveUrl` — same as React.

## `<WhenVisible>` Component

```svelte
<script lang="ts">
  import { WhenVisible } from '@inertiajs/svelte'
</script>

<WhenVisible data="comments">
  {#snippet fallback()}
    <Spinner />
  {/snippet}
  <CommentsList />
</WhenVisible>
```

Svelte 4: `<svelte:fragment slot="fallback"><Spinner /></svelte:fragment>`.

## `use:inertia` Directive

Svelte-only alternative to `<Link>`. Turns any element into an Inertia link:

```svelte
<script lang="ts">
  import { inertia } from '@inertiajs/svelte'
</script>

<button use:inertia={{ href: '/logout', method: 'post' }}>
  Log out
</button>

<a use:inertia href="/users">Users</a>

<!-- With prefetching -->
<a use:inertia={{ href: '/users', prefetch: true, cacheFor: '30s' }}>Users</a>
```

Both `<Link>` and `use:inertia` are valid — `use:inertia` is useful when you need
custom elements (e.g., buttons for non-GET requests) or want to avoid a wrapper component.

## URL-Driven State (Dialogs, Tabs, Filters)

Same pattern: controller reads params → passes as prop → component derives state.

```svelte
<script lang="ts">
  import { router } from '@inertiajs/svelte'

  let { users, selected_user_id }: {
    users: User[]
    selected_user_id: number | null
  } = $props()

  let selectedUser = $derived(
    selected_user_id
      ? users.find(u => u.id === selected_user_id)
      : null
  )

  const openDialog = (id: number) =>
    router.get('/users', { user_id: id }, {
      preserveState: true,
      preserveScroll: true,
    })

  const closeDialog = () =>
    router.get('/users', {}, {
      preserveState: true,
      preserveScroll: true,
    })
</script>

<Dialog open={!!selectedUser} onOpenChange={(open) => !open && closeDialog()}>
  <DialogContent>
    <!-- content -->
  </DialogContent>
</Dialog>
```

Svelte 4: use `$:` reactive declarations instead of `$derived()`.

**NEVER** use `$state()`/`$effect()` to sync URL state. The server is the single
source of truth — the component derives state from props.
