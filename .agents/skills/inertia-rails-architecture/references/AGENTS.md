# Architecture Rules — Expanded Reference

Incorrect/Correct pairs for all architecture rules. Use as a quick reference
when reviewing or writing Inertia.js + Rails code.

## Table of Contents

- [Rule 1: Server Owns Data (CRITICAL)](#rule-1-server-owns-data-critical)
- [Rule 2: Server Owns Auth (CRITICAL)](#rule-2-server-owns-auth-critical)
- [Rule 3: Use Form Component (CRITICAL)](#rule-3-use-form-component-critical)
- [Rule 4: Navigation (HIGH)](#rule-4-navigation-high)
- [Rule 5: Data Refresh (HIGH)](#rule-5-data-refresh-high)
- [Rule 6: Global Data (HIGH)](#rule-6-global-data-high)
- [Rule 7: Flash Messages (HIGH)](#rule-7-flash-messages-high)
- [Rule 8: Expensive Queries (MEDIUM)](#rule-8-expensive-queries-medium)
- [Rule 9: Persistent Layouts (MEDIUM)](#rule-9-persistent-layouts-medium)
- [Rule 10: Components as Renderers (MEDIUM)](#rule-10-components-as-renderers-medium)

---

## Rule 1: Server Owns Data (CRITICAL)

**Incorrect: useEffect + fetch for page data**
```tsx
// BAD — SPA pattern in an Inertia app
export default function Users() {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch('/api/users')
      .then(res => res.json())
      .then(data => {
        setUsers(data)
        setLoading(false)
      })
  }, [])

  if (loading) return <Spinner />
  return <UserList users={users} />
}
```

**Correct: Server provides data as props**
```ruby
# app/controllers/users_controller.rb
class UsersController < InertiaController
  def index
    render inertia: {
      users: User.all.as_json(only: [:id, :name, :email]),
    }
  end
end
```
```tsx
// app/frontend/pages/users/index.tsx — path matches controller/action
export default function Index({ users }: { users: User[] }) {
  return <UserList users={users} />
}
```

No loading state needed. No error handling for fetch. No race conditions.
The data arrives with the page, fully server-rendered and type-safe.

**Refreshing data without full page reload:**
```tsx
// Refresh only the users prop
router.reload({ only: ['users'] })

// After a mutation Rails redirects back and returns only the users prop
router.post('/users', {
  data: formData,
  only: ['users'],
})
```

---

## Rule 2: Server Owns Auth (CRITICAL)

**Incorrect: Client-side auth checks**
```tsx
// BAD — checking auth in React
export default function Dashboard() {
  const { auth } = usePage().props
  if (!auth.user) {
    router.visit('/login')
    return null
  }
  return <DashboardContent />
}
```

**Correct: Server handles auth, React trusts it**
```ruby
# app/controllers/dashboard_controller.rb
class DashboardController < InertiaController
  before_action :authenticate_user! # Redirect happens server-side

  def index
    render inertia: {
      stats: DashboardStats.for(Current.user),
    }
  end
end
```
```tsx
// If this component renders, user IS authenticated
export default function Index({ stats }: DashboardIndexProps) {
  return <DashboardContent stats={stats} />
}
```

If unauthenticated, the user never receives the page component.
The redirect happens server-side before any React code runs.

---

## Rule 3: Use Form Component (CRITICAL)

**Incorrect: Rolling your own form submission**
```tsx
// BAD — manual fetch/axios for forms
export default function CreateUser() {
  const [name, setName] = useState('')
  const [errors, setErrors] = useState({})
  const [submitting, setSubmitting] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setSubmitting(true)
    try {
      const res = await fetch('/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': ... },
        body: JSON.stringify({ name }),
      })
      if (!res.ok) setErrors(await res.json())
    } finally { setSubmitting(false) }
  }
}
```

**Correct: Inertia `<Form>` component**
```tsx
import { Form } from '@inertiajs/react'

export default function CreateUser() {
  return (
    <Form method="post" action="/users">
      {({ errors, processing }) => (
        <>
          <input type="text" name="name" />
          {errors.name && <span>{errors.name}</span>}
          <button type="submit" disabled={processing}>Create</button>
        </>
      )}
    </Form>
  )
}
```

`<Form>` handles: CSRF tokens, redirect following, error mapping, processing state,
file upload detection, scroll preservation, and browser history state — all
without manual `onChange` handlers or state management.

Use `useForm` hook only when you need programmatic control (dynamic fields,
external submit triggers, complex transforms, pre-populated edit forms).

---

## Rule 4: Navigation (HIGH)

**Incorrect: Traditional links or window.location**
```tsx
// BAD — causes full page reload, loses SPA behavior
<a href="/users">Users</a>
window.location.href = '/users'
```

**Correct: Inertia Link and router**
```tsx
import { Link, router } from '@inertiajs/react'

// Declarative
<Link href="/users">Users</Link>
<Link href="/users/1/edit" method="get">Edit</Link>

// Programmatic
router.visit('/users')
router.post('/users', { data: { name: 'John' } })

// With prefetching
<Link href="/users" prefetch cacheFor="30s">Users</Link>
```

Use `<a>` links only for external resources (i.e. socials).

---

## Rule 5: Data Refresh (HIGH)

**Incorrect: React Query / SWR for Inertia data**
```tsx
// BAD — separate data fetching layer in an Inertia app
import { useQuery } from '@tanstack/react-query'

export default function Users() {
  const { data: users } = useQuery({
    queryKey: ['users'],
    queryFn: () => fetch('/api/users').then(r => r.json()),
  })
}
```

**Correct: Partial reloads**
```tsx
// Refresh specific props without full page reload
router.reload({ only: ['users'] })

// Polling (simple/MVP — prefer ActionCable for production real-time)
// usePoll auto-throttles when tab is in background, auto-stops on unmount
import { usePoll } from '@inertiajs/react'
usePoll(30000, { only: ['notifications'] })
// keepAlive: true to continue polling even when tab is hidden
usePoll(30000, { only: ['notifications'], keepAlive: true })

// Manual control — start/stop polling on user action
const { start, stop } = usePoll(5000, { only: ['stats'] }, { autoStart: false })
// <button onClick={start}>Start Live Updates</button>
// <button onClick={stop}>Pause</button>

// BAD — manual setInterval (no background throttling, leaks on unmount):
// useEffect(() => {
//   const interval = setInterval(() => router.reload({ only: ['notifications'] }), 30000)
//   return () => clearInterval(interval)
// }, [])

// After user action Rails redirects back and returns only the users prop
const handleDelete = (id: number) => {
  router.delete(`/users/${id}`, {
    only: ['users'],
  })
}
```

---

## Rule 6: Global Data (HIGH)

**Incorrect: React Context for global app state**
```tsx
// BAD — reimplementing what inertia_share already does
const AuthContext = createContext(null)
const FlashContext = createContext(null)

function App({ children }) {
  const [user, setUser] = useState(null)
  useEffect(() => { fetch('/api/me').then(...) }, [])
  return (
    <AuthContext.Provider value={user}>
      {children}
    </AuthContext.Provider>
  )
}
```

**Correct: Shared props via inertia_share**
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  inertia_share do
    { auth: { user: Current.user&.as_json(only: [:id, :name, :email, :role]) } }
  end
end
```
```tsx
// Access anywhere in React tree
import { usePage } from '@inertiajs/react'

function UserMenu() {
  const { props } = usePage()
  return <span>{props.auth.user?.name}</span>
}
```

---

## Rule 7: Flash Messages (HIGH)

**Incorrect: Passing flash through shared props manually**
```ruby
# BAD — flash is already automatic in inertia-rails
inertia_share do
  { flash: flash.to_hash.compact }
end
```
```tsx
// BAD — accessing flash as a regular prop
const { flash } = usePage().props
```

**Correct: Use Rails flash normally (it's automatic)**
```ruby
# Rails flash works automatically with Inertia.
# By default notice and alert keys are included,
# Configure if additional keys are needed:
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.flash_keys = %i[notice alert toast]
end

# In controllers, just use Rails flash normally:
def create
  @user = User.create!(user_params)
  redirect_to users_path, notice: "User created!"
end
```
```tsx
// Access flash directly on the page object (NOT props)
import { usePage } from '@inertiajs/react'

function FlashMessages() {
  const { flash } = usePage()
  return (
    <>
      {flash.notice && <Toast type="success">{flash.notice}</Toast>}
      {flash.alert && <Toast type="error">{flash.alert}</Toast>}
    </>
  )
}
```

Flash data is NOT persisted in history state — it won't reappear when
navigating back. Use `router.flash('key', 'value')` for client-side flash.

---

## Rule 8: Expensive Queries (MEDIUM)

**Incorrect: Loading states in React for server data**
```tsx
// BAD — client-side loading for data that should be deferred server-side
export default function Dashboard({ basicStats }) {
  const [detailedStats, setDetailedStats] = useState(null)
  useEffect(() => {
    fetch('/api/detailed-stats').then(r => r.json()).then(setDetailedStats)
  }, [])
  return detailedStats ? <Details data={detailedStats} /> : <Spinner />
}
```

**Correct: Deferred props**
```ruby
# Server defers expensive computation
def index
  render inertia: {
    basic_stats: DashboardStats.quick,
    detailed_stats: InertiaRails.defer { DashboardStats.detailed },
    permissions: InertiaRails.defer(group: 'auth') { Current.user.permissions },
  }
end
```
```tsx
import { Deferred } from '@inertiajs/react'

export default function Index({ basic_stats }: DashboardIndexProps) {
  return (
    <>
      <QuickStats data={basic_stats} />
      <Deferred data="detailed_stats" fallback={<Spinner />}>
        <DetailedStats />
      </Deferred>
    </>
  )
}
```

---

## Rule 9: Persistent Layouts (MEDIUM)

**Incorrect: Remounting layout on every navigation**
```tsx
// BAD — layout remounts, losing audio player state, etc.
export default function Show({ course }) {
  return (
    <AppLayout>
      <CourseContent course={course} />
    </AppLayout>
  )
}
```

**Correct: Set a default persistent layout in `createInertiaApp`**
```tsx
// Inside createInertiaApp's resolve callback
page.default.layout ??= (page: ReactNode) => <Layout>{page}</Layout>
```

Override per-page when needed:

```tsx
import { AppLayout } from '@/layouts/app-layout'

export default function Show({ course }: CourseShowProps) {
  return <CourseContent course={course} />
}

Show.layout = (page: React.ReactNode) => <AppLayout>{page}</AppLayout>
```

The layout persists across page navigations. Audio players keep playing,
WebSocket connections stay alive, and heavy components don't reinitialize.

---

## Rule 10: Components as Renderers (MEDIUM)

**Incorrect: React component that fetches its own data**
```tsx
// BAD — component is both a data fetcher and a renderer
function UserProfile({ userId }) {
  const [user, setUser] = useState(null)
  useEffect(() => {
    fetch(`/api/users/${userId}`).then(r => r.json()).then(setUser)
  }, [userId])
  if (!user) return <Spinner />
  return <ProfileCard user={user} />
}
```

**Correct: Component receives data, renders it**
```tsx
// Component is a pure renderer
function UserProfile({ user }: { user: User }) {
  return <ProfileCard user={user} />
}
```
```ruby
# Data comes from the controller
# app/controllers/users_controller.rb
def show
  render inertia: {
    user: User.find(params[:id]).as_json(only: [:id, :name, :email, :bio])
  }
end
```

If a child component needs data, pass it down as props from the page.
The page component is the bridge between server data and React rendering.
