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
    `${repoName}/production/INFISICAL_CLIENT_ID`,
    {
      repository: repo.name,
      environment: env.environment,
      secretName: "INFISICAL_CLIENT_ID",
      plaintextValue: Config.infisical.clientId,
    },
    {},
  );

  new github.ActionsEnvironmentSecret(
    `${repoName}/production/INFISICAL_CLIENT_SECRET`,
    {
      repository: repo.name,
      environment: env.environment,
      secretName: "INFISICAL_CLIENT_SECRET",
      plaintextValue: Config.infisical.clientSecret,
    },
    {},
  );

  new github.ActionsEnvironmentVariable(
    `${repoName}/production/INFISICAL_PROJECT_SLUG`,
    {
      repository: repo.name,
      environment: env.environment,
      variableName: "INFISICAL_PROJECT_SLUG",
      value: Config.infisical.projectSlug,
    },
    {},
  );
};
