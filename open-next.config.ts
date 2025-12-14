import { defineAzureConfig } from "opennextjs-azure";

export default defineAzureConfig({
	// Azure storage adapters for Next.js features
	incrementalCache: "azure-blob",
	tagCache: "azure-table",
	queue: "azure-queue",
	imageLoader: "azure-blob",

	// Enable image optimization caching
	enableImageOptimizationCache: true,

	// Disable route preloading (reduces cold start time)
	routePreloadingBehavior: "none",

	// Enable Application Insights monitoring
	applicationInsights: true,
});
