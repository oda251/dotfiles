import { err, ok, type ResultAsync } from "neverthrow";
import * as v from "valibot";
import {
  fetchRaw,
  isSuccess,
  parseOr,
  USER_AGENT,
  type HttpClientError,
} from "@/http.ts";

const GITHUB_API = "https://api.github.com";

const FileContentSchema = v.object({
  content: v.string(),
  sha: v.string(),
});

const b64encode = (s: string): string => {
  const bytes = new TextEncoder().encode(s);
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary);
};

const b64decode = (s: string): string => {
  const binary = atob(s.replace(/\n/g, ""));
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return new TextDecoder().decode(bytes);
};

const headers = (pat: string): HeadersInit => ({
  Authorization: `Bearer ${pat}`,
  Accept: "application/vnd.github+json",
  "X-GitHub-Api-Version": "2022-11-28",
  "User-Agent": USER_AGENT,
});

export interface GitHubFileTarget {
  pat: string;
  owner: string;
  repo: string;
  path: string;
}

interface ExistingFile {
  content: string;
  sha: string;
}

const urlFor = (t: GitHubFileTarget): string =>
  `${GITHUB_API}/repos/${t.owner}/${t.repo}/contents/${encodeURI(t.path)}`;

const getFile = (
  target: GitHubFileTarget,
): ResultAsync<ExistingFile | null, HttpClientError> =>
  fetchRaw(
    "github",
    urlFor(target),
    { headers: headers(target.pat) },
    target.path,
  ).andThen(({ status, body }) => {
    if (status === 404) {
      return ok<ExistingFile | null, HttpClientError>(null);
    }
    if (!isSuccess(status)) {
      return err<ExistingFile | null, HttpClientError>({
        source: "github",
        kind: "http",
        status,
        body,
        path: target.path,
      });
    }
    try {
      return parseOr(
        FileContentSchema,
        JSON.parse(body),
        "github",
        target.path,
      ).map<ExistingFile | null>((parsed) => ({
        content: b64decode(parsed.content),
        sha: parsed.sha,
      }));
    } catch (e) {
      return err<ExistingFile | null, HttpClientError>({
        source: "github",
        kind: "parse",
        issues: `JSON.parse failed: ${String(e)}`,
        path: target.path,
      });
    }
  });

const putFile = (
  target: GitHubFileTarget,
  content: string,
  sha: string | null,
  message: string,
): ResultAsync<void, HttpClientError> =>
  fetchRaw(
    "github",
    urlFor(target),
    {
      method: "PUT",
      headers: { ...headers(target.pat), "Content-Type": "application/json" },
      body: JSON.stringify({
        message,
        content: b64encode(content),
        ...(sha ? { sha } : {}),
      }),
    },
    target.path,
  ).andThen(({ status, body }) => {
    if (isSuccess(status)) return ok<void, HttpClientError>(undefined);
    return err<void, HttpClientError>({
      source: "github",
      kind: "http",
      status,
      body,
      path: target.path,
    });
  });

export const appendLines = (
  target: GitHubFileTarget,
  lines: string[],
): ResultAsync<void, HttpClientError> =>
  getFile(target).andThen((existing) => {
    const prev = existing?.content ?? "";
    const separator = prev.length === 0 || prev.endsWith("\n") ? "" : "\n";
    const next = prev + separator + lines.join("\n") + "\n";
    return putFile(
      target,
      next,
      existing?.sha ?? null,
      `memo-bot: append ${lines.length} memo(s)`,
    );
  });
