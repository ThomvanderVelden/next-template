import { z } from "zod/v4";

// =============================================================================
// AUTH SCHEMAS - Single source of truth for auth-related types
// =============================================================================

/**
 * Sign In Schema
 * Used for: sign-in form validation (client + server)
 */
export const signInSchema = z.object({
	email: z.email("Invalid email address"),
	password: z.string().min(1, "Password is required"),
});

export type SignInInput = z.infer<typeof signInSchema>;

/**
 * Sign Up Schema
 * Used for: sign-up form validation (client + server)
 */
export const signUpSchema = z.object({
	name: z
		.string()
		.min(2, "Name must be at least 2 characters")
		.max(100, "Name must be less than 100 characters"),
	email: z.email("Invalid email address"),
	password: z
		.string()
		.min(8, "Password must be at least 8 characters")
		.regex(/[A-Z]/, "Password must contain at least one uppercase letter")
		.regex(/[a-z]/, "Password must contain at least one lowercase letter")
		.regex(/[0-9]/, "Password must contain at least one number"),
});

export type SignUpInput = z.infer<typeof signUpSchema>;

/**
 * User Schema (public-safe user data)
 * Used for: API responses, frontend components
 * Note: Excludes sensitive fields like password
 */
export const userSchema = z.object({
	id: z.string(),
	name: z.string(),
	email: z.email(),
	emailVerified: z.boolean(),
	image: z.string().nullable(),
	createdAt: z.date(),
	updatedAt: z.date(),
});

export type User = z.infer<typeof userSchema>;

/**
 * Session User Schema (minimal user data for session)
 * Used for: auth session, header components
 */
export const sessionUserSchema = z.object({
	id: z.string(),
	name: z.string(),
	email: z.email(),
	image: z.string().nullable(),
});

export type SessionUser = z.infer<typeof sessionUserSchema>;
