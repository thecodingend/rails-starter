# Decision Trees

Quick flowcharts for common Inertia.js + Rails decisions.

## "I need data in my component"

```
Is this data specific to this page?
├── YES → Controller prop (render inertia: props: { ... })
│   └── Is it expensive to compute?
│       ├── >500ms → InertiaRails.defer { ... }
│       ├── <100ms → Regular prop (defer overhead not worth it)
│       └── 100-500ms → Judgment call — defer if page has fast props to show first
├── NO, it's needed on every page → inertia_share
└── NO, it's from an external API → Dedicated API endpoint
    (Stripe status, third-party webhook, etc.)
```

## "I need to update data"

```
Is this a form submission (create/update/delete)?
├── YES → <Form> component + controller action + redirect
│   └── Need programmatic control? → useForm hook instead
└── NO
    ├── Need to refresh page data? → router.reload({ only: [...] })
    ├── Need real-time updates?
    │   ├── Core feature (chat, live feed)? → ActionCable + router.reload
    │   └── MVP/prototype or no ActionCable yet? → usePoll(interval, { only: [...] })
    ├── Need optimistic UI? → useState for optimistic + router.post with onError rollback
    └── Need search/filter? → router.visit with query params (preserveState)
```

## "I need state in my component"

```
Where does the data come from?
├── Server → It's a prop, not state
├── User interaction (modal open, dropdown) → useState
├── Form data → <Form> component (or useForm for complex cases)
├── Shared across pages (auth) → usePage().props (from inertia_share)
└── Multiple components need it → Lift to closest common parent as prop
    └── Still unwieldy? → Consider React Context (rare in Inertia apps)
```

## "Should I prefetch / poll / defer / use ActionCable?"

```
PREFETCH — preload page data before navigation:
├── Frequently visited page (dashboard, main nav)? → YES, prefetch="mount"
├── Likely next click (nav links)? → YES, prefetch (hover, default)
├── Data changes constantly per user? → NO — cache will be stale immediately
├── Page requires POST data to load? → NO — prefetch only works with GET
└── Multiple pages share data? → Use cacheTags for coordinated invalidation

POLL — auto-refresh data on an interval:
├── Dashboard counters, queue status, leaderboard? → YES, usePoll with only: [...]
├── Query is expensive (>1s)? → NO — use ActionCable push instead
├── Updates are rare (<1/hour)? → NO — manual refresh or ActionCable
├── Need real-time (<1s latency)? → NO — use ActionCable/WebSockets
└── Need user control? → { autoStart: false } + start/stop

DEFER — load expensive data after initial render:
├── Query >500ms? → YES, always defer
├── Query <100ms? → NO — defer overhead not worth it
├── Data critical for initial render (form defaults, auth)? → NO — regular prop
└── 100-500ms? → Defer if page has fast props to show first

ACTIONCABLE — server pushes updates to client:
├── Core real-time feature (chat, live feed, collaboration)? → YES
├── Updates must arrive <1s after change? → YES
├── Multiple users see the same resource? → YES — broadcast on change
├── Only current user's data, low frequency? → usePoll is simpler
└── Pattern: ActionCable receives event → router.reload({ only: [...] })
```

## "I need to navigate"

```
Is this a link the user clicks?
├── YES → <Link href={...}> (with prefetch for common destinations)
├── NO, programmatic after action → router.visit / router.get
├── External URL from server? → inertia_location (CRITICAL — not redirect_to)
├── External URL from client? → window.location.href
└── Need to update URL params? → router.visit with preserveState
```

## "I need to show a notification"

```
Is it a one-time message (success, error)?
├── YES → Rails flash + usePage().flash
│   └── Need custom keys beyond notice/alert? → config.flash_keys
├── Need it to persist across navigations? → inertia_share (shared prop)
└── Client-side only (no server)? → router.flash('key', 'value')
```

## "I need to redirect after a mutation"

```
Is the destination inside the Inertia app?
├── YES → redirect_to path (standard Rails redirect)
│   └── With flash? → redirect_to path, notice: "Done!"
└── NO, external URL (Stripe, OAuth, etc.)
    └── inertia_location url (returns 409 + X-Inertia-Location header)
        NEVER: redirect_to external_url (breaks Inertia)
```
