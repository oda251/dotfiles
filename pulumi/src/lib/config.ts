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
  vulnerabilityAlerts: v.optional(v.boolean(), true),
});

export type RepoSpec = v.InferOutput<typeof RepoSpecSchema>;

const ReposSchema = v.array(RepoSpecSchema);

const parseRepos = (raw: unknown): RepoSpec[] => {
  const result = v.safeParse(ReposSchema, raw);
  if (!result.success) {
    throw new Error(
      `Invalid repos config: ${JSON.stringify(result.issues, null, 2)}`,
    );
  }
  return result.output;
};

const cfgGithub = new pulumi.Config("github");
const cfgNewrelic = new pulumi.Config("newrelic");
const cfgRepos = new pulumi.Config("repos");
const cfgCloudflare = new pulumi.Config("cloudflare");
const cfgMemoBot = new pulumi.Config("memoBot");

export const Config = {
  github: {
    owner: cfgGithub.require("owner"),
    token: cfgGithub.requireSecret("token"),
  },
  newrelic: {
    region: v.parse(v.picklist(["US", "EU"]), cfgNewrelic.get("region") ?? "US"),
    apiKey: cfgNewrelic.requireSecret("apiKey"),
    accountId: cfgNewrelic.require("accountId"),
  },
  repos: parseRepos(cfgRepos.requireObject("all")),
  cloudflare: {
    accountId: cfgCloudflare.require("accountId"),
  },
  memoBot: {
    discordBotToken: cfgMemoBot.requireSecret("discordBotToken"),
    githubPat: cfgMemoBot.requireSecret("githubPat"),
    allowedDiscordUserId: cfgMemoBot.require("allowedDiscordUserId"),
    githubOwner: cfgMemoBot.get("githubOwner") ?? "oda251",
    githubRepo: cfgMemoBot.get("githubRepo") ?? "obsidian-vault",
    dailyNoteDir: cfgMemoBot.get("dailyNoteDir") ?? "Daily",
  },
};
