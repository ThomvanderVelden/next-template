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
import { type SignInInput, signInSchema } from "@/lib/validations";

export default function SignIn() {
	const router = useRouter();
	const [formData, setFormData] = useState<SignInInput>({
		email: "",
		password: "",
	});
	const [errors, setErrors] = useState<
		Partial<Record<keyof SignInInput, string>>
	>({});
	const [submitError, setSubmitError] = useState("");
	const [loading, setLoading] = useState(false);

	function handleChange(field: keyof SignInInput, value: string) {
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
		const result = signInSchema.safeParse(formData);
		if (!result.success) {
			const fieldErrors: Partial<Record<keyof SignInInput, string>> = {};
			for (const issue of result.error.issues) {
				const field = issue.path[0] as keyof SignInInput;
				fieldErrors[field] = issue.message;
			}
			setErrors(fieldErrors);
			return;
		}

		setLoading(true);

		const { error } = await authClient.signIn.email(result.data);

		if (error) {
			setSubmitError(error.message ?? "Failed to sign in");
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
					<CardTitle>Sign In</CardTitle>
					<CardDescription>
						Enter your credentials to access your account
					</CardDescription>
				</CardHeader>
				<form onSubmit={handleSubmit}>
					<CardContent className="space-y-4">
						{submitError && (
							<p className="text-sm text-red-500">{submitError}</p>
						)}
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
							{loading ? "Signing in..." : "Sign In"}
						</Button>
						<p className="text-sm text-muted-foreground">
							Don&apos;t have an account?{" "}
							<Link href="/sign-up" className="underline">
								Sign up
							</Link>
						</p>
					</CardFooter>
				</form>
			</Card>
		</div>
	);
}
