import * as v from "valibot";
import { formatValibotIssues } from "@/http.ts";

const hasMethod = (obj: object, key: string): boolean =>
  key in obj &&
  typeof (obj as Record<string, unknown>)[key] === "function";

const KVNamespaceSchema = v.custom<KVNamespace>(
  (value) =>
    typeof value === "object" &&
    value !== null &&
    hasMethod(value, "get") &&
    hasMethod(value, "put"),
  "Expected a KVNamespace binding",
);

const EnvSchema = v.object({
  DISCORD_BOT_TOKEN: v.pipe(v.string(), v.minLength(1)),
  GITHUB_PAT: v.pipe(v.string(), v.minLength(1)),
  ALLOWED_DISCORD_USER_ID: v.pipe(v.string(), v.regex(/^\d+$/)),
  GITHUB_OWNER: v.pipe(v.string(), v.minLength(1)),
  GITHUB_REPO: v.pipe(v.string(), v.minLength(1)),
  DAILY_NOTE_DIR: v.pipe(v.string(), v.minLength(1)),
  MEMO_BOT_KV: KVNamespaceSchema,
});

export type ValidatedEnv = v.InferOutput<typeof EnvSchema>;

let cached: ValidatedEnv | null = null;

export const parseEnv = (raw: unknown): ValidatedEnv => {
  if (cached) return cached;
  const result = v.safeParse(EnvSchema, raw);
  if (!result.success) {
    throw new Error(
      `Invalid Worker env bindings: ${formatValibotIssues(result.issues)}`,
    );
  }
  cached = result.output;
  return cached;
};
