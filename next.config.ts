import type { NextConfig } from "next";

const nextConfig: NextConfig = {
	// Required for Azure Functions deployment (serverless)
	output: "standalone",
};

export default nextConfig;
