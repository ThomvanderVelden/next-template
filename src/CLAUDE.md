# Next.js 16 Frontend Development Best Practices

This guide provides comprehensive best practices for building modern Next.js 16 applications with React 19, TypeScript, and shadcn/ui. Use this as the definitive reference for all frontend development in this repository.

## Table of Contents

1. [Developer Checklist](#developer-checklist)
2. [Next.js 16 App Router Architecture](#nextjs-16-app-router-architecture)
3. [React 19 Component Architecture](#react-19-component-architecture)
4. [Server Components & Server Actions](#server-components--server-actions)
5. [Form Handling & Validation](#form-handling--validation)
6. [Authentication with Better Auth](#authentication-with-better-auth)
7. [shadcn/ui Component Development](#shadcnui-component-development)
8. [Performance Optimization](#performance-optimization)
9. [Accessibility Standards](#accessibility-standards)
10. [SEO Implementation](#seo-implementation)
11. [TypeScript Best Practices](#typescript-best-practices)
12. [Development Workflow](#development-workflow)

---

## Developer Checklist

### Before Starting Any Feature

Use this checklist to ensure you're following all essential best practices:

#### Architecture & Planning
- [ ] Review existing codebase patterns and conventions
- [ ] Choose appropriate rendering strategy (Static/SSR/ISR)
- [ ] Determine Server vs Client Component boundaries
- [ ] Plan data fetching strategy and caching approach
- [ ] Consider mobile-first responsive design from the start

#### TypeScript & Code Quality
- [ ] TypeScript strict mode enabled
- [ ] All props have proper TypeScript interfaces
- [ ] No `any` types used (use `unknown` if needed)
- [ ] Return types defined for all functions
- [ ] Imports organized properly (external, internal, types, styles)

#### Component Development
- [ ] Server Components used by default
- [ ] Client Components only when interactivity needed
- [ ] Component has single, clear responsibility
- [ ] Component is reusable and composable

#### Forms & Data Mutations
- [ ] Server Actions implemented for all mutations
- [ ] Progressive enhancement (works without JavaScript)
- [ ] Zod schema created in `lib/validations/` (source of truth)
- [ ] Type inferred from schema: `type X = z.infer<typeof xSchema>`
- [ ] Same schema used for client AND server validation
- [ ] Schema exported from `lib/validations/index.ts`
- [ ] Proper error handling and user feedback
- [ ] Loading/pending states implemented

#### Performance
- [ ] Images use Next.js Image component with proper sizing
- [ ] Fonts optimized with next/font
- [ ] Heavy components lazy loaded with dynamic imports
- [ ] Proper caching strategy implemented

#### Accessibility
- [ ] Semantic HTML elements used
- [ ] ARIA labels and roles implemented correctly
- [ ] Keyboard navigation works properly
- [ ] Color contrast meets WCAG 2.1 AA (4.5:1)
- [ ] Touch targets at least 44x44 pixels

#### Security
- [ ] All inputs validated server-side
- [ ] User inputs sanitized before database operations
- [ ] Authentication implemented for protected actions
- [ ] Authorization checks for data access
- [ ] No sensitive data exposed in client code

#### shadcn/ui Components
- [ ] Extend existing shadcn components, don't rebuild
- [ ] Radix UI primitives used as foundation
- [ ] CVA used for variant management
- [ ] Tailwind classes used exclusively
- [ ] Dark mode support through CSS variables

#### Before Commit
- [ ] Biome formatting applied (`pnpm lint:fix`)
- [ ] TypeScript compilation successful
- [ ] No console.logs or debugger statements

---

## Next.js 16 App Router Architecture

### Core Principles

- **Server-first**: Leverage Server Components by default for optimal performance
- **Progressive Enhancement**: Ensure forms and navigation work without JavaScript
- **Type Safety**: Use TypeScript strict mode throughout the application
- **Turbopack**: Use Turbopack for fast development builds

### Current Project Structure

```
src/
├── app/                    # Next.js App Router pages and layouts
│   ├── api/                # API routes
│   │   └── auth/
│   │       └── [...all]/
│   │           └── route.ts  # Better Auth API handler
│   ├── sign-in/
│   │   └── page.tsx        # Sign in page
│   ├── sign-up/
│   │   └── page.tsx        # Sign up page
│   ├── globals.css         # Global styles (Tailwind 4)
│   ├── layout.tsx          # Root layout
│   └── page.tsx            # Home page
│
├── components/
│   ├── ui/                 # shadcn/ui components
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   ├── input.tsx
│   │   └── label.tsx
│   └── header.tsx          # App header with auth
│
├── lib/
│   ├── auth.ts             # Better Auth server instance
│   ├── auth-client.ts      # Better Auth client
│   ├── prisma.ts           # Prisma client singleton
│   ├── utils.ts            # Utility functions (cn, etc.)
│   └── validations/        # Zod schemas (source of truth for types)
│       ├── index.ts        # Re-exports all schemas
│       ├── auth.ts         # Auth schemas (SignInInput, SignUpInput, etc.)
│       └── common.ts       # Reusable patterns (pagination, ActionResult)
│
├── types/                  # TypeScript types
│   ├── index.ts            # App types + re-exports
│   └── database.ts         # Prisma-derived types for complex queries
│
└── generated/
    └── prisma/             # Generated Prisma client
        └── client.ts

prisma/
├── schema.prisma           # Database schema
└── migrations/             # Database migrations

prisma.config.ts            # Prisma 7 configuration (root)
```

### Routing Patterns

**Layout Patterns**
- Use layouts for shared UI across multiple pages
- Implement nested layouts for section-specific navigation

**Route Groups**
- Organize routes logically without affecting URL structure: `(marketing)`, `(app)`
- Create separate layouts for different sections

### Rendering Strategies

```tsx
// Static Generation (Default) - cache: 'force-cache'
export const dynamic = 'force-static'

// Server-Side Rendering - cache: 'no-store'
export const dynamic = 'force-dynamic'

// Incremental Static Regeneration
export default async function Page() {
  const data = await fetch('https://api.example.com/data', {
    next: { revalidate: 60 } // Revalidate every 60 seconds
  })
  return <div>{/* ... */}</div>
}
```

### Next.js 16 Configuration

```typescript
// next.config.ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Enable React strict mode
  reactStrictMode: true,

  // Image optimization
  images: {
    formats: ['image/avif', 'image/webp'],
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'example.com'
      }
    ]
  },

  // Experimental features (Next.js 16)
  experimental: {
    // Partial Prerendering (if needed)
    ppr: true,
  },
};

export default nextConfig;
```

---

## React 19 Component Architecture

### Component Development Rules

**Component-First Thinking**
- Every UI piece should be reusable and composable
- Extract components when you see repeated patterns (DRY principle)
- Components should have a single, clear responsibility
- Prefer composition over inheritance

**Mobile-First Responsive Design**
- Always design for mobile screens first (320px+)
- Use responsive breakpoints: sm (640px), md (768px), lg (1024px), xl (1280px), 2xl (1536px)
- Touch targets must be at least 44x44 pixels

### Component Organization

**Server Components (Default)**
- Use for data fetching and static UI
- No client-side JavaScript bundle
- Cannot use hooks or event handlers

**Client Components**
- Use 'use client' directive at the top
- For interactivity, hooks, and event handlers
- Keep client boundaries small and low in the tree

```tsx
// Server Component - data fetching
export default async function ProductList() {
  const products = await fetch('...').then(r => r.json())
  return <ul>{products.map(p => <li key={p.id}>{p.name}</li>)}</ul>
}

// Client Component - interactivity
'use client'
import { useState } from 'react'

export function Counter() {
  const [count, setCount] = useState(0)
  return <button onClick={() => setCount(count + 1)}>Count: {count}</button>
}
```

### React 19 Features

**useActionState Hook**
For managing form state with Server Actions:

```tsx
'use client'
import { useActionState } from 'react'
import { createUser } from '@/app/actions'

const initialState = { message: '' }

export function SignupForm() {
  const [state, formAction, isPending] = useActionState(createUser, initialState)

  return (
    <form action={formAction}>
      <input name="email" type="email" required />
      <p aria-live="polite">{state?.message}</p>
      <button type="submit" disabled={isPending}>
        {isPending ? 'Submitting...' : 'Sign Up'}
      </button>
    </form>
  )
}
```

**useFormStatus Hook**
For tracking form submission state in child components:

```tsx
'use client'
import { useFormStatus } from 'react-dom'

export function SubmitButton({ children }: { children: React.ReactNode }) {
  const { pending } = useFormStatus()
  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Submitting...' : children}
    </button>
  )
}
```

### State Management

**Priority Order**: Server Components > URL State > useState > useReducer > Context

```tsx
// Server State - Preferred for data fetching
export default async function Page() {
  const data = await fetch('...').then(r => r.json())
  return <div>{data.title}</div>
}

// Client State - Local UI state
'use client'
export function ShoppingCart() {
  const [items, setItems] = useState<CartItem[]>([])
  return <div>{/* ... */}</div>
}
```

---

## Server Components & Server Actions

### Server Component Rules

**When to Use Server Components**
- Default choice for all components unless interactivity is needed
- Use for data fetching, accessing backend resources directly
- Use when component only renders static content
- Use when you need to reduce client-side JavaScript bundle

**When to Use Client Components**
- Component needs useState, useEffect, or other React hooks
- Component needs event handlers (onClick, onChange, etc.)
- Component needs browser-only APIs (localStorage, geolocation, etc.)
- Component uses third-party libraries that depend on browser APIs

### Data Fetching Patterns

```tsx
// Parallel fetching - use Promise.all
const [users, posts] = await Promise.all([fetchUsers(), fetchPosts()])

// Sequential fetching - when data depends on previous result
const user = await fetchUser(id)
const posts = await fetchUserPosts(user.id)

// Streaming with Suspense
export default function Page() {
  return (
    <>
      <Header />
      <Suspense fallback={<Skeleton />}>
        <SlowComponent />
      </Suspense>
    </>
  )
}
```

### Dynamic Route Parameters (Next.js 16)

In Next.js 16, dynamic route parameters are now async:

```tsx
// app/posts/[slug]/page.tsx
export default async function Page({
  params,
}: {
  params: Promise<{ slug: string }>
}) {
  const { slug } = await params
  return <div>Post: {slug}</div>
}
```

### Accessing Headers and Cookies

```tsx
// Headers and cookies are now async in Next.js 16
import { cookies, headers } from 'next/headers'

export default async function Page() {
  const headersList = await headers()
  const cookieStore = await cookies()

  const authHeader = headersList.get('authorization')
  const theme = cookieStore.get('theme')

  return <div>...</div>
}
```

### Server Actions

```tsx
// Basic Server Action with validation
'use server'
import { z } from 'zod'
import { revalidatePath } from 'next/cache'

const schema = z.object({
  name: z.string().min(2),
  email: z.string().email()
})

export async function createUser(prevState: any, formData: FormData) {
  const validated = schema.safeParse({
    name: formData.get('name'),
    email: formData.get('email')
  })

  if (!validated.success) {
    return { errors: validated.error.flatten().fieldErrors }
  }

  try {
    await prisma.user.create({ data: validated.data })
    revalidatePath('/users')
    return { success: true }
  } catch (error) {
    return { error: 'Failed to create user' }
  }
}
```

---

## Form Handling & Validation

### Form Implementation Patterns

```tsx
// Basic Form with Server Action (works without JS)
import Form from 'next/form'
import { createPost } from '@/app/actions'

export default function NewPost() {
  return (
    <Form action={createPost}>
      <label htmlFor="title">Title</label>
      <input id="title" name="title" required />
      <button type="submit">Create Post</button>
    </Form>
  )
}

// Form with State Management (useActionState)
'use client'
import { useActionState } from 'react'

export function SignupForm() {
  const [state, formAction, pending] = useActionState(createUser, { errors: {} })

  return (
    <form action={formAction}>
      <input name="email" aria-describedby={state?.errors?.email ? 'email-error' : undefined} />
      {state?.errors?.email && <p id="email-error">{state.errors.email}</p>}

      <button type="submit" disabled={pending}>
        {pending ? 'Submitting...' : 'Sign Up'}
      </button>
    </form>
  )
}
```

### Validation Pattern

```tsx
// 1. Shared Zod Schema (lib/validations/user.ts)
import { z } from 'zod'

export const userSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).regex(/[A-Z]/).regex(/[0-9]/)
})

// 2. Server Action (REQUIRED)
'use server'
export async function createUser(prevState: any, formData: FormData) {
  const validated = userSchema.safeParse(Object.fromEntries(formData))
  if (!validated.success) {
    return { errors: validated.error.flatten().fieldErrors }
  }
  await prisma.user.create({ data: validated.data })
  return { success: true }
}
```

---

## E2E Type Safety with Zod

This template uses **Zod schemas as the single source of truth** for types throughout the application. This is the modern industry-standard approach used by tRPC, Next.js, and most production apps.

### Why This Approach?

```
┌─────────────────────────────────────────────────────────────────┐
│                    SINGLE SOURCE OF TRUTH                       │
│                                                                 │
│   Zod Schema ──→ TypeScript Type (inferred automatically)       │
│       │                                                         │
│       ├──→ Client-side validation (same rules)                  │
│       ├──→ Server-side validation (same rules)                  │
│       ├──→ Form state types (same shape)                        │
│       └──→ API response types (same shape)                      │
│                                                                 │
│   Change schema once → TypeScript errors everywhere affected    │
└─────────────────────────────────────────────────────────────────┘
```

### Type Locations

| Location | Purpose | When to Use |
|----------|---------|-------------|
| `lib/validations/*.ts` | Zod schemas + inferred types | Forms, API input/output, any data shape |
| `types/database.ts` | Prisma-derived types | Complex queries with relations |
| `types/index.ts` | App-specific types | Route params, API wrappers |

### Adding a New Feature (Complete Workflow)

When adding a new feature with a database table, follow this exact order:

#### Step 1: Database Schema (Prisma)

```prisma
// prisma/schema.prisma
model Post {
  id        String   @id @default(cuid())
  title     String
  content   String?
  published Boolean  @default(false)
  authorId  String
  author    User     @relation(fields: [authorId], references: [id], onDelete: Cascade)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([authorId])
  @@map("post")
}
```

Then run:
```bash
pnpm db:generate   # Generate Prisma client types
pnpm db:push       # Push to database (dev)
```

#### Step 2: Validation Schemas (Zod)

```typescript
// lib/validations/post.ts
import { z } from "zod/v4";

// Input schema for creating
export const createPostSchema = z.object({
  title: z.string().min(1, "Title is required").max(200),
  content: z.string().optional(),
});
export type CreatePostInput = z.infer<typeof createPostSchema>;

// Input schema for updating (all fields optional)
export const updatePostSchema = createPostSchema.partial();
export type UpdatePostInput = z.infer<typeof updatePostSchema>;

// Output schema (what API returns)
export const postSchema = z.object({
  id: z.string(),
  title: z.string(),
  content: z.string().nullable(),
  published: z.boolean(),
  authorId: z.string(),
  createdAt: z.date(),
  updatedAt: z.date(),
});
export type Post = z.infer<typeof postSchema>;

// With author (for lists)
export const postWithAuthorSchema = postSchema.extend({
  author: z.object({
    id: z.string(),
    name: z.string(),
    image: z.string().nullable(),
  }),
});
export type PostWithAuthor = z.infer<typeof postWithAuthorSchema>;
```

Export from index:
```typescript
// lib/validations/index.ts
export * from "./auth";
export * from "./common";
export * from "./post";  // Add this line
```

#### Step 3: Database Types (if needed)

Only needed for complex Prisma queries with relations:

```typescript
// types/database.ts
export type PostWithAuthor = Prisma.PostGetPayload<{
  include: { author: { select: { id: true; name: true; image: true } } };
}>;

export const postWithAuthorInclude = {
  author: { select: { id: true, name: true, image: true } },
} as const satisfies Prisma.PostInclude;
```

#### Step 4: Server Action

```typescript
// lib/actions/post.ts
"use server";

import { revalidatePath } from "next/cache";
import { headers } from "next/headers";
import { auth } from "@/lib/auth";
import prisma from "@/lib/prisma";
import {
  createPostSchema,
  type CreatePostInput,
  type ActionResult,
} from "@/lib/validations";

export async function createPost(
  input: CreatePostInput
): Promise<ActionResult<{ id: string }>> {
  // 1. Auth check
  const session = await auth.api.getSession({ headers: await headers() });
  if (!session?.user) {
    return { success: false, message: "Unauthorized" };
  }

  // 2. Validate with SAME schema as client
  const result = createPostSchema.safeParse(input);
  if (!result.success) {
    return {
      success: false,
      errors: result.error.flatten().fieldErrors as Record<string, string[]>,
    };
  }

  // 3. Database operation
  try {
    const post = await prisma.post.create({
      data: {
        ...result.data,
        authorId: session.user.id,
      },
    });

    revalidatePath("/posts");
    return { success: true, data: { id: post.id } };
  } catch (error) {
    return { success: false, message: "Failed to create post" };
  }
}
```

#### Step 5: Client Component (Form)

```tsx
// app/posts/new/page.tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createPostSchema, type CreatePostInput } from "@/lib/validations";
import { createPost } from "@/lib/actions/post";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export default function NewPostPage() {
  const router = useRouter();
  const [formData, setFormData] = useState<CreatePostInput>({
    title: "",
    content: "",
  });
  const [errors, setErrors] = useState<Partial<Record<keyof CreatePostInput, string>>>({});
  const [loading, setLoading] = useState(false);

  function handleChange(field: keyof CreatePostInput, value: string) {
    setFormData((prev) => ({ ...prev, [field]: value }));
    if (errors[field]) {
      setErrors((prev) => ({ ...prev, [field]: undefined }));
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setErrors({});

    // Client validation with SAME schema
    const validation = createPostSchema.safeParse(formData);
    if (!validation.success) {
      const fieldErrors: Partial<Record<keyof CreatePostInput, string>> = {};
      for (const issue of validation.error.issues) {
        const field = issue.path[0] as keyof CreatePostInput;
        fieldErrors[field] = issue.message;
      }
      setErrors(fieldErrors);
      return;
    }

    setLoading(true);
    const result = await createPost(validation.data);
    setLoading(false);

    if (result.success) {
      router.push("/posts");
    } else if (result.errors) {
      setErrors(result.errors as Partial<Record<keyof CreatePostInput, string>>);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="title">Title</Label>
        <Input
          id="title"
          value={formData.title}
          onChange={(e) => handleChange("title", e.target.value)}
          aria-invalid={!!errors.title}
          aria-describedby={errors.title ? "title-error" : undefined}
        />
        {errors.title && (
          <p id="title-error" className="text-sm text-red-500">{errors.title}</p>
        )}
      </div>
      <Button type="submit" disabled={loading}>
        {loading ? "Creating..." : "Create Post"}
      </Button>
    </form>
  );
}
```

#### Step 6: Server Component (List)

```tsx
// app/posts/page.tsx
import prisma from "@/lib/prisma";
import { postWithAuthorInclude } from "@/types";
import type { PostWithAuthor } from "@/lib/validations";

export default async function PostsPage() {
  const posts = await prisma.post.findMany({
    include: postWithAuthorInclude,
    orderBy: { createdAt: "desc" },
  });

  return (
    <ul className="space-y-4">
      {posts.map((post) => (
        <li key={post.id}>
          <h2>{post.title}</h2>
          <p>by {post.author.name}</p>
        </li>
      ))}
    </ul>
  );
}
```

### Quick Reference: Type Imports

```typescript
// Always import schemas AND types from validations
import {
  createPostSchema,      // For validation
  type CreatePostInput,  // For typing
  type Post,             // For API responses
} from "@/lib/validations";

// Import Prisma query helpers from types
import { postWithAuthorInclude } from "@/types";

// Import Prisma-specific types when needed
import type { PostWithAuthor } from "@/types";
```

### Validation Schema Patterns

```typescript
// Required field with constraints
title: z.string().min(1, "Required").max(200, "Too long")

// Optional field
content: z.string().optional()

// Nullable (can be null from DB)
image: z.string().nullable()

// Email validation
email: z.email("Invalid email")

// Password with rules
password: z
  .string()
  .min(8, "Min 8 characters")
  .regex(/[A-Z]/, "Need uppercase")
  .regex(/[0-9]/, "Need number")

// Enum
status: z.enum(["draft", "published", "archived"])

// Array
tags: z.array(z.string()).min(1, "Need at least one tag")

// Nested object
author: z.object({
  id: z.string(),
  name: z.string(),
})

// Partial (all fields optional) - for updates
updateSchema = createSchema.partial()

// Pick specific fields
publicSchema = fullSchema.pick({ id: true, name: true })

// Extend existing schema
withTimestamps = baseSchema.extend({
  createdAt: z.date(),
  updatedAt: z.date(),
})
```

---

## Authentication with Better Auth

This template uses **Better Auth** for authentication, providing a simple and type-safe authentication solution.

### Server Configuration

```typescript
// lib/auth.ts
import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";
import { prisma } from "./prisma";

export const auth = betterAuth({
  database: prismaAdapter(prisma, {
    provider: "postgresql",
  }),
  emailAndPassword: {
    enabled: true,
  },
});
```

### Client Configuration

```typescript
// lib/auth-client.ts
"use client";

import { createAuthClient } from "better-auth/react";

export const authClient = createAuthClient();
```

### API Route Handler

```typescript
// app/api/auth/[...all]/route.ts
import { auth } from "@/lib/auth";
import { toNextJsHandler } from "better-auth/next-js";

export const { GET, POST } = toNextJsHandler(auth);
```

### Using Authentication in Components

**Client Component with Session**
```tsx
'use client'
import { authClient } from "@/lib/auth-client";

export function UserProfile() {
  const { data: session, isPending } = authClient.useSession();

  if (isPending) return <div>Loading...</div>;
  if (!session) return <div>Not logged in</div>;

  return <div>Welcome, {session.user.email}!</div>;
}
```

**Sign In/Sign Up**
```tsx
'use client'
import { authClient } from "@/lib/auth-client";

// Sign in with email/password
const { error } = await authClient.signIn.email({
  email,
  password,
});

// Sign up with email/password
const { error } = await authClient.signUp.email({
  email,
  password,
  name,
});

// Sign out
await authClient.signOut();
```

### Protected Routes Pattern

```tsx
// Server Component - check auth
import { auth } from "@/lib/auth";
import { headers } from "next/headers";
import { redirect } from "next/navigation";

export default async function ProtectedPage() {
  const session = await auth.api.getSession({
    headers: await headers(),
  });

  if (!session) {
    redirect("/sign-in");
  }

  return <div>Protected content for {session.user.email}</div>;
}
```

---

## shadcn/ui Component Development

### Core Principles

- Build on Radix UI primitives for accessibility
- Use Tailwind CSS with design tokens
- Implement proper TypeScript interfaces
- Support dark mode through CSS variables
- Create composable, reusable components

### shadcn/ui Component Pattern

```tsx
// Button component with CVA variants (current implementation)
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import type * as React from "react";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive: "bg-destructive text-white hover:bg-destructive/90",
        outline: "border bg-background shadow-xs hover:bg-accent",
        secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-9 px-4 py-2",
        sm: "h-8 rounded-md gap-1.5 px-3",
        lg: "h-10 rounded-md px-6",
        icon: "size-9",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);

function Button({
  className,
  variant = "default",
  size = "default",
  asChild = false,
  ...props
}: React.ComponentProps<"button"> &
  VariantProps<typeof buttonVariants> & {
    asChild?: boolean;
  }) {
  const Comp = asChild ? Slot : "button";

  return (
    <Comp
      className={cn(buttonVariants({ variant, size, className }))}
      {...props}
    />
  );
}

export { Button, buttonVariants };
```

### Compound Component Pattern

```tsx
// Card compound component
const Card = ({ className, ...props }: React.ComponentProps<"div">) => (
  <div className={cn("rounded-xl border bg-card shadow", className)} {...props} />
);

const CardHeader = ({ className, ...props }: React.ComponentProps<"div">) => (
  <div className={cn("flex flex-col space-y-1.5 p-6", className)} {...props} />
);

const CardTitle = ({ className, ...props }: React.ComponentProps<"div">) => (
  <div className={cn("font-semibold leading-none tracking-tight", className)} {...props} />
);

const CardContent = ({ className, ...props }: React.ComponentProps<"div">) => (
  <div className={cn("p-6 pt-0", className)} {...props} />
);

export { Card, CardHeader, CardTitle, CardContent };
```

---

## Performance Optimization

### Core Web Vitals Targets

- **TTFB** (Time to First Byte): < 200ms
- **FCP** (First Contentful Paint): < 1s
- **LCP** (Largest Contentful Paint): < 2.5s
- **CLS** (Cumulative Layout Shift): < 0.1
- **INP** (Interaction to Next Paint): < 200ms

### Performance Code Examples

```tsx
// Image - Always use Next.js Image
import Image from 'next/image'
<Image
  src="/img.jpg"
  alt="Alt text"
  width={800}
  height={600}
  sizes="(max-width: 768px) 100vw, 50vw"
  priority={false}
  quality={85}
/>

// Font - Use next/font (current implementation)
import { Geist, Geist_Mono } from 'next/font/google'

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

// Dynamic Imports - Code splitting
import dynamic from 'next/dynamic'
const Chart = dynamic(() => import('@/components/Chart'), {
  loading: () => <Skeleton />,
  ssr: false
})

// Caching Strategies
const data = await fetch('...', { cache: 'force-cache' }) // Static
const data = await fetch('...', { cache: 'no-store' }) // Dynamic
const data = await fetch('...', { next: { revalidate: 60 } }) // ISR
const data = await fetch('...', { next: { tags: ['posts'] } }) // Tag-based
```

---

## Accessibility Standards

### WCAG 2.1 AA Requirements

- Use semantic HTML (article, nav, header, main, section)
- Every image must have alt text
- Proper heading hierarchy (h1 > h2 > h3, no skipping)
- Color contrast ratio 4.5:1 for text, 3:1 for large text
- Touch targets minimum 44x44 pixels
- All interactive elements keyboard accessible

```tsx
// Accessible form input
<div className="space-y-2">
  <Label htmlFor="email">Email</Label>
  <Input
    id="email"
    type="email"
    aria-describedby={error ? "email-error" : undefined}
    aria-invalid={error ? true : undefined}
    required
  />
  {error && (
    <p id="email-error" className="text-sm text-destructive" role="alert">
      {error}
    </p>
  )}
</div>

// Screen Reader - Live Regions
<div role="status" aria-live="polite" aria-atomic="true">{message}</div>

// Visually Hidden (Tailwind sr-only)
<span className="sr-only">Loading...</span>
```

---

## SEO Implementation

### Essential SEO Requirements

- Page titles: 50-60 characters, unique per page
- Meta descriptions: 150-160 characters
- Open Graph and Twitter Card metadata
- JSON-LD structured data for rich results

```tsx
// Static Metadata
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Home | My App',
  description: 'Welcome to my app',
  openGraph: {
    title: 'Home | My App',
    description: 'Welcome to my app',
    images: [{ url: '/og-image.jpg', width: 1200, height: 630 }],
    type: 'website'
  },
  twitter: { card: 'summary_large_image' },
}

// Dynamic Metadata
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params
  const post = await getPost(slug)
  return {
    title: post.title,
    description: post.excerpt,
  }
}

// JSON-LD Structured Data
const jsonLd = {
  '@context': 'https://schema.org',
  '@type': 'Article',
  headline: article.title,
  datePublished: article.publishedAt,
  author: { '@type': 'Person', name: article.author }
}
return <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />

// Sitemap (app/sitemap.ts)
import type { MetadataRoute } from 'next'

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const posts = await getPosts()
  return [
    { url: 'https://example.com', changeFrequency: 'daily', priority: 1 },
    ...posts.map(p => ({ url: `https://example.com/posts/${p.slug}`, lastModified: p.updatedAt }))
  ]
}
```

---

## TypeScript Best Practices

### Essential TypeScript Rules

- Enable strict mode and all strict flags
- No `any` types (use `unknown` if truly uncertain)
- All functions must have return types
- Use discriminated unions for variants
- Extend HTML attributes for component props

```tsx
// Component Props - Extend HTML attributes
interface ButtonProps extends React.ComponentProps<"button"> {
  variant?: 'primary' | 'secondary'
  isLoading?: boolean
}

// API Response Types
export interface ApiResponse<T> {
  data: T
  message: string
  success: boolean
}

// Server Action Types
export interface ActionResult<T = void> {
  success: boolean
  message?: string
  data?: T
  errors?: Record<string, string[]>
}

// Utility Types
type RequiredFields<T, K extends keyof T> = T & Required<Pick<T, K>>
type OptionalFields<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>
```

---

## Development Workflow

### Commands

```bash
# Development
pnpm dev              # Start dev server with Turbopack
pnpm build            # Production build
pnpm lint             # Check for issues with Biome
pnpm lint:fix         # Auto-fix issues with Biome

# Database
pnpm db:generate      # Generate Prisma client
pnpm db:migrate       # Run migrations
pnpm db:push          # Push schema changes
pnpm db:studio        # Open Prisma Studio

# Docker
pnpm docker:up        # Start PostgreSQL
pnpm docker:down      # Stop PostgreSQL
```

### Code Standards

- Use tabs for indentation (Biome default)
- Use double quotes for strings
- TypeScript strict mode enabled
- Path alias: `@/*` maps to `./src/*`
- **Run `pnpm lint:fix` after making changes**

### Git Workflow

- Create feature branches from main
- Use conventional commit format: type(scope): description
- Commit types: feat, fix, docs, style, refactor, test, chore
- Keep commits atomic and focused on single changes

---

## Quick Reference

### Import Patterns

```typescript
// External libraries first
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'

// Internal modules
import { Button } from '@/components/ui/button'
import { authClient } from '@/lib/auth-client'
import { cn } from '@/lib/utils'

// Types (if separate)
import type { User } from '@/types'
```

### Common Patterns

```tsx
// Conditional rendering with auth
const { data: session, isPending } = authClient.useSession();

{isPending ? null : session ? (
  <AuthenticatedContent />
) : (
  <UnauthenticatedContent />
)}

// Form with loading state
<Button type="submit" disabled={loading}>
  {loading ? "Processing..." : "Submit"}
</Button>

// Navigation after action
const router = useRouter();
router.push("/");
router.refresh(); // Refresh server components
```

---

## Resources

- [Next.js 16 Documentation](https://nextjs.org/docs)
- [React 19 Documentation](https://react.dev)
- [Better Auth Documentation](https://www.better-auth.com)
- [Prisma 7 Documentation](https://www.prisma.io/docs)
- [shadcn/ui](https://ui.shadcn.com)
- [Tailwind CSS 4](https://tailwindcss.com)

---

**Last Updated**: 2025-12-14
**Compatibility**: Next.js 16+, React 19, TypeScript 5+, Prisma 7, Better Auth
