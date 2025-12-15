"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import type { z } from "zod/v4";

type FieldErrors<T> = Partial<Record<keyof T, string>>;

interface UseAuthFormOptions<TSchema extends z.ZodSchema> {
	schema: TSchema;
	initialData: z.infer<TSchema>;
	onSubmit: (
		data: z.infer<TSchema>,
	) => Promise<{ error?: { message?: string } }>;
	redirectTo?: string;
}

interface UseAuthFormReturn<TSchema extends z.ZodSchema> {
	formData: z.infer<TSchema>;
	errors: FieldErrors<z.infer<TSchema>>;
	submitError: string;
	loading: boolean;
	handleChange: (field: keyof z.infer<TSchema>, value: string) => void;
	handleSubmit: (e: React.FormEvent) => Promise<void>;
}

export function useAuthForm<TSchema extends z.ZodSchema>({
	schema,
	initialData,
	onSubmit,
	redirectTo = "/",
}: UseAuthFormOptions<TSchema>): UseAuthFormReturn<TSchema> {
	type FormData = z.infer<TSchema>;

	const router = useRouter();
	const [formData, setFormData] = useState<FormData>(initialData);
	const [errors, setErrors] = useState<FieldErrors<FormData>>({});
	const [submitError, setSubmitError] = useState("");
	const [loading, setLoading] = useState(false);

	function handleChange(field: keyof FormData, value: string) {
		setFormData((prev) => ({ ...prev, [field]: value }));
		if (errors[field]) {
			setErrors((prev) => ({ ...prev, [field]: undefined }));
		}
	}

	async function handleSubmit(e: React.FormEvent) {
		e.preventDefault();
		setSubmitError("");
		setErrors({});

		const result = schema.safeParse(formData);
		if (!result.success) {
			const fieldErrors: FieldErrors<FormData> = {};
			for (const issue of result.error.issues) {
				const field = issue.path[0] as keyof FormData;
				fieldErrors[field] = issue.message;
			}
			setErrors(fieldErrors);
			return;
		}

		setLoading(true);

		const { error } = await onSubmit(result.data);

		if (error) {
			setSubmitError(error.message ?? "An error occurred");
			setLoading(false);
			return;
		}

		router.push(redirectTo);
		router.refresh();
	}

	return {
		formData,
		errors,
		submitError,
		loading,
		handleChange,
		handleSubmit,
	};
}
