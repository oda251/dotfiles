import * as github from "@pulumi/github";
import { Config } from "../lib/config.ts";

const ownerUserId = github
  .getUserOutput({ username: Config.github.owner })
  .id.apply((id) => Number.parseInt(id, 10));

export const createProductionEnvironment = (
  repoName: string,
  repo: github.Repository,
): void => {
  const env = new github.RepositoryEnvironment(
    `${repoName}/production`,
    {
      repository: repo.name,
      environment: "production",
      reviewers: [{ users: [ownerUserId] }],
      deploymentBranchPolicy: {
        protectedBranches: true,
        customBranchPolicies: false,
      },
    },
    {},
  );

  new github.ActionsEnvironmentSecret(
    `${repoName}/production/PULUMI_ACCESS_TOKEN`,
    {
      repository: repo.name,
      environment: env.environment,
      secretName: "PULUMI_ACCESS_TOKEN",
      plaintextValue: Config.pulumi.accessToken,
    },
    {},
  );
};
