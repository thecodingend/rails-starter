# shadcn/ui Components for Inertia — Extended Reference

Additional component patterns adapted for Inertia.js + Rails.

## Table of Contents

- [Alert Dialog with Server Action](#alert-dialog-with-server-action)
- [Sheet (Slide-over Panel)](#sheet-slide-over-panel)
- [Tabs with URL State](#tabs-with-url-state)
- [Dropdown Menu with Actions](#dropdown-menu-with-actions)
- [Pagination](#pagination)
- [Search Input with Debounce](#search-input-with-debounce)
- [Checkbox and Switch in Forms](#checkbox-and-switch-in-forms)
- [Textarea in Forms](#textarea-in-forms)
- [Date Picker in Forms](#date-picker-in-forms)
- [Breadcrumbs with Link](#breadcrumbs-with-link)

---

## Alert Dialog with Server Action

Confirm before destructive server actions:

```tsx
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle,
  AlertDialogTrigger } from '@/components/ui/alert-dialog'
import { router } from '@inertiajs/react'

function DeleteUserButton({ userId }: { userId: number }) {
  return (
    <AlertDialog>
      <AlertDialogTrigger asChild>
        <Button variant="destructive">Delete</Button>
      </AlertDialogTrigger>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Delete user?</AlertDialogTitle>
          <AlertDialogDescription>This action cannot be undone.</AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>Cancel</AlertDialogCancel>
          <AlertDialogAction onClick={() => router.delete(`/users/${userId}`)}>
            Delete
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  )
}
```

## Sheet (Slide-over Panel)

```tsx
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from '@/components/ui/sheet'
import { Form } from '@inertiajs/react'

function CreateUserSheet() {
  return (
    <Sheet>
      <SheetTrigger asChild>
        <Button>New User</Button>
      </SheetTrigger>
      <SheetContent>
        <SheetHeader>
          <SheetTitle>Create User</SheetTitle>
        </SheetHeader>
        <Form method="post" action="/users">
          {({ errors, processing }) => (
            <div className="space-y-4 mt-4">
              <Input name="name" placeholder="Name" />
              {errors.name && <p className="text-sm text-destructive">{errors.name}</p>}
              <Button type="submit" disabled={processing}>Create</Button>
            </div>
          )}
        </Form>
      </SheetContent>
    </Sheet>
  )
}
```

## Tabs with URL State

Use Inertia navigation to persist tab state in the URL:

```tsx
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { router } from '@inertiajs/react'

function UserTabs({ activeTab, profile, activity }: Props) {
  return (
    <Tabs
      value={activeTab}
      onValueChange={(tab) => {
        router.get(`/users/${user.id}`, { tab }, { preserveState: true })
      }}
    >
      <TabsList>
        <TabsTrigger value="profile">Profile</TabsTrigger>
        <TabsTrigger value="activity">Activity</TabsTrigger>
      </TabsList>
      <TabsContent value="profile"><ProfileView data={profile} /></TabsContent>
      <TabsContent value="activity"><ActivityFeed data={activity} /></TabsContent>
    </Tabs>
  )
}
```

## Dropdown Menu with Actions

```tsx
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem,
  DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { router } from '@inertiajs/react'

function UserActions({ user }: { user: User }) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon"><MoreHorizontal /></Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent>
        <DropdownMenuItem onClick={() => router.visit(`/users/${user.id}/edit`)}>
          Edit
        </DropdownMenuItem>
        <DropdownMenuItem
          className="text-destructive"
          onClick={() => {
            if (confirm('Delete?')) router.delete(`/users/${user.id}`)
          }}
        >
          Delete
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
```

## Pagination

Server-driven pagination with Inertia navigation:

```tsx
import { Button } from '@/components/ui/button'
import { router } from '@inertiajs/react'

function Pagination({ currentPage, totalPages }: Props) {
  const goToPage = (page: number) => {
    router.get(window.location.pathname, { page }, { preserveState: true })
  }

  return (
    <div className="flex gap-2">
      <Button
        variant="outline"
        disabled={currentPage <= 1}
        onClick={() => goToPage(currentPage - 1)}
      >
        Previous
      </Button>
      <span className="flex items-center px-2">
        Page {currentPage} of {totalPages}
      </span>
      <Button
        variant="outline"
        disabled={currentPage >= totalPages}
        onClick={() => goToPage(currentPage + 1)}
      >
        Next
      </Button>
    </div>
  )
}
```

## Search Input with Debounce

```tsx
import { Input } from '@/components/ui/input'
import { router } from '@inertiajs/react'
import { useRef } from 'react'

function SearchInput({ initialValue }: { initialValue: string }) {
  const timeout = useRef<ReturnType<typeof setTimeout>>()

  const handleSearch = (value: string) => {
    clearTimeout(timeout.current)
    timeout.current = setTimeout(() => {
      router.get('/users', { search: value }, {
        preserveState: true,
        preserveScroll: true,
      })
    }, 300)
  }

  return (
    <Input
      defaultValue={initialValue}
      placeholder="Search users..."
      onChange={(e) => handleSearch(e.target.value)}
    />
  )
}
```

## Checkbox and Switch in Forms

```tsx
import { Checkbox } from '@/components/ui/checkbox'
import { Switch } from '@/components/ui/switch'

<Form method="post" action="/settings">
  {({ errors }) => (
    <>
      <div className="flex items-center gap-2">
        <Checkbox id="notifications" name="notifications" defaultChecked />
        <Label htmlFor="notifications">Email notifications</Label>
      </div>

      <div className="flex items-center gap-2">
        <Switch id="dark_mode" name="dark_mode" />
        <Label htmlFor="dark_mode">Dark mode</Label>
      </div>
    </>
  )}
</Form>
```

## Textarea in Forms

```tsx
import { Textarea } from '@/components/ui/textarea'

<Form method="post" action="/posts">
  {({ errors }) => (
    <>
      <Textarea name="body" rows={6} placeholder="Write your post..." />
      {errors.body && <p className="text-sm text-destructive">{errors.body}</p>}
    </>
  )}
</Form>
```

## Date Picker in Forms

Use a hidden input to submit the selected date value:

```tsx
import { Calendar } from '@/components/ui/calendar'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { useState } from 'react'

function DateField({ name, defaultValue }: { name: string; defaultValue?: string }) {
  const [date, setDate] = useState<Date | undefined>(
    defaultValue ? new Date(defaultValue) : undefined
  )

  return (
    <>
      <input type="hidden" name={name} value={date?.toISOString() ?? ''} />
      <Popover>
        <PopoverTrigger asChild>
          <Button variant="outline">
            {date ? date.toLocaleDateString() : 'Pick a date'}
          </Button>
        </PopoverTrigger>
        <PopoverContent>
          <Calendar mode="single" selected={date} onSelect={setDate} />
        </PopoverContent>
      </Popover>
    </>
  )
}
```

## Breadcrumbs with Link

```tsx
import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList,
  BreadcrumbSeparator } from '@/components/ui/breadcrumb'
import { Link } from '@inertiajs/react'

function PageBreadcrumbs({ items }: { items: { label: string; href?: string }[] }) {
  return (
    <Breadcrumb>
      <BreadcrumbList>
        {items.map((item, i) => (
          <BreadcrumbItem key={i}>
            {item.href ? (
              <BreadcrumbLink asChild>
                <Link href={item.href}>{item.label}</Link>
              </BreadcrumbLink>
            ) : (
              <span>{item.label}</span>
            )}
            {i < items.length - 1 && <BreadcrumbSeparator />}
          </BreadcrumbItem>
        ))}
      </BreadcrumbList>
    </Breadcrumb>
  )
}
```
