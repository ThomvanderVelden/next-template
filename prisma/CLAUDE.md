# Prisma Directory

## Schema

The `schema.prisma` file defines all database models. Current models:
- `User` - User accounts
- `Session` - Auth sessions
- `Account` - OAuth/credential accounts
- `Verification` - Email verification tokens

## Configuration

Prisma 7 uses `prisma.config.ts` for database connection:
- Connection string comes from `DATABASE_URL` env var
- Uses `@prisma/adapter-pg` for PostgreSQL

## Workflow

### Adding a new model

1. Add model to `schema.prisma`
2. Generate client: `pnpm db:generate`
3. Create migration: `pnpm db:migrate`

### Updating existing model

1. Modify model in `schema.prisma`
2. Generate client: `pnpm db:generate`
3. Create migration: `pnpm db:migrate`

### Quick sync (dev only)

Use `pnpm db:push` to sync schema without migration history.

## Conventions

- Model names: PascalCase singular (e.g., `User`, `Session`)
- Field names: camelCase (e.g., `createdAt`, `userId`)
- Use `@@map("lowercase")` for table names
- Always add `createdAt` and `updatedAt` timestamps
- Use `@id` with String type for UUIDs (Better Auth generates IDs)
