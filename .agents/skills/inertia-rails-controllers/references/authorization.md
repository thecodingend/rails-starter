# Authorization as Props

Pass permissions as props — the frontend decides what to **show**, the server
decides what to **allow**. Never check permissions client-side only.

## Controller Pattern

```ruby
def show
  @user = User.find(params[:id])
  render inertia: {
    user: @user.as_json(only: [:id, :name, :email]),
    can: {
      edit: allowed_to?(:edit?, @user),
      delete: allowed_to?(:destroy?, @user),
    },
  }
end
```

## Frontend Pattern

```tsx
export default function Show({ user, can }: Props) {
  return (
    <>
      <h1>{user.name}</h1>
      {can.edit && <Link href={`/users/${user.id}/edit`}>Edit</Link>}
      {can.delete && <DeleteButton userId={user.id} />}
    </>
  )
}
```

## Key Rules

- **Always enforce server-side** — `can` props control UI visibility, not access. The `update`/`destroy` actions must independently authorize.
- **Per-record, not global** — pass `can` per resource, not a blanket `isAdmin` flag. A user may edit their own profile but not others.
- **Default to Action Policy** — examples use `allowed_to?(:edit?, @user)` from [Action Policy](https://actionpolicy.evilmartians.io/). For projects already using Pundit (`policy(@user).edit?`) or CanCanCan (`can?(:edit, @user)`), use those instead.
