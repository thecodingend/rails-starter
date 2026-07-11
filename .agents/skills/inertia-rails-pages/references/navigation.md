# Navigation — Detailed Reference

Prefetching, cache tags, programmatic navigation, and external URLs.

## Table of Contents

- [Programmatic Navigation](#programmatic-navigation)
- [Partial Reloads](#partial-reloads)
- [External URLs](#external-urls)
- [History Management](#history-management)
- [Global Events](#global-events)
- [Link Prefetching](#link-prefetching)
- [Cache Control](#cache-control)

---

## Programmatic Navigation

### Basic Navigation
```tsx
import { router } from '@inertiajs/react'

router.visit('/users')                           // GET (default)
router.get('/users', { search: 'john' })          // GET with query params
router.post('/users', { data: { name: 'John' } }) // POST with body
router.put(`/users/${id}`, { data: formData })     // PUT
router.patch(`/users/${id}`, { data: formData })   // PATCH
router.delete(`/users/${id}`)                      // DELETE
```

### Visit Options
```tsx
router.visit('/users', {
  method: 'get',
  data: { search: 'john', page: 2 },
  preserveState: true,      // keep component state
  preserveScroll: true,     // keep scroll position
  replace: true,            // replace history entry
  only: ['users'],          // partial reload
  except: ['stats'],        // exclude from reload
  headers: { 'X-Custom': 'value' },
  onBefore: (visit) => { /* cancel with return false */ },
  onStart: (visit) => { /* show loading indicator */ },
  onProgress: (progress) => { /* upload progress */ },
  onSuccess: (page) => { /* handle success */ },
  onError: (errors) => { /* handle validation errors */ },
  onFinish: (visit) => { /* always runs */ },
  onCancel: () => { /* request was cancelled */ },
  onFlash: (flash) => { /* flash data received */ },
})
```

## Partial Reloads

Refresh specific props without reloading the entire page.

```tsx
// Only refresh these props
router.reload({ only: ['users', 'pagination'] })

// Refresh all props EXCEPT these
router.reload({ except: ['expensive_stats'] })
```

### Search/Filter Pattern
```tsx
function handleSearch(query: string) {
  router.get('/users', { search: query }, {
    preserveState: true,    // keep other form inputs
    preserveScroll: true,   // don't jump to top
  })
}
```

## External URLs

### From the Server (CRITICAL)

Use `inertia_location` for external URLs. **NEVER use `redirect_to`
for URLs outside the Inertia app** — it breaks because Inertia tries
to handle the redirect as an Inertia response.

```ruby
# Correct — triggers full page visit
inertia_location "https://stripe.com/checkout/session_xxx"

# WRONG — breaks Inertia
redirect_to "https://stripe.com/checkout/session_xxx"
```

### From the Client

```tsx
// For external URLs in React use <a> tag (intentionally NOT <Link>)
<a href="https://external-site.com" target="_blank" rel="noopener">
  External Site
</a>

// Or use window.location.href (rare — prefer server-side)
window.location.href = 'https://external-site.com'
```

## History Management

### Replace vs Push
```tsx
// Push new entry (default) — user can go back
router.visit('/users')

// Replace current entry — no back navigation
router.visit('/users', { replace: true })
```

### Client-Side Prop Updates (No Server Round-Trip)
```tsx
// Replace a prop value
router.replaceProp('show_modal', false)
router.replaceProp('user.name', 'Jane Smith')

// With callback
router.replaceProp('count', (current) => current + 1)

// Append/prepend to arrays
router.appendToProp('messages', { id: 4, text: 'New' })
router.prependToProp('notifications', (current, props) => ({
  id: Date.now(),
  message: `Hello ${props.auth.user.name}`,
}))
```

## Global Events

Listen to Inertia navigation events globally:

```tsx
import { router } from '@inertiajs/react'

// In a layout or app-level component
useEffect(() => {
  const removeStart = router.on('start', (event) => {
    NProgress.start()
  })
  const removeFinish = router.on('finish', (event) => {
    NProgress.done()
  })
  const removeFlash = router.on('flash', (event) => {
    showToast(event.detail.flash)
  })

  return () => {
    removeStart()
    removeFinish()
    removeFlash()
  }
}, [])
```

Available events: `before`, `start`, `progress`, `success`, `error`,
`finish`, `cancel`, `navigate`, `flash`.

## Link Prefetching

Prefetch page data before the user clicks for instant navigation.

```tsx
// Prefetch on hover (default)
<Link href="/users" prefetch>Users</Link>

// Prefetch on mount (eager)
<Link href="/dashboard" prefetch="mount">Dashboard</Link>

// Prefetch on hover with custom delay
<Link href="/users" prefetch="hover">Users</Link>
```

### Cache Duration

Control how long prefetched data stays valid:

```tsx
// Cache for 30 seconds
<Link href="/users" prefetch cacheFor="30s">Users</Link>

// Cache for 5 minutes
<Link href="/dashboard" prefetch cacheFor="5m">Dashboard</Link>

// No cache (always re-prefetch)
<Link href="/notifications" prefetch cacheFor="0">Notifications</Link>
```

### Cache Tags

Coordinate cache invalidation across multiple prefetched pages. When a
mutation affects data shown on several pages, tag them and invalidate by tag:

```tsx
// Tag prefetched pages
<Link href="/users" prefetch cacheTags="users">Users</Link>
<Link href="/dashboard" prefetch cacheTags={['dashboard', 'users']}>Dashboard</Link>

// Invalidate matching caches after a form submission
form.post('/users', {
  invalidateCacheTags: ['users', 'dashboard']
})

// Also works with router
router.post('/users', {
  data: formData,
  invalidateCacheTags: ['users'],
})
```

### Programmatic Prefetching

Prefetch without a `<Link>` — useful for predictive loading based on user context:

```tsx
import { router } from '@inertiajs/react'

// Prefetch a likely destination after user completes a step
router.prefetch('/onboarding/step-2')

// With cache duration
router.prefetch('/settings', {}, { cacheFor: '1m' })
```

### Cache Flushing (Debugging)

Clear prefetch cache manually:

```tsx
router.flushAll()        // Clear all prefetch cache
router.flush('/users')   // Clear specific URL cache
```

## Cache Control

Inertia caches pages for back/forward navigation. Control with:

```tsx
// Force fresh data (skip cache)
router.visit('/users', { cache: false })

// Replace cache entry instead of pushing
router.visit('/users', { replace: true })
```
