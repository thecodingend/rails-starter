# Vue 3 Form Patterns

Vue 3 equivalents for every pattern in the parent SKILL.md. All concepts, NEVER rules,
and decision matrices from the parent apply unchanged — only syntax differs.

## `<Form>` Component

Uses `#default` scoped slot instead of React render function:

```vue
<script setup lang="ts">
import { Form } from '@inertiajs/vue3'
</script>

<template>
  <Form method="post" action="/users">
    <template #default="{ errors, processing }">
      <input type="text" name="name" />
      <span v-if="errors.name" class="error">{{ errors.name }}</span>

      <input type="email" name="email" />
      <span v-if="errors.email" class="error">{{ errors.email }}</span>

      <button type="submit" :disabled="processing">
        {{ processing ? 'Creating...' : 'Create User' }}
      </button>
    </template>
  </Form>
</template>
```

Plain children (no slot) work but give no access to errors/processing/progress.

### Delete Form

```vue
<template>
  <Form method="delete" :action="`/posts/${post.id}`">
    <template #default="{ processing }">
      <button type="submit" :disabled="processing">
        {{ processing ? 'Deleting...' : 'Delete Post' }}
      </button>
    </template>
  </Form>
</template>
```

### Edit Form (Pre-populated)

Use `method="patch"` with `:value` or plain `value` for initial values:

```vue
<template>
  <Form method="patch" :action="`/posts/${post.id}`">
    <template #default="{ errors, processing }">
      <input type="text" name="title" :value="post.title" />
      <span v-if="errors.title" class="error">{{ errors.title }}</span>

      <label>
        <input type="checkbox" name="published" value="1" :checked="post.published" />
        Published
      </label>

      <button type="submit" :disabled="processing">
        {{ processing ? 'Saving...' : 'Update Post' }}
      </button>
    </template>
  </Form>
</template>
```

### Key Slot Properties

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

Vue uses standard event syntax on `<Form>`:

```vue
<Form
  method="post"
  action="/users"
  @success="handleSuccess"
  @error="handleError"
  @before="() => confirm('Submit?')"
>
```

### External Access with `ref`

```vue
<script setup lang="ts">
import { ref } from 'vue'
import { Form } from '@inertiajs/vue3'
import type { FormComponentRef } from '@inertiajs/core'

const formRef = ref<FormComponentRef | null>(null)
</script>

<template>
  <Form ref="formRef" method="post" action="/users">
    <template #default="{ errors }">
      <input type="text" name="name" />
      <span v-if="errors.name" class="error">{{ errors.name }}</span>
    </template>
  </Form>
  <button @click="formRef?.submit()">Submit</button>
  <button @click="formRef?.reset()">Reset</button>
</template>
```

## `useForm` Hook

Vue's `useForm` returns a reactive proxy — access/set data directly on `form`,
no `setData` needed:

```vue
<script setup lang="ts">
import { useForm } from '@inertiajs/vue3'

const props = defineProps<{ product: Product }>()

const form = useForm({
  name: props.product.name,
  price: props.product.price,
  description: props.product.description,
})

const handleSubmit = () => {
  form.put(`/products/${props.product.id}`)
}
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <input v-model="form.name" />
    <span v-if="form.errors.name">{{ form.errors.name }}</span>

    <input v-model="form.price" type="number" />
    <span v-if="form.errors.price">{{ form.errors.price }}</span>

    <button :disabled="form.processing">Save</button>
  </form>

  <!-- Preview consumes form data outside the form -->
  <ProductPreview :product="form.data()" />
</template>
```

**Key difference from React:** Use `v-model` for two-way binding instead of
`value` + `onChange` + `setData`. Access current data with `form.data()` method.

### useForm API (Vue-specific)

```ts
const form = useForm({
  email: '',
  password: '',
})

form.email            // Direct access (reactive proxy)
form.email = 'new'    // Direct assignment (no setData needed)
form.data()           // Get all current data as plain object
form.post(url)        // POST request
form.put(url)         // PUT request
form.patch(url)       // PATCH request
form.delete(url)      // DELETE request
form.processing       // boolean
form.errors           // { field: "message" }
form.hasErrors        // boolean
form.progress         // Upload progress
form.reset()          // Reset all or specific fields
form.clearErrors()    // Clear all or specific errors
form.isDirty          // boolean
form.transform(cb)    // Transform data before send
form.wasSuccessful    // boolean
form.recentlySuccessful // boolean (2s window)
```

## File Uploads

Same auto-detection as React — `<Form>` detects file inputs and switches to FormData:

```vue
<template>
  <Form method="patch" action="/profile">
    <template #default="{ errors, processing, progress }">
      <input type="text" name="name" :value="user.name" />
      <span v-if="errors.name" class="error">{{ errors.name }}</span>

      <input type="file" name="avatar" />
      <span v-if="errors.avatar" class="error">{{ errors.avatar }}</span>

      <progress v-if="progress" :value="progress.percentage ?? 0" max="100" />

      <button type="submit" :disabled="processing">
        {{ processing ? 'Uploading...' : 'Save' }}
      </button>
    </template>
  </Form>
</template>
```

With `useForm`:

```vue
<script setup lang="ts">
import { useForm } from '@inertiajs/vue3'

const form = useForm<{ avatar: File | null }>({
  avatar: null,
})

const handleFile = (e: Event) => {
  const target = e.target as HTMLInputElement
  form.avatar = target.files?.[0] ?? null
}

const handleSubmit = () => {
  form.post('/avatars', { forceFormData: true })
}
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <input type="file" @change="handleFile" />
    <progress v-if="form.progress" :value="form.progress.percentage" max="100" />
    <button :disabled="form.processing">Upload</button>
  </form>
</template>
```
