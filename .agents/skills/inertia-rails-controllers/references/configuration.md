# Inertia Rails Configuration

## Table of Contents

- [Initializer](#initializer)
- [Version Tracking](#version-tracking)
- [Flash Keys](#flash-keys)
- [History Encryption](#history-encryption)
- [Error Handling](#error-handling)
- [SSR Configuration](#ssr-configuration)
- [Middleware](#middleware)

---

## Initializer

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  # Asset version — triggers full page reload when assets change
  config.version = ViteRuby.digest

  # Flash keys exposed to client (default: %i[notice alert])
  config.flash_keys = %i[notice alert toast]

  # Encrypt browser history state (default: false)
  config.encrypt_history = Rails.env.production?

  # Always include errors hash in response (default: false)
  config.always_include_errors_hash = true # true will be default in the next major release

  # Deep merge shared data instead of shallow merge (default: false)
  config.deep_merge_shared_data = false

  # Component path resolver (default: infers from controller/action)
  config.component_path_resolver = ->(path:, action:) {
    "#{path}/#{action}"
  }
end
```

## Version Tracking

Inertia uses version tracking to detect asset changes and trigger
full page reloads when the frontend bundle changes.

```ruby
# With ViteRuby (recommended)
config.version = ViteRuby.digest

# With Propshaft
config.version = Rails.application.config.assets.version

# Manual version string
config.version = '1.0.0'

# Lambda (evaluated per request)
config.version = -> { Rails.application.config.asset_version }
```

## Flash Keys

Controls which Rails flash keys are exposed to the Inertia client.

```ruby
# Default: only notice and alert
config.flash_keys = %i[notice alert]

# Add custom keys
config.flash_keys = %i[notice alert toast]
```

Access on client: `usePage().flash.notice`, `usePage().flash.alert`, etc.

## History Encryption

Encrypts page data in browser history state. Without it, sensitive props are
stored in plaintext and visible via back/forward navigation or devtools.

**Enable in production only** — encryption can cause issues with HMR and
hot-reloading in development:

```ruby
config.encrypt_history = Rails.env.production?
```

**Clear history** on logout to prevent back-button access to authenticated pages:

```ruby
# Server-side — triggers client to clear encrypted history
def destroy
  sign_out(current_user)
  redirect_to root_path, inertia: { clear_history: true }
end
```

```tsx
// Client-side — clear history programmatically (rotates encryption key)
import { router } from '@inertiajs/react'
router.clearHistory()
```

**When to use `clear_history`:** logout, role change, account switching — any
moment when the previous session's data should not be accessible via back button.

## Error Handling

```ruby
# Always include errors hash (even when empty)
config.always_include_errors_hash = true
```

Custom error page for non-Inertia requests:
```ruby
# app/controllers/application_controller.rb
rescue_from ActiveRecord::RecordNotFound do |e|
  if request.inertia?
    render inertia: 'errors/not-found', props: { message: e.message }, status: 404
  else
    render file: Rails.public_path.join('404.html'), status: 404
  end
end
```

## SSR Configuration

```ruby
# config/initializers/inertia_rails.rb
InertiaRails.configure do |config|
  config.ssr_enabled = true
  config.ssr_url = "http://localhost:13714"
end
```

Vite SSR setup:
```ts
// vite.config.ts
export default defineConfig({
  plugins: [
    ruby(),
    react(),
    tailwindcss(),
  ],
  ssr: {
    noExternal: ['@inertiajs/react'],
  },
})
```
