import { registerGithub } from "./src/github/index.ts";
import { registerMemoBot } from "./src/memo-bot/index.ts";
import { registerNewrelic } from "./src/newrelic/index.ts";

const github = registerGithub();
const newrelic = registerNewrelic();
const memoBot = registerMemoBot();

export const repositoryUrls = github.repositoryUrls;
export const otlpEndpoint = newrelic.otlpEndpoint;
export const newrelicLicenseKey = newrelic.newrelicLicenseKey;
export const dashboardGuid = newrelic.dashboardGuid;
export const memoBotSecretIds = memoBot.secretIds;
