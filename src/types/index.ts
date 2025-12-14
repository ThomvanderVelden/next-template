// =============================================================================
// TYPES INDEX
// =============================================================================
// Central export for all application types.
//
// Type Strategy:
//   1. Zod schemas (lib/validations) = Source of truth for input/output shapes
//   2. Database types (types/database) = Prisma-derived types for complex queries
//   3. This file = Re-exports + application-specific types
//
// Prefer importing from:
//   - "@/lib/validations" for validation schemas and their inferred types
//   - "@/types" for database types and app-specific types
//
// =============================================================================

// Database types (Prisma-derived)
export * from "./database";

// =============================================================================
// APP-SPECIFIC TYPES
// =============================================================================

/**
 * Generic API response wrapper
 */
export type ApiResponse<T> = {
	success: boolean;
	data?: T;
	error?: string;
};

/**
 * Route params type helper
 */
export type RouteParams<T extends Record<string, string>> = {
	params: Promise<T>;
};

/**
 * Search params type helper
 */
export type SearchParams<T extends Record<string, string | string[]>> = {
	searchParams: Promise<T>;
};

/**
 * Page props combining route and search params
 */
export type PageProps<
	TParams extends Record<string, string> = Record<string, string>,
	TSearchParams extends Record<string, string | string[]> = Record<
		string,
		string | string[]
	>,
> = RouteParams<TParams> & SearchParams<TSearchParams>;
