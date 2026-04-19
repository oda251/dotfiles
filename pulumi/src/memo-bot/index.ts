import * as gcp from "@pulumi/gcp";
import type * as pulumi from "@pulumi/pulumi";
import { Config } from "@/lib/config.ts";

interface SecretSpec {
  id: string;
  value: pulumi.Input<string>;
}

export const registerMemoBot = (): {
  secretIds: pulumi.Output<string>[];
} => {
  const projectId = Config.gcp.projectId;
  const userMember = `user:${Config.gcp.userEmail}`;

  const smApi = new gcp.projects.Service("memo-bot-sm-api", {
    project: projectId,
    service: "secretmanager.googleapis.com",
    disableOnDestroy: false,
  });

  const specs: SecretSpec[] = [
    { id: "memo-bot-discord-token", value: Config.memoBot.discordBotToken },
    { id: "memo-bot-github-pat", value: Config.memoBot.githubPat },
    { id: "memo-bot-allowed-user-id", value: Config.memoBot.allowedDiscordUserId },
  ];

  const secrets = specs.map(({ id, value }) => {
    const secret = new gcp.secretmanager.Secret(
      id,
      {
        project: projectId,
        secretId: id,
        replication: { auto: {} },
      },
      { dependsOn: [smApi] },
    );

    new gcp.secretmanager.SecretVersion(`${id}-version`, {
      secret: secret.id,
      secretData: value,
    });

    new gcp.secretmanager.SecretIamMember(`${id}-accessor`, {
      project: projectId,
      secretId: secret.secretId,
      role: "roles/secretmanager.secretAccessor",
      member: userMember,
    });

    return secret;
  });

  return {
    secretIds: secrets.map((s) => s.id),
  };
};
