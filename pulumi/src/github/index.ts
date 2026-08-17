import type * as github from "@pulumi/github";
import { Config } from "@/lib/config.ts";
import { createRepository, type RepoBundle } from "./repository.ts";

const created: RepoBundle[] = Config.repos.map(createRepository);

export const registerGithub = (): {
  repositoryUrls: Record<string, github.Repository["htmlUrl"]>;
} => ({
  repositoryUrls: Object.fromEntries(created.map(({ spec, repo }) => [spec.name, repo.htmlUrl])),
});
