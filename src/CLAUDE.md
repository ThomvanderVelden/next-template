# Source Directory

## App Router Structure

All routes use the Next.js 16 App Router:
- `app/page.tsx` - Home page
- `app/layout.tsx` - Root layout with fonts
- `app/api/` - API route handlers

## Authentication

Use the auth client in client components:

```typescript
"use client";
import { authClient } from "@/lib/auth-client";

// Get session
const { data: session } = authClient.useSession();

// Sign up
await authClient.signUp.email({
  email: "user@example.com",
  password: "password",
  name: "User Name",
});

// Sign in
await authClient.signIn.email({
  email: "user@example.com",
  password: "password",
});

// Sign out
await authClient.signOut();
```

For server components/actions, use the auth instance directly:

```typescript
import { auth } from "@/lib/auth";
import { headers } from "next/headers";

const session = await auth.api.getSession({
  headers: await headers(),
});
```

## Component Patterns

- Use `"use client"` directive only when needed (interactivity, hooks)
- Prefer Server Components for data fetching
- Use `@/` path alias for imports
