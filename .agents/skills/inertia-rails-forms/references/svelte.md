# Svelte Form Patterns

Svelte 5 equivalents for every pattern in the parent SKILL.md. Svelte 4 syntax
is noted in parentheses where it differs. All concepts, NEVER rules, and decision
matrices from the parent apply unchanged — only syntax differs.

## `<Form>` Component

Svelte 5 uses `{#snippet}` for the children render pattern:

```svelte
<script lang="ts">
  import { Form } from '@inertiajs/svelte'
</script>

<Form method="post" action="/users">
  {#snippet children({ errors, processing })}
    <input type="text" name="name" />
    {#if errors.name}<span class="error">{errors.name}</span>{/if}

    <input type="email" name="email" />
    {#if errors.email}<span class="error">{errors.email}</span>{/if}

    <button type="submit" disabled={processing}>
      {processing ? 'Creating...' : 'Create User'}
    </button>
  {/snippet}
</Form>
```

Svelte 4: `<Form let:errors let:processing>` instead of `{#snippet}`.

### Delete Form

```svelte
<Form method="delete" action={`/posts/${post.id}`}>
  {#snippet children({ processing })}
    <button type="submit" disabled={processing}>
      {processing ? 'Deleting...' : 'Delete Post'}
    </button>
  {/snippet}
</Form>
```

### Edit Form (Pre-populated)

```svelte
<Form method="patch" action={`/posts/${post.id}`}>
  {#snippet children({ errors, processing })}
    <input type="text" name="title" value={post.title} />
    {#if errors.title}<span class="error">{errors.title}</span>{/if}

    <label>
      <input type="checkbox" name="published" value="1" checked={post.published} />
      Published
    </label>

    <button type="submit" disabled={processing}>
      {processing ? 'Saving...' : 'Update Post'}
    </button>
  {/snippet}
</Form>
```

### Key Snippet Properties

| Property | Type | Purpose |
|----------|------|---------|
| `errors` | `Record<string, string>` | Validation errors keyed by field name |
| `processing` | `boolean` | True while request is in flight |
| `progress` | `{ percentage: number } \| null` | Upload progress (file uploads only) |
| `hasErrors` | `boolean` | True if any errors exist |
| `wasSuccessful` | `boolean` | True after last submit succeeded |
| `recentlySuccessful` | `boolean` | True for 2s after success |
| `isDirty` | `boolean` | True if any input changed from initial value |
| `reset` | `(...fields) => void` | Reset specific fields or all fields |
| `clearErrors` | `(...fields) => void` | Clear specific errors or all errors |

### Event Binding

Svelte 5 uses callback props (same names as React):

```svelte
<Form
  method="post"
  action="/users"
  onSuccess={handleSuccess}
  onError={handleError}
  onBefore={() => confirm('Submit?')}
>
```

Svelte 4: `on:success={handleSuccess}`, `on:error={handleError}`.

### External Access with `bind:this`

**Important limitation:** In Svelte, the `<Form>` ref exposes **methods only**
(submit, reset, clearErrors, etc.) — NOT reactive state. Access `isDirty`,
`errors`, `processing` etc. via the snippet props instead.

```svelte
<script lang="ts">
  import { Form } from '@inertiajs/svelte'
  import type { FormComponentRef } from '@inertiajs/core'

  let formRef: FormComponentRef | undefined
</script>

<Form bind:this={formRef} method="post" action="/users">
  {#snippet children({ errors })}
    <input type="text" name="name" />
    {#if errors.name}<span class="error">{errors.name}</span>{/if}
  {/snippet}
</Form>
<button onclick={() => formRef?.submit()}>Submit</button>
<button onclick={() => formRef?.reset()}>Reset</button>
```

## `useForm` Hook

Svelte's `useForm` returns a Writable store — access data via `$form`:

```svelte
<script lang="ts">
  import { useForm } from '@inertiajs/svelte'

  let { product }: { product: Product } = $props()

  const form = useForm({
    name: product.name,
    price: product.price,
    description: product.description,
  })

  const handleSubmit = () => {
    $form.put(`/products/${product.id}`)
  }
</script>

<form onsubmit={(e) => { e.preventDefault(); handleSubmit() }}>
  <input bind:value={$form.name} />
  {#if $form.errors.name}<span>{$form.errors.name}</span>{/if}

  <input bind:value={$form.price} type="number" />
  {#if $form.errors.price}<span>{$form.errors.price}</span>{/if}

  <button disabled={$form.processing}>Save</button>
</form>

<!-- Preview consumes form data outside the form -->
<ProductPreview product={$form.data()} />
```

**Key difference from React:** Use `$form.field` (store auto-subscription) for
both reading and writing. Use `bind:value` for two-way binding.

### useForm API (Svelte-specific)

```ts
const form = useForm({ email: '', password: '' })

$form.email            // Access via store subscription
$form.email = 'new'    // Direct assignment via store
$form.data()           // Get all current data as plain object
$form.post(url)        // POST request
$form.put(url)         // PUT request
$form.patch(url)       // PATCH request
$form.delete(url)      // DELETE request
$form.processing       // boolean
$form.errors           // { field: "message" }
$form.hasErrors        // boolean
$form.progress         // Upload progress
$form.reset()          // Reset all or specific fields
$form.clearErrors()    // Clear all or specific errors
$form.isDirty          // boolean
$form.transform(cb)    // Transform data before send
$form.wasSuccessful    // boolean
$form.recentlySuccessful // boolean (2s window)
```

## File Uploads

Same auto-detection as React — `<Form>` detects file inputs and switches to FormData:

```svelte
<Form method="patch" action="/profile">
  {#snippet children({ errors, processing, progress })}
    <input type="text" name="name" value={user.name} />
    {#if errors.name}<span class="error">{errors.name}</span>{/if}

    <input type="file" name="avatar" />
    {#if errors.avatar}<span class="error">{errors.avatar}</span>{/if}

    {#if progress}
      <progress value={progress.percentage ?? 0} max="100" />
    {/if}

    <button type="submit" disabled={processing}>
      {processing ? 'Uploading...' : 'Save'}
    </button>
  {/snippet}
</Form>
```

With `useForm`:

```svelte
<script lang="ts">
  import { useForm } from '@inertiajs/svelte'

  const form = useForm<{ avatar: File | null }>({
    avatar: null,
  })

  const handleFile = (e: Event) => {
    const target = e.target as HTMLInputElement
    $form.avatar = target.files?.[0] ?? null
  }

  const handleSubmit = () => {
    $form.post('/avatars', { forceFormData: true })
  }
</script>

<form onsubmit={(e) => { e.preventDefault(); handleSubmit() }}>
  <input type="file" onchange={handleFile} />
  {#if $form.progress}
    <progress value={$form.progress.percentage} max="100" />
  {/if}
  <button disabled={$form.processing}>Upload</button>
</form>
```
