import type { Prisma } from "@/generated/prisma/client";

// =============================================================================
// DATABASE TYPES - Derived from Prisma for complex query results
// =============================================================================
// Use these when you need types that include relations or specific field selections.
// For simple input/output types, prefer Zod schemas in lib/validations.
//
// Pattern:
//   1. Define the include/select shape as a const
//   2. Use Prisma.XGetPayload to extract the type
//
// =============================================================================

/**
 * User with sessions
 */
export type UserWithSessions = Prisma.UserGetPayload<{
	include: { sessions: true };
}>;

/**
 * User with accounts (selected fields only)
 */
export type UserWithAccounts = Prisma.UserGetPayload<{
	include: {
		accounts: {
			select: {
				id: true;
				providerId: true;
				createdAt: true;
			};
		};
	};
}>;

/**
 * Public user data (excludes sensitive fields)
 */
export type PublicUser = Prisma.UserGetPayload<{
	select: {
		id: true;
		name: true;
		email: true;
		image: true;
		createdAt: true;
	};
}>;

// =============================================================================
// QUERY ARGS - Reusable include/select configurations
// =============================================================================
// Use these in your Prisma queries for consistent data shapes

export const publicUserSelect = {
	id: true,
	name: true,
	email: true,
	image: true,
	createdAt: true,
} as const satisfies Prisma.UserSelect;

export const userWithSessionsInclude = {
	sessions: true,
} as const satisfies Prisma.UserInclude;

// =============================================================================
// RE-EXPORT PRISMA TYPES
// =============================================================================
// For convenience, re-export commonly used Prisma types

export type {
	Account as PrismaAccount,
	Session as PrismaSession,
	User as PrismaUser,
	Verification as PrismaVerification,
} from "@/generated/prisma/client";
