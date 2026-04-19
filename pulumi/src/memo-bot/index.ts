import * as fs from "node:fs";
import * as path from "node:path";
import * as cloudflare from "@pulumi/cloudflare";
import type * as pulumi from "@pulumi/pulumi";
import { Config } from "@/lib/config.ts";

const WORKER_BUNDLE = path.resolve(
  import.meta.dirname,
  "../../../apps/memo-bot/dist/worker.js",
);

const readBundle = (): string => {
  if (!fs.existsSync(WORKER_BUNDLE)) {
    throw new Error(
      `Worker bundle not found at ${WORKER_BUNDLE}. Run 'bun run build' in apps/memo-bot/ first.`,
    );
  }
  return fs.readFileSync(WORKER_BUNDLE, "utf-8");
};

export const registerMemoBot = (): {
  workerName: pulumi.Output<string>;
  kvNamespaceId: pulumi.Output<string>;
} => {
  const accountId = Config.cloudflare.accountId;

  const kv = new cloudflare.WorkersKvNamespace("memo-bot-kv", {
    accountId,
    title: "memo-bot",
  });

  const script = new cloudflare.WorkersScript("memo-bot", {
    accountId,
    scriptName: "memo-bot",
    content: readBundle(),
    mainModule: "worker.js",
    bindings: [
      {
        name: "MEMO_BOT_KV",
        type: "kv_namespace",
        namespaceId: kv.id,
      },
      {
        name: "DISCORD_BOT_TOKEN",
        type: "secret_text",
        text: Config.memoBot.discordBotToken,
      },
      {
        name: "GITHUB_PAT",
        type: "secret_text",
        text: Config.memoBot.githubPat,
      },
      {
        name: "ALLOWED_DISCORD_USER_ID",
        type: "plain_text",
        text: Config.memoBot.allowedDiscordUserId,
      },
      {
        name: "GITHUB_OWNER",
        type: "plain_text",
        text: Config.memoBot.githubOwner,
      },
      {
        name: "GITHUB_REPO",
        type: "plain_text",
        text: Config.memoBot.githubRepo,
      },
      {
        name: "INBOX_DIR",
        type: "plain_text",
        text: Config.memoBot.inboxDir,
      },
    ],
  });

  new cloudflare.WorkersCronTrigger("memo-bot-cron", {
    accountId,
    scriptName: script.scriptName,
    schedules: [{ cron: "*/15 * * * *" }],
  });

  return {
    workerName: script.scriptName,
    kvNamespaceId: kv.id,
  };
};
