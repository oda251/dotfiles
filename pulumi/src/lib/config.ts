import * as pulumi from "@pulumi/pulumi";
import * as v from "valibot";

const RepoSpecSchema = v.object({
  name: v.string(),
  description: v.optional(v.string(), ""),
  visibility: v.optional(v.picklist(["public", "private"]), "public"),
  topics: v.optional(v.array(v.string()), []),
  isTemplate: v.optional(v.boolean(), false),
  template: v.optional(v.string()),
  hasESC: v.optional(v.boolean(), false),
  hasTerraform: v.optional(v.boolean(), false),
  vulnerabilityAlerts: v.optional(v.boolean(), true),
});

export type RepoSpec = v.InferOutput<typeof RepoSpecSchema>;

const ReposSchema = v.array(RepoSpecSchema);

const parseRepos = (raw: unknown, source: string): RepoSpec[] => {
  const result = v.safeParse(ReposSchema, raw);
  if (!result.success) {
    throw new Error(
      `Invalid ${source} repos config: ${JSON.stringify(result.issues, null, 2)}`,
    );
  }
  return result.output;
};

const cfgGithub = new pulumi.Config("github");
const cfgNewrelic = new pulumi.Config("newrelic");
const cfgRepos = new pulumi.Config("repos");
const cfgPulumi = new pulumi.Config("pulumi");

export const Config = {
  github: {
    owner: cfgGithub.require("owner"),
    token: cfgGithub.requireSecret("token"),
  },
  newrelic: {
    region: cfgNewrelic.get("region") ?? "US",
    apiKey: cfgNewrelic.requireSecret("apiKey"),
    accountId: cfgNewrelic.require("accountId"),
  },
  pulumi: {
    accessToken: cfgPulumi.requireSecret("accessToken"),
  },
  repos: {
    public: parseRepos(cfgRepos.requireObject("public"), "public"),
    private: parseRepos(cfgRepos.requireObject("private"), "private"),
  },
} as const;
