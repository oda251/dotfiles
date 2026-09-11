import { registerGithub } from "./src/github/index.ts";

const github = registerGithub();

export const repositoryUrls = github.repositoryUrls;
