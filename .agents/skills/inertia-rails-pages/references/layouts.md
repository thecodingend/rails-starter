# Layouts — Detailed Reference

Persistent and nested layout patterns for Inertia.js + React.

## Table of Contents

- [Why Persistent Layouts](#why-persistent-layouts)
- [Single Layout](#single-layout)
- [Nested Layouts](#nested-layouts)
- [Default Layout](#default-layout)
- [Conditional Layouts](#conditional-layouts)
- [Layout with Props](#layout-with-props)
- [Scroll Regions](#scroll-regions)

---

## Why Persistent Layouts

In Inertia, layouts persist across navigations. Unlike wrapping content
in a layout component (which remounts on every navigation), persistent
layouts keep their state:

- Audio/video players continue playing
- WebSocket connections stay alive
- Heavy component trees don't re-render

## Single Layout

```tsx
import { AppLayout } from '@/layouts/app-layout'

export default function Index({ users }: Props) {
  return <UserList users={users} />
}

Index.layout = (page: React.ReactNode) => <AppLayout>{page}</AppLayout>
```

**Incorrect — layout remounts every navigation:**
```tsx
// BAD — wrapping in return causes remount
export default function Index({ users }: Props) {
  return (
    <AppLayout>
      <UserList users={users} />
    </AppLayout>
  )
}
```

## Default Layout

Set a default layout in the Inertia entrypoint so pages don't need
to declare it individually:

```tsx
// app/frontend/entrypoints/inertia.tsx
createInertiaApp({
  resolve: async (name) => {
    const pages = import.meta.glob('../pages/**/*.tsx', { eager: false })
    const page = await pages[`../pages/${name}.tsx`]()

    // Set default layout if page doesn't define one
    page.default.layout ??= (p: React.ReactNode) => (
      <AppLayout>{p}</AppLayout>
    )

    return page
  },
  // ...
})
```

Pages can still override with their own layout or `null` for no layout:

```tsx
// Opt out of default layout
LoginPage.layout = null

// Use different layout
AdminPage.layout = (page: React.ReactNode) => <AdminLayout>{page}</AdminLayout>
```

## Conditional Layouts

Choose layout based on page props or user state:

```tsx
// In the entrypoint resolve function
resolve: async (name) => {
  const page = await pages[`../pages/${name}.tsx`]()

  if (name.startsWith('admin/')) {
    page.default.layout ??= (p: React.ReactNode) => <AdminLayout>{p}</AdminLayout>
  } else if (name.startsWith('auth/')) {
    page.default.layout ??= (p: React.ReactNode) => <AuthLayout>{p}</AuthLayout>
  } else {
    page.default.layout ??= (p: React.ReactNode) => <AppLayout>{p}</AppLayout>
  }

  return page
}
```

## Layout with Props

Layouts receive the page component as children. Access shared props
with `usePage()`:

```tsx
// app/frontend/layouts/app-layout.tsx
import { usePage, Link } from '@inertiajs/react'

export function AppLayout({ children }: { children: React.ReactNode }) {
  const { props, flash } = usePage()

  return (
    <div className="min-h-screen">
      <nav>
        <Link href="/">Home</Link>
        {props.auth.user && (
          <span>{props.auth.user.name}</span>
        )}
      </nav>

      <main>{children}</main>

      {flash.notice && <Toast>{flash.notice}</Toast>}
    </div>
  )
}
```

## Scroll Regions

By default, Inertia resets scroll to the top on navigation.
For layouts with scrollable regions, use `scroll-region`:

```tsx
export function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen">
      <aside className="w-64 overflow-y-auto" scroll-region>
        <Navigation />
      </aside>
      <main className="flex-1 overflow-y-auto" scroll-region>
        {children}
      </main>
    </div>
  )
}
```

The `scroll-region` attribute tells Inertia to remember and restore
scroll position for that element across navigations.

Preserve scroll on specific navigations:
```tsx
<Link href="/users" preserveScroll>Users</Link>
router.visit('/users', { preserveScroll: true })
```
