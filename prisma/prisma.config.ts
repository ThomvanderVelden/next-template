import path from "node:path";
import type { PrismaConfig } from "prisma";
import { PrismaPg } from "@prisma/adapter-pg";

export default {
	schema: path.join(__dirname, "schema.prisma"),
	migrate: {
		adapter: async () => {
			const connectionString = process.env.DATABASE_URL;
			if (!connectionString) {
				throw new Error("DATABASE_URL environment variable is not set");
			}
			return new PrismaPg({ connectionString });
		},
	},
} satisfies PrismaConfig;
