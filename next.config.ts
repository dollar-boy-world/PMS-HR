import type { NextConfig } from "next";
import path from "node:path";

const nextConfig: NextConfig = {
  // Silence the multi-lockfile workspace-root warning: this app is the root,
  // even though the capstone repo root also has a package.json (for generate-ppt.js).
  turbopack: { root: path.resolve(__dirname, "..") },
};

export default nextConfig;