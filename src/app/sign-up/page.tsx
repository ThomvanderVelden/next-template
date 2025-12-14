"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
	Card,
	CardContent,
	CardDescription,
	CardFooter,
	CardHeader,
	CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { authClient } from "@/lib/auth-client";
import { type SignUpInput, signUpSchema } from "@/lib/validations";

export default function SignUp() {
	const router = useRouter();
	const [formData, setFormData] = useState<SignUpInput>({
		name: "",
		email: "",
		password: "",
	});
	const [errors, setErrors] = useState<
		Partial<Record<keyof SignUpInput, string>>
	>({});
	const [submitError, setSubmitError] = useState("");
	const [loading, setLoading] = useState(false);

	function handleChange(field: keyof SignUpInput, value: string) {
		setFormData((prev) => ({ ...prev, [field]: value }));
		// Clear field error on change
		if (errors[field]) {
			setErrors((prev) => ({ ...prev, [field]: undefined }));
		}
	}

	async function handleSubmit(e: React.FormEvent) {
		e.preventDefault();
		setSubmitError("");
		setErrors({});

		// Validate with Zod schema
		const result = signUpSchema.safeParse(formData);
		if (!result.success) {
			const fieldErrors: Partial<Record<keyof SignUpInput, string>> = {};
			for (const issue of result.error.issues) {
				const field = issue.path[0] as keyof SignUpInput;
				fieldErrors[field] = issue.message;
			}
			setErrors(fieldErrors);
			return;
		}

		setLoading(true);

		const { error } = await authClient.signUp.email(result.data);

		if (error) {
			setSubmitError(error.message ?? "Failed to sign up");
			setLoading(false);
			return;
		}

		router.push("/");
		router.refresh();
	}

	return (
		<div className="flex min-h-screen items-center justify-center">
			<Card className="w-full max-w-sm">
				<CardHeader>
					<CardTitle>Sign Up</CardTitle>
					<CardDescription>Create an account to get started</CardDescription>
				</CardHeader>
				<form onSubmit={handleSubmit}>
					<CardContent className="space-y-4">
						{submitError && (
							<p className="text-sm text-red-500">{submitError}</p>
						)}
						<div className="space-y-2">
							<Label htmlFor="name">Name</Label>
							<Input
								id="name"
								type="text"
								value={formData.name}
								onChange={(e) => handleChange("name", e.target.value)}
								aria-invalid={!!errors.name}
								aria-describedby={errors.name ? "name-error" : undefined}
							/>
							{errors.name && (
								<p id="name-error" className="text-sm text-red-500">
									{errors.name}
								</p>
							)}
						</div>
						<div className="space-y-2">
							<Label htmlFor="email">Email</Label>
							<Input
								id="email"
								type="email"
								value={formData.email}
								onChange={(e) => handleChange("email", e.target.value)}
								aria-invalid={!!errors.email}
								aria-describedby={errors.email ? "email-error" : undefined}
							/>
							{errors.email && (
								<p id="email-error" className="text-sm text-red-500">
									{errors.email}
								</p>
							)}
						</div>
						<div className="space-y-2">
							<Label htmlFor="password">Password</Label>
							<Input
								id="password"
								type="password"
								value={formData.password}
								onChange={(e) => handleChange("password", e.target.value)}
								aria-invalid={!!errors.password}
								aria-describedby={
									errors.password ? "password-error" : undefined
								}
							/>
							{errors.password && (
								<p id="password-error" className="text-sm text-red-500">
									{errors.password}
								</p>
							)}
						</div>
					</CardContent>
					<CardFooter className="flex flex-col gap-4">
						<Button type="submit" className="w-full" disabled={loading}>
							{loading ? "Creating account..." : "Sign Up"}
						</Button>
						<p className="text-sm text-muted-foreground">
							Already have an account?{" "}
							<Link href="/sign-in" className="underline">
								Sign in
							</Link>
						</p>
					</CardFooter>
				</form>
			</Card>
		</div>
	);
}
