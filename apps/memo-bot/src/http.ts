import { err, ok, ResultAsync, type Result } from "neverthrow";
import * as v from "valibot";

export const USER_AGENT = "memo-bot (cloudflare-workers)";
const BODY_TRUNCATE = 200;

export type Source = "discord" | "github";

export type HttpClientError =
  | { source: Source; kind: "http"; status: number; body: string; path: string }
  | { source: Source; kind: "network"; cause: unknown; path: string }
  | { source: Source; kind: "parse"; issues: string; path: string };

export const formatValibotIssues = (
  issues: readonly v.BaseIssue<unknown>[],
): string =>
  issues
    .map(
      (i) =>
        `${i.path?.map((p) => p.key).join(".") ?? "(root)"}: ${i.message}`,
    )
    .join("; ");

const sourceName = (s: Source): string =>
  s === "discord" ? "Discord" : "GitHub";

export const formatHttpError = (e: HttpClientError): string => {
  const prefix = sourceName(e.source);
  switch (e.kind) {
    case "http":
      return `${prefix} HTTP ${e.status} at ${e.path}: ${e.body.slice(0, BODY_TRUNCATE)}`;
    case "network":
      return `${prefix} network error at ${e.path}: ${String(e.cause)}`;
    case "parse":
      return `${prefix} parse error at ${e.path}: ${e.issues}`;
  }
};

export const parseOr = <T>(
  schema: v.BaseSchema<unknown, T, v.BaseIssue<unknown>>,
  data: unknown,
  source: Source,
  path: string,
): Result<T, HttpClientError> => {
  const r = v.safeParse(schema, data);
  if (!r.success) {
    return err({
      source,
      kind: "parse",
      issues: formatValibotIssues(r.issues),
      path,
    });
  }
  return ok(r.output);
};

export interface RawResponse {
  status: number;
  body: string;
}

export const fetchRaw = (
  source: Source,
  url: string,
  init: RequestInit,
  path: string,
): ResultAsync<RawResponse, HttpClientError> =>
  ResultAsync.fromPromise(
    fetch(url, init),
    (cause): HttpClientError => ({ source, kind: "network", cause, path }),
  ).andThen((res) =>
    ResultAsync.fromPromise(
      res.text(),
      (cause): HttpClientError => ({ source, kind: "network", cause, path }),
    ).map((body) => ({ status: res.status, body })),
  );

const isSuccess = (status: number): boolean => status >= 200 && status < 300;

export const fetchJson = <T>(
  source: Source,
  url: string,
  init: RequestInit,
  schema: v.BaseSchema<unknown, T, v.BaseIssue<unknown>>,
  path: string,
): ResultAsync<T, HttpClientError> =>
  fetchRaw(source, url, init, path).andThen(({ status, body }) => {
    if (!isSuccess(status)) {
      return err<T, HttpClientError>({
        source,
        kind: "http",
        status,
        body,
        path,
      });
    }
    try {
      return parseOr(schema, JSON.parse(body), source, path);
    } catch (e) {
      return err<T, HttpClientError>({
        source,
        kind: "parse",
        issues: `JSON.parse failed: ${String(e)}`,
        path,
      });
    }
  });

export { isSuccess };
