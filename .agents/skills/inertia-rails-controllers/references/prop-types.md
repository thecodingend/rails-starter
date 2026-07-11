# Prop Types — Detailed Reference

Each prop type with real-world examples for inertia-rails 3.17+.

## Table of Contents

- [Regular Props](#regular-props)
- [Optional Props](#optional-props)
- [Deferred Props](#deferred-props)
- [Once Props](#once-props)
- [Merge Props](#merge-props)
- [Always Props](#always-props)
- [Scroll Props](#scroll-props)
- [Resetting Merge/Scroll Props](#resetting-mergescroll-props)
- [Combining Prop Types](#combining-prop-types)
---

## Regular Props

Always included in the initial page response. Wrap in `-> {}` to skip evaluation during partial reloads that don't request them.

```ruby
render inertia: {
  filters: { search: params[:search], sort: params[:sort] },
  users: -> { User.where(active: true).as_json(only: [:id, :name, :email]) },
  total_count: -> { User.active.count },
}
```

With `router.reload({ only: ['filters'] })`, `users` and `total_count` are never evaluated.

Rule of thumb: wrap anything involving a query in `-> {}`. Use plain values only for cheap data like params or literals.

## Optional Props

Only evaluated when explicitly requested via partial reload headers.
Saves computation on initial page load.

```ruby
render inertia: {
  users: User.active.as_json(only: [:id, :name]),
  # Only computed when client requests it
  export_data: InertiaRails.optional { User.active.to_csv },
  detailed_stats: InertiaRails.optional { Analytics.compute_detailed },
}
```

Client requests optional props with `router.reload`:
```tsx
// Only fetches export_data, skips everything else
router.reload({ only: ['export_data'] })
```

## Deferred Props

Loaded automatically after the initial page render. The page loads fast
with a placeholder, then deferred data streams in.

```ruby
render inertia: {
  # Fast — included in initial response
  course: @course.as_json(only: [:id, :title, :description]),

  # Slow — loaded after page renders
  reviews: InertiaRails.defer { @course.reviews.includes(:user).as_json },

  # Grouped — fetched together in a single request
  chart_data: InertiaRails.defer(group: 'analytics') { Analytics.chart_for(@course) },
  engagement: InertiaRails.defer(group: 'analytics') { Analytics.engagement_for(@course) },
}
```

React side with `<Deferred>`:
```tsx
<Deferred data="reviews" fallback={<ReviewsSkeleton />}>
  <ReviewsList />
</Deferred>
```

## Once Props

Resolved once per session, remembered across navigations.
Use for reference data that rarely changes.

```ruby
render inertia: {
  # Fetched once, cached across navigations
  countries: InertiaRails.once { Country.pluck(:name, :code) },
  timezones: InertiaRails.once { ActiveSupport::TimeZone::MAPPING.keys },
  roles: InertiaRails.once { User::ROLES },
}
```

## Merge Props

Appended to existing array on the client. Use for accumulating data across
partial reloads — new items are added to the existing list without replacing it.

When merging arrays, you may use the `match_on` parameter to match existing items
by a specific field and update them instead of appending new ones.

For **infinite scroll**, prefer `InertiaRails.scroll` (see [Scroll Props](#scroll-props))
which handles scroll-aware loading automatically. Use `merge` for patterns where
data accumulates from user actions or background updates:

```ruby
# Activity log — poll or ActionCable triggers router.reload({ only: ['activities'] })
render inertia: {
  activities: InertiaRails.merge { @recent_activities.as_json },
}

# Chat / live feed — new messages appended via partial reload
# update existing ones by id
render inertia: {
  messages: InertiaRails.merge(match_on: 'id')) { @messages.as_json(only: [:id, :body, :created_at]) },
}

# Nested data
InertiaRails.merge(append: 'data', match_on: 'data.id') { post_data }

# Same as above, but using a hash shortcut...
InertiaRails.merge(append: { data: 'id' }) { post_data }

# Multiple properties with different match fields
InertiaRails.merge(append: { 'users.data' => 'id', 'messages' => 'uuid', }) { complex_data }
```

Client-side, `router.reload({ only: ['messages'] })` fetches the new batch
and Inertia appends it to the existing `messages` array automatically.

**Reset on fresh visit:** Merge only appends during partial reloads. A full
page visit (navigation, `router.get`) replaces the prop entirely — no stale
accumulation across pages.

## Always Props

Included even in partial reloads (which normally only include
requested props). Use sparingly for data that must always be fresh.

```ruby
render inertia: {
  users: User.all.as_json,
  # Always included, even when client requests only: ['users']
  csrf: InertiaRails.always { form_authenticity_token },
  version: InertiaRails.always { Rails.application.config.version },
}
```

## Scroll Props

Scroll-aware props for infinite scroll. Combines with `<InfiniteScroll>` on the
client to automatically load more data as the user scrolls down.

**Check the project's pagy version** before writing pagination code — the API
changed significantly in v42. Check `Gemfile.lock` for the installed version.

```ruby
# Pagy v42+ syntax
class PostsController < ApplicationController
  include Pagy::Method

  def index
    pagy, posts = pagy(:offset, Post.order(created_at: :desc), limit: 20)
    # For cursor-based: pagy, posts = pagy(:keyset, Post.order(:id), limit: 20)

    render inertia: {
      posts: InertiaRails.scroll(pagy) { posts.as_json(only: [:id, :title, :body]) },
    }
  end
end

# Pagy pre-v42 syntax (if project uses older version)
class PostsController < ApplicationController
  include Pagy::Backend

  def index
    pagy, posts = pagy(Post.order(created_at: :desc), limit: 20)

    render inertia: {
      posts: InertiaRails.scroll(pagy) { posts.as_json(only: [:id, :title, :body]) },
    }
  end
end
```

React side with `<InfiniteScroll>`:
```tsx
import { InfiniteScroll } from '@inertiajs/react'

export default function Index({ posts }: Props) {
  return (
    <InfiniteScroll data="posts" loading={() => <PostsSkeleton />}>
      {posts.map(post => <PostCard key={post.id} post={post} />)}
    </InfiniteScroll>
  )
}

// Manual mode — "Load more" button instead of auto-scroll
export function IndexManual({ posts }: Props) {
  return (
    <InfiniteScroll
      data="posts"
      manual
      next={({ loading, fetch, hasMore }) =>
        hasMore && (
          <button onClick={fetch} disabled={loading}>
            {loading ? 'Loading...' : 'Load more'}
          </button>
        )
      }
    >
      {posts.map(post => <PostCard key={post.id} post={post} />)}
    </InfiniteScroll>
  )
}
```

**NEVER use `<WhenVisible>` for infinite scroll** — use `<InfiniteScroll>` which
handles page tracking, URL sync, and merge behavior automatically.

## Resetting Merge/Scroll Props

Merge and scroll props accumulate data across partial reloads. To discard the
accumulated state and start fresh **without a full page visit**, pass `reset`
on the client:

```tsx
// Fetch messages from scratch — clears the accumulated array first
router.reload({ only: ['messages'], reset: ['messages'] })
```

**Use when user changes filters / sort order: `reset` the prop so stale items are discarded.**

## Combining Prop Types

Prop helpers accept keyword arguments that layer behaviours together:

```ruby
render inertia: {
  # Deferred + merge — loads after initial render, then accumulates on subsequent reloads
  notifications: InertiaRails.defer(merge: true) {
    current_user.notifications.recent.as_json
  },

  # Deferred + merge in a group — multiple props fetched together, both accumulate
  posts: InertiaRails.defer(group: 'feed', merge: true) {
    @posts.as_json(only: [:id, :title, :body])
  },
  comments: InertiaRails.defer(group: 'feed', merge: true) {
    @comments.as_json(only: [:id, :post_id, :body])
  },

  # Optional + merge — only fetched on demand, appends to existing data
  activity_log: InertiaRails.optional(merge: true) {
    @activities.as_json
  },
}
```

The `merge: true` flag works on `defer`, `optional`, and `always`. It tells
Inertia to append results to the existing client-side array on partial reloads
instead of replacing it — the same behaviour as `InertiaRails.merge`, but
combined with another prop type.
