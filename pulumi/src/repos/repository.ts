import * as github from "@pulumi/github";
import { Config, type RepoSpec } from "../lib/config.ts";
import { createProductionEnvironment } from "./environment.ts";
import { gateWorkflow } from "./templates.ts";

export type RepoBundle = {
  spec: RepoSpec;
  repo: github.Repository;
};

export const createRepository = (spec: RepoSpec): RepoBundle => {
  const repo = new github.Repository(
    spec.name,
    {
      name: spec.name,
      description: spec.description,
      visibility: spec.visibility,
      topics: spec.topics,
      isTemplate: spec.isTemplate,
      hasIssues: true,
      hasProjects: false,
      hasWiki: false,
      vulnerabilityAlerts: spec.vulnerabilityAlerts,
      deleteBranchOnMerge: true,
      allowSquashMerge: true,
      allowMergeCommit: false,
      allowRebaseMerge: false,
      ...(spec.visibility === "public"
        ? {
            securityAndAnalysis: {
              secretScanning: { status: "enabled" },
              secretScanningPushProtection: { status: "enabled" },
            },
          }
        : {}),
      ...(spec.template
        ? {
            template: {
              owner: Config.github.owner,
              repository: spec.template,
            },
          }
        : {}),
    },
    {},
  );

  if (spec.visibility === "public" && !spec.isTemplate) {
    new github.RepositoryFile(
      `${spec.name}/gate`,
      {
        repository: repo.name,
        branch: "main",
        file: ".github/workflows/gate.yml",
        content: gateWorkflow,
        commitMessage: "chore: add gate workflow (managed by Pulumi)",
        overwriteOnCreate: true,
      },
      { ignoreChanges: ["content"] },
    );
  }

  if (spec.visibility === "public") {
    new github.RepositoryRuleset(
      `${spec.name}/main`,
      {
        repository: repo.name,
        name: "main",
        target: "branch",
        enforcement: "active",
        bypassActors: [
          { actorId: 5, actorType: "RepositoryRole", bypassMode: "always" },
        ],
        conditions: {
          refName: { includes: ["~DEFAULT_BRANCH"], excludes: [] },
        },
        rules: {
          pullRequest: {
            requiredApprovingReviewCount: 1,
            dismissStaleReviewsOnPush: true,
          },
          requiredStatusChecks: {
            requiredChecks: [{ context: "gate" }],
            strictRequiredStatusChecksPolicy: true,
          },
        },
      },
      {},
    );
  }

  if (spec.hasESC) {
    createProductionEnvironment(spec.name, repo);
  }

  return { spec, repo };
};
