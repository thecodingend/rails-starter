# Advanced Form Patterns

Advanced form handling for Inertia.js + Rails + React.

## Table of Contents

- [useForm Hook](#useform-hook)
- [Data Transforms](#data-transforms)
- [Remember State](#remember-state)
- [Nested Data](#nested-data)
- [Multiple Forms on One Page](#multiple-forms-on-one-page)
- [Conditional Submission](#conditional-submission)
- [Reset and Clear Patterns](#reset-and-clear-patterns)
- [Dynamic Fields](#dynamic-fields)
- [Multi-Step Forms](#multi-step-forms)
- [Client-Side Validation](#client-side-validation)

---

## useForm Hook

Use `useForm` when form data needs to live **outside** the `<Form>` element:

- **Multi-step wizards** — single form state shared across step components
- **Live preview** — form data drives a sibling preview panel (e.g. populate product fields, see the store page update in real time)

```tsx
import { useForm } from '@inertiajs/react'

export default function ProductEditor({ product }: { product: Product }) {
  const form = useForm({
    name: product.name,
    price: product.price,
    description: product.description,
  })

  return (
    <div className="grid grid-cols-2 gap-8">
      <form onSubmit={e => { e.preventDefault(); form.put(`/products/${product.id}`) }}>
        <input value={form.data.name} onChange={e => form.setData('name', e.target.value)} />
        {form.errors.name && <span>{form.errors.name}</span>}
        {/* ... more fields */}
        <button disabled={form.processing}>Save</button>
      </form>

      {/* Preview consumes form.data outside the form */}
      <ProductPreview product={form.data} />
    </div>
  )
}
```

**For everything else, use `<Form>`** — it handles CSRF, redirects, errors, transforms, file detection, and history state with zero setup.

### useForm API

```tsx
const {
  data,              // Current form data
  setData,           // (key, value) or (values) or (callback)
  post,              // (url, options?) — POST request
  put,               // (url, options?) — PUT request
  patch,             // (url, options?) — PATCH request
  delete: destroy,   // (url, options?) — DELETE request
  processing,        // boolean
  errors,            // { field: "message" }
  hasErrors,         // boolean
  progress,          // Upload progress object
  reset,             // (...fields) — reset to initial values
  clearErrors,       // (...fields) — clear specific errors
  isDirty,           // boolean
  transform,         // (callback) — transform data before send
  wasSuccessful,     // boolean
  recentlySuccessful,// boolean (2s window)
} = useForm({ /* initial data */ })
```

## Data Transforms

Transform data before it's sent to the server. Useful for formatting
dates, removing empty fields, or restructuring data.

### With `<Form>` component:
```tsx
<Form
  method="post"
  action="/events"
  transform={(data) => ({
    ...data,
    start_date: formatISO(data.start_date),
    tags: data.tags.filter(Boolean),
  })}
>
```

### With `useForm` hook:
```tsx
const form = useForm({ name: '', price: '' })

const handleSubmit = (e: React.FormEvent) => {
  e.preventDefault()
  form.transform((data) => ({
    ...data,
    price: parseFloat(data.price) * 100, // cents
  }))
  form.post('/products')
}
```

## Remember State

Persist form data across navigations so users don't lose their input
when they navigate away and come back.

```tsx
// useForm with remember key
const form = useForm('create-user', {
  name: '',
  email: '',
  role: 'member',
})
// Data persists in history state under the key 'create-user'
```

The first argument is a unique key for the form state. When the user
navigates away and back, the form data is restored.

## Nested Data

Rails accepts nested attributes via strong parameters. Structure
your form data to match.

### With `useForm`:
```tsx
const form = useForm({
  user: {
    name: '',
    email: '',
    address_attributes: {
      street: '',
      city: '',
      zip: '',
    },
  },
})

// Update nested field
form.setData('user.address_attributes.city', 'New York')
```

### With `<Form>` component:
```tsx
<Form method="post" action="/users">
  {({ errors }) => (
    <>
      <input name="user[name]" />
      <input name="user[email]" />
      <input name="user[address_attributes][street]" />
      <input name="user[address_attributes][city]" />
    </>
  )}
</Form>
```

Rails controller:
```ruby
def user_params
  params.require(:user).permit(
    :name, :email,
    address_attributes: [:street, :city, :zip]
  )
end
```

## Multiple Forms on One Page

Use error bags to namespace errors when multiple forms appear on the
same page (e.g., login + register on the same screen).

```tsx
<Form method="post" action="/login" errorBag="login">
  {({ errors }) => (
    <>
      <input name="email" />
      {errors.email && <span>{errors.email}</span>}
    </>
  )}
</Form>

<Form method="post" action="/register" errorBag="register">
  {({ errors }) => (
    <>
      <input name="email" />
      {errors.email && <span>{errors.email}</span>}
    </>
  )}
</Form>
```

## Conditional Submission

Confirm before submitting, or conditionally prevent submission.

```tsx
<Form
  method="delete"
  action={`/users/${user.id}`}
  onBefore={() => confirm('Delete this user?')}
>
  {({ processing }) => (
    <button type="submit" disabled={processing}>Delete</button>
  )}
</Form>
```

With `useForm`:
```tsx
const handleSubmit = (e: React.FormEvent) => {
  e.preventDefault()
  if (!confirm('Submit?')) return
  form.post('/users')
}
```

## Reset and Clear Patterns

```tsx
const form = useForm({ name: '', email: '', role: 'member' })

// Reset all fields to initial values
form.reset()

// Reset specific fields
form.reset('name', 'email')

// Clear all errors
form.clearErrors()

// Clear specific field errors
form.clearErrors('name', 'email')
```

With `<Form>`:
```tsx
<Form method="post" action="/users">
  {({ reset, clearErrors, wasSuccessful }) => (
    <>
      {/* fields */}
      <button type="button" onClick={() => reset()}>Reset</button>
      <button type="button" onClick={() => clearErrors()}>Clear Errors</button>
    </>
  )}
</Form>
```

## Dynamic Fields

Adding/removing fields dynamically requires `useForm` (not `<Form>`).

```tsx
const form = useForm({
  items: [{ name: '', quantity: 1 }],
})

const addItem = () => {
  form.setData('items', [...form.data.items, { name: '', quantity: 1 }])
}

const removeItem = (index: number) => {
  form.setData('items', form.data.items.filter((_, i) => i !== index))
}

return (
  <form onSubmit={e => { e.preventDefault(); form.post('/orders') }}>
    {form.data.items.map((item, index) => (
      <div key={index}>
        <input
          value={item.name}
          onChange={e => {
            const items = [...form.data.items]
            items[index] = { ...items[index], name: e.target.value }
            form.setData('items', items)
          }}
        />
        <button type="button" onClick={() => removeItem(index)}>Remove</button>
      </div>
    ))}
    <button type="button" onClick={addItem}>Add Item</button>
    <button type="submit">Submit</button>
  </form>
)
```

## Multi-Step Forms

Use `useForm` (not `<Form>`) with a remember key. Track the current step
with `useState`. Validate per step with `setError`/`clearErrors`, submit
once at the final step.

```tsx
const [step, setStep] = useState(1)

// Remember key preserves progress across navigation
const form = useForm('onboarding', {
  email: '', password: '',  // step 1
  name: '', company: '',    // step 2
  plan: 'starter' as const, // step 3
})

function nextStep() {
  form.clearErrors()
  // Per-step client-side validation
  if (step === 1 && !form.data.email) {
    return form.setError('email', 'Required')
  }
  setStep(s => s + 1)
}

// Single POST at the end — Rails sees one standard action
const submit = (e: React.FormEvent) => {
  e.preventDefault()
  form.post('/onboarding')
}
```

Each step renders its own fields gated by `{step === N && (...)}`.
Back/forward buttons call `setStep`. Only the final step has
`<button type="submit">`.

## Cache Tag Invalidation

After a form submission, invalidate prefetch caches for pages that show the
affected data. Use `invalidateCacheTags` on `<Form>` or `useForm` submit options:

```tsx
// With <Form>
<Form method="post" action="/users" invalidateCacheTags={['users', 'dashboard']}>
  {({ errors, processing }) => (
    <>{/* fields */}</>
  )}
</Form>

// With useForm
form.post('/users', {
  invalidateCacheTags: ['users', 'dashboard'],
})
```

Tags must match `cacheTags` set on `<Link prefetch cacheTags="...">` — see
`inertia-rails-pages` navigation reference for prefetch tag setup.

## Client-Side Validation

Use `setError` for immediate feedback before submitting to the server.
Call `clearErrors` before re-validating to avoid stale messages.

```tsx
function validateAndSubmit(e: React.FormEvent) {
  e.preventDefault()
  form.clearErrors()

  if (form.data.password.length < 8) {
    form.setError('password', 'Must be at least 8 characters')
    return
  }
  if (form.data.password !== form.data.password_confirmation) {
    form.setError('password_confirmation', 'Passwords do not match')
    return
  }

  form.post('/register')
}
```
```
