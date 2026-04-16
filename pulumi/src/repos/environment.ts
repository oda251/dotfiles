import * as github from "@pulumi/github";
import { Config } from "../lib/config.ts";

const ownerUserId = github
  .getUserOutput({ username: Config.github.owner })
  .id.apply((id) => Number.parseInt(id, 10));

export const createProductionEnvironment = (
  repoName: string,
  repo: github.Repository,
): void => {
  new github.RepositoryEnvironment(`${repoName}/production`, {
    repository: repo.name,
    environment: "production",
    reviewers: [{ users: [ownerUserId] }],
    deploymentBranchPolicy: {
      protectedBranches: true,
      customBranchPolicies: false,
    },
  });
};
