import type * as github from "@pulumi/github";
import { Config } from "../lib/config.ts";
import { createRepository, type RepoBundle } from "./repository.ts";

const created: RepoBundle[] = [
  ...Config.repos.public.map((spec) => createRepository(spec)),
  ...Config.repos.private.map((spec) =>
    createRepository({ ...spec, visibility: "private" }),
  ),
];

export const registerGithub = (): {
  repositoryUrls: Record<string, github.Repository["htmlUrl"]>;
} => ({
  repositoryUrls: Object.fromEntries(
    created.map(({ spec, repo }) => [spec.name, repo.htmlUrl]),
  ),
});
