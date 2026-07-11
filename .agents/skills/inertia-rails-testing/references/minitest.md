# Minitest Assertions for Inertia Rails

## Setup

```ruby
# test/test_helper.rb
require 'inertia_rails/minitest'
```

## Assertions

| Assertion | Purpose |
|-----------|---------|
| `assert_inertia_response` | Verify Inertia response |
| `assert_inertia_component('path')` | Check component name |
| `assert_inertia_props(key: value)` | Partial props match |
| `assert_inertia_props_equal(key: value)` | Exact props match |
| `assert_no_inertia_prop(:key)` | Assert prop absent |
| `assert_inertia_flash(key: value)` | Partial flash match |
| `assert_inertia_flash_equal(key: value)` | Exact flash match |
| `assert_no_inertia_flash(:key)` | Assert flash absent |
| `assert_inertia_deferred_props(:key)` | Check deferred props |

## Example

```ruby
test 'renders users index' do
  get events_path

  assert_inertia_response
  assert_inertia_component 'events/index'
  assert_inertia_props title: 'Rails World'
  assert_no_inertia_prop :secret
end
```

Partial reload and deferred prop helpers (`inertia_reload_only`,
`inertia_reload_except`, `inertia_load_deferred_props`) work the
same in both RSpec and Minitest.
