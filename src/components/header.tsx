"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { authClient } from "@/lib/auth-client";

export function Header() {
	const router = useRouter();
	const { data: session, isPending } = authClient.useSession();

	async function handleSignOut() {
		await authClient.signOut();
		router.push("/");
		router.refresh();
	}

	return (
		<header className="border-b">
			<div className="container mx-auto flex h-14 items-center justify-between px-4">
				<Link href="/" className="font-semibold">
					App
				</Link>
				<nav className="flex items-center gap-4">
					{isPending ? null : session ? (
						<>
							<span className="text-sm text-muted-foreground">
								{session.user.email}
							</span>
							<Button variant="outline" size="sm" onClick={handleSignOut}>
								Sign Out
							</Button>
						</>
					) : (
						<>
							<Button variant="ghost" size="sm" asChild>
								<Link href="/sign-in">Sign In</Link>
							</Button>
							<Button size="sm" asChild>
								<Link href="/sign-up">Sign Up</Link>
							</Button>
						</>
					)}
				</nav>
			</div>
		</header>
	);
}
