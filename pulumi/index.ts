import { registerGithub } from "./src/github/index.ts";
import { registerNewrelic } from "./src/newrelic/index.ts";

const github = registerGithub();
const newrelic = registerNewrelic();

export const repositoryUrls = github.repositoryUrls;
export const otlpEndpoint = newrelic.otlpEndpoint;
export const newrelicLicenseKey = newrelic.newrelicLicenseKey;
export const dashboardGuid = newrelic.dashboardGuid;
