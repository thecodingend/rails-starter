# Rails Starter

Starter template for new Rails projects.

## Start a New Project

1. Clone this repository for the new project.
2. Change the default Git remote to the new project repository:

```sh
git remote set-url origin git@github.com:YOUR_USER_OR_ORG/YOUR_NEW_REPO.git
git remote -v
```

3. Start the app:

```sh
docker compose up -d
bin/rails db:create 
# or if db already exists 
# bin/rails db:prepare
bin/dev
```

## Required Skills

Install the project skills:

```sh
npx skills add inertia-rails/skills
npx skills add pbakaus/impeccable
```

References:

- [inertia-rails/skills](https://github.com/inertia-rails/skills)
- [impeccable](https://impeccable.style/)
