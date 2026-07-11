# File Uploads

File upload handling for Inertia.js + Rails with Active Storage.

## Table of Contents

- [Basic Upload with Form Component](#basic-upload-with-form-component)
- [Upload with useForm](#upload-with-useform)
- [Progress Tracking](#progress-tracking)
- [Active Storage Backend](#active-storage-backend)
- [Multiple Files](#multiple-files)
- [Image Preview](#image-preview)
- [Direct Uploads](#direct-uploads)

---

## Basic Upload with Form Component

Inertia auto-detects file inputs and switches to `multipart/form-data`.

```tsx
<Form method="post" action="/avatars">
  {({ progress, processing }) => (
    <>
      <input type="file" name="avatar" accept="image/*" />
      {progress && (
        <progress value={progress.percentage} max="100">
          {progress.percentage}%
        </progress>
      )}
      <button type="submit" disabled={processing}>Upload</button>
    </>
  )}
</Form>
```

No manual `FormData` construction needed. No special headers.

## Upload with useForm

```tsx
const form = useForm<{ avatar: File | null }>({
  avatar: null,
})

const handleSubmit = (e: React.FormEvent) => {
  e.preventDefault()
  form.post('/avatars', {
    forceFormData: true, // ensure FormData even if no file selected
  })
}

return (
  <form onSubmit={handleSubmit}>
    <input
      type="file"
      onChange={e => form.setData('avatar', e.target.files?.[0] ?? null)}
    />
    {form.progress && (
      <progress value={form.progress.percentage} max="100" />
    )}
    <button disabled={form.processing}>Upload</button>
  </form>
)
```

## Progress Tracking

Both `<Form>` and `useForm` provide upload progress automatically.

```tsx
// Form component
<Form method="post" action="/documents" onProgress={(progress) => {
  console.log(`${progress.percentage}% uploaded`)
}}>
  {({ progress }) => (
    progress && <ProgressBar value={progress.percentage} />
  )}
</Form>
```

The `progress` object:
```typescript
{
  percentage: number  // 0-100
  total: number       // total bytes
  loaded: number      // bytes uploaded
}
```

## Active Storage Backend

```ruby
# app/controllers/avatars_controller.rb
class AvatarsController < ApplicationController
  def create
    current_user.avatar.attach(params[:avatar])
    redirect_to profile_path, notice: "Avatar uploaded!"
  end
end

# app/models/user.rb
class User < ApplicationRecord
  has_one_attached :avatar
end
```

Strong parameters for files:
```ruby
def user_params
  params.require(:user).permit(:name, :email, :avatar)
end
```

## Multiple Files

```tsx
<Form method="post" action="/documents">
  {({ progress }) => (
    <>
      <input type="file" name="documents[]" multiple />
      {progress && <progress value={progress.percentage} max="100" />}
      <button type="submit">Upload All</button>
    </>
  )}
</Form>
```

Rails side:
```ruby
def create
  params[:documents].each do |doc|
    current_user.documents.attach(doc)
  end
  redirect_to documents_path, notice: "#{params[:documents].size} files uploaded"
end
```

## Image Preview

`useState` for preview is local UI state — still use `<Form>`, not `useForm`:

```tsx
function AvatarUpload() {
  const [preview, setPreview] = useState<string | null>(null)

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      setPreview(URL.createObjectURL(file))
    }
  }

  return (
    <Form method="post" action="/avatars">
      {({ progress, processing }) => (
        <>
          {preview && <img src={preview} alt="Preview" className="w-24 h-24 rounded-full" />}
          <input type="file" name="avatar" accept="image/*" onChange={handleFileChange} />
          {progress && <progress value={progress.percentage} max="100" />}
          <button type="submit" disabled={processing}>Upload</button>
        </>
      )}
    </Form>
  )
}
```

## Direct Uploads

For large files, use Active Storage direct uploads to upload directly
to the storage service (S3, GCS) instead of through the Rails server.

```tsx
import { DirectUpload } from '@rails/activestorage'

function uploadFile(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const upload = new DirectUpload(file, '/rails/active_storage/direct_uploads')
    upload.create((error, blob) => {
      if (error) reject(error)
      else resolve(blob.signed_id)
    })
  })
}
```

Then submit the signed ID via Inertia form:
```tsx
const form = useForm({ avatar: '' })

const handleFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
  const file = e.target.files?.[0]
  if (file) {
    const signedId = await uploadFile(file)
    form.setData('avatar', signedId)
  }
}
```
