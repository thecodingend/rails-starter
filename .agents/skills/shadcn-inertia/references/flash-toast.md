# Flash Toast with Sonner

Full-stack flash toast: Rails flash_keys config + useFlash hook + Sonner.

Use `notice` for success and `alert` for error — these are the standard Rails flash keys
and match the default `FlashData` type. No need to add custom keys for success/error messaging.

## Rails Setup

Configure which flash keys are exposed to the client:

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.flash_keys = %i[notice alert]
end
```

Use `notice:` for success and `alert:` for errors — do NOT manually pass `inertia: { flash: ... }`:

```ruby
def create
  @user = User.new(user_params)
  if @user.save
    redirect_to users_path, notice: "User created!"
  else
    redirect_back fallback_location: new_user_path, alert: "Failed to create user",
      inertia: { errors: @user.errors.to_hash }
  end
end
```

## useFlash Hook

**Important:** `toast` is imported from `'sonner'` (the package), NOT from `@/components/ui/sonner` (that only exports `Toaster`).

```tsx
// app/frontend/hooks/use-flash.ts
import { router, usePage } from '@inertiajs/react'
import { useEffect, useRef } from 'react'
import { toast } from 'sonner' // NOT from '@/components/ui/sonner'

function showFlash(flash: FlashData) {
  if (flash.alert) toast.error(flash.alert)
  if (flash.notice) toast(flash.notice)
}

export function useFlash() {
  const { flash } = usePage()
  const toastShowed = useRef(false)

  // Show flash from initial page load
  useEffect(() => {
    if (!toastShowed.current) {
      toastShowed.current = true
      showFlash(flash)
    }
  }, [flash])

  // Listen for flash events (client-side flash, redirects)
  useEffect(() => {
    return router.on('flash', (event) => {
      showFlash(event.detail.flash)
    })
  }, [])
}
```

## Layout Integration

Use in persistent layout (runs once, covers all pages):

```tsx
// app/frontend/layouts/persistent-layout.tsx
import { Toaster } from 'sonner'
import { useFlash } from '@/hooks/use-flash'

export function PersistentLayout({ children }) {
  useFlash()
  return <>{children}<Toaster /></>
}
```
