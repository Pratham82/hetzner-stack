"use client";

import { useEffect, useState } from "react";

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8080";

type Hello = { message: string; time: string };

export default function Home() {
  const [data, setData] = useState<Hello | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const controller = new AbortController();
    fetch(`${API_BASE}/api/hello`, { signal: controller.signal })
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json() as Promise<Hello>;
      })
      .then(setData)
      .catch((err: unknown) => {
        if (err instanceof Error && err.name === "AbortError") return;
        setError(err instanceof Error ? err.message : String(err));
      })
      .finally(() => setLoading(false));
    return () => controller.abort();
  }, []);

  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-6 bg-zinc-50 p-8 font-sans dark:bg-black">
      <h1 className="text-2xl font-semibold tracking-tight text-black dark:text-zinc-50">
        hetzner-stack
      </h1>

      <div className="w-full max-w-md rounded-xl border border-black/[.08] bg-white p-6 dark:border-white/[.145] dark:bg-zinc-900">
        <p className="mb-2 text-sm text-zinc-500">
          Calling <code className="font-mono">{API_BASE}/api/hello</code>
        </p>

        {loading && <p className="text-zinc-600 dark:text-zinc-400">Loading…</p>}

        {error && (
          <p className="font-mono text-sm text-red-600 dark:text-red-400">
            Error: {error}
          </p>
        )}

        {data && (
          <div className="space-y-1">
            <p className="text-lg font-medium text-black dark:text-zinc-50">
              {data.message}
            </p>
            <p className="font-mono text-xs text-zinc-500">{data.time}</p>
          </div>
        )}
      </div>
    </main>
  );
}
