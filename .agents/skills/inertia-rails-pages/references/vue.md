# Vue 3 Page Patterns

Vue 3 equivalents for every pattern in the parent SKILL.md. All concepts, NEVER rules,
and decision matrices from the parent apply unchanged — only syntax differs.

## Page Component Structure

Pages are default exports receiving controller props via `defineProps`.

```vue
<script setup lang="ts">
defineProps<{
  posts: Post[]
}>()
</script>

<template>
  <PostList :posts="posts" />
</template>
```

`interface` works fine with `defineProps<T>()` in Vue (the React TS2344 issue does not apply).

## Persistent Layouts

### Single Layout

```vue
<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue'

defineOptions({ layout: AppLayout })

defineProps<{ course: Course }>()
</script>

<template>
  <CourseContent :course="course" />
</template>
```

### Nested Layouts

```vue
<script setup lang="ts">
import AppLayout from '@/layouts/AppLayout.vue'
import SettingsLayout from '@/layouts/SettingsLayout.vue'

defineOptions({ layout: [AppLayout, SettingsLayout] })
</script>
```

### Default Layout in createInertiaApp

```ts
// app/frontend/entrypoints/inertia.ts
import AppLayout from '@/layouts/AppLayout.vue'

createInertiaApp({
  resolve: async (name) => {
    const pages = import.meta.glob('../pages/**/*.vue', { eager: false })
    const page = await pages[`../pages/${name}.vue`]()
    page.default.layout = page.default.layout || AppLayout
    return page
  },
  // ...
})
```

Pages can override with their own layout or `false` for no layout:

```vue
<script setup lang="ts">
defineOptions({ layout: false }) // opt out of default layout
</script>
```

### Conditional Layouts

```ts
resolve: async (name) => {
  const page = await pages[`../pages/${name}.vue`]()

  if (name.startsWith('admin/')) {
    page.default.layout = page.default.layout || AdminLayout
  } else if (name.startsWith('auth/')) {
    page.default.layout = page.default.layout || AuthLayout
  } else {
    page.default.layout = page.default.layout || AppLayout
  }

  return page
}
```

## usePage() Composable

`usePage()` returns a reactive object. Use `computed()` for derived values
to maintain reactivity.

```vue
<script setup lang="ts">
import { usePage } from '@inertiajs/vue3'
import { computed } from 'vue'

const page = usePage()
const userName = computed(() => page.props.auth.user?.name)
</script>

<template>
  <span>{{ userName }}</span>
</template>
```

**Do NOT destructure `usePage()`** at the top level — it breaks reactivity:

```vue
<script setup lang="ts">
// BAD — loses reactivity:
// const { props } = usePage()

// GOOD — keep the reactive reference:
const page = usePage()
</script>
```

## `<Head>` Component

Identical API to React — import from the Vue adapter:

```vue
<script setup lang="ts">
import { Head } from '@inertiajs/vue3'
</script>

<template>
  <Head title="Dashboard" />
</template>
```

## Flash Access

Flash is top-level on the page object, NOT inside props:

```vue
<script setup lang="ts">
import { usePage } from '@inertiajs/vue3'

const page = usePage()
// GOOD: page.flash.notice
// BAD:  page.props.flash  ← WRONG
</script>
```

## Shared Props

Typed globally via InertiaConfig (see `inertia-rails-typescript`). Page
components only type their own props:

```vue
<script setup lang="ts">
import { usePage } from '@inertiajs/vue3'
import { computed } from 'vue'

defineProps<{
  users: User[]  // page-specific only — auth is NOT here
}>()

const page = usePage()
const auth = computed(() => page.props.auth) // typed via InertiaConfig
</script>
```

## `<Deferred>` Component

Uses `#default` and `#fallback` scoped slots:

```vue
<script setup lang="ts">
import { Deferred, usePage } from '@inertiajs/vue3'

defineProps<{ basic_stats: Stats }>()
</script>

<template>
  <QuickStats :data="basic_stats" />
  <Deferred data="detailed_stats">
    <template #fallback>
      <Spinner />
    </template>
    <DetailedStats />
  </Deferred>
</template>
```

The child component reads the deferred prop via `usePage().props` — same
as React, the slot receives no arguments.

## `<InfiniteScroll>` Component

```vue
<script setup lang="ts">
import { InfiniteScroll } from '@inertiajs/vue3'

defineProps<{ posts: Post[] }>()
</script>

<template>
  <InfiniteScroll data="posts">
    <PostCard v-for="post in posts" :key="post.id" :post="post" />
    <template #loading>
      <Spinner />
    </template>
  </InfiniteScroll>
</template>
```

Props: `data`, `manual`, `manualAfter`, `preserveUrl` — same as React.

## `<WhenVisible>` Component

```vue
<script setup lang="ts">
import { WhenVisible } from '@inertiajs/vue3'
</script>

<template>
  <WhenVisible data="comments">
    <template #fallback>
      <Spinner />
    </template>
    <CommentsList />
  </WhenVisible>
</template>
```

## URL-Driven State (Dialogs, Tabs, Filters)

Same pattern: controller reads params → passes as prop → component derives state.

```vue
<script setup lang="ts">
import { router } from '@inertiajs/vue3'
import { computed } from 'vue'

const props = defineProps<{
  users: User[]
  selected_user_id: number | null
}>()

const selectedUser = computed(() =>
  props.selected_user_id
    ? props.users.find(u => u.id === props.selected_user_id)
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

<template>
  <Dialog :open="!!selectedUser" @update:open="(open) => !open && closeDialog()">
    <DialogContent>
      <!-- content -->
    </DialogContent>
  </Dialog>
</template>
```

**NEVER** use `ref()`/`watch()` to sync URL state. The server is the single
source of truth — the component derives state from props.
