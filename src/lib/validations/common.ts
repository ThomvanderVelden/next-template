import { z } from "zod/v4";

// =============================================================================
// COMMON SCHEMAS - Reusable validation patterns
// =============================================================================

/**
 * Pagination schema
 * Used for: paginated API endpoints
 */
export const paginationSchema = z.object({
	page: z.coerce.number().int().positive().default(1),
	limit: z.coerce.number().int().positive().max(100).default(20),
});

export type PaginationInput = z.infer<typeof paginationSchema>;

/**
 * Paginated response wrapper
 * Used for: API responses with pagination
 */
export const paginatedResponseSchema = <T extends z.ZodType>(itemSchema: T) =>
	z.object({
		items: z.array(itemSchema),
		meta: z.object({
			page: z.number(),
			limit: z.number(),
			total: z.number(),
			totalPages: z.number(),
		}),
	});

/**
 * ID parameter schema
 * Used for: route params like /users/[id]
 */
export const idParamSchema = z.object({
	id: z.string().min(1, "ID is required"),
});

export type IdParam = z.infer<typeof idParamSchema>;

/**
 * Search query schema
 * Used for: search endpoints
 */
export const searchSchema = z.object({
	q: z.string().optional(),
	...paginationSchema.shape,
});

export type SearchInput = z.infer<typeof searchSchema>;

/**
 * Action result schema (for server actions)
 * Used for: standardized server action responses
 */
export const actionResultSchema = <T extends z.ZodType>(dataSchema?: T) =>
	z.object({
		success: z.boolean(),
		message: z.string().optional(),
		data: dataSchema ?? z.undefined(),
		errors: z.record(z.string(), z.array(z.string())).optional(),
	});

/**
 * Type helper for action results
 */
export type ActionResult<T = void> = {
	success: boolean;
	message?: string;
	data?: T;
	errors?: Record<string, string[]>;
};
