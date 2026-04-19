/// <reference types="@cloudflare/workers-types" />
import {
  fetchMessagesAfter,
  listDMChannels,
  type DiscordChannel,
  type DiscordMessage,
} from "@/discord.ts";
import { parseEnv, type ValidatedEnv } from "@/env.ts";
import { formatLine, toJstParts } from "@/format.ts";
import { appendLines, type GitHubFileTarget } from "@/github.ts";
import { formatHttpError } from "@/http.ts";

const DM_CHANNEL_TYPE = 1;

const kvKey = (channelId: string): string => `last_msg:${channelId}`;

const groupByDate = (msgs: DiscordMessage[]): Map<string, string[]> => {
  const byDate = new Map<string, string[]>();
  for (const m of msgs) {
    const { date } = toJstParts(m.timestamp);
    const list = byDate.get(date) ?? [];
    list.push(formatLine(m));
    byDate.set(date, list);
  }
  return byDate;
};

const saveCursor = (
  env: ValidatedEnv,
  channelId: string,
  msgs: DiscordMessage[],
): Promise<void> => {
  const newest = msgs[0];
  return newest
    ? env.MEMO_BOT_KV.put(kvKey(channelId), newest.id)
    : Promise.resolve();
};

const processChannel = async (
  env: ValidatedEnv,
  channel: DiscordChannel,
): Promise<void> => {
  const lastId = await env.MEMO_BOT_KV.get(kvKey(channel.id));
  const msgsResult = await fetchMessagesAfter(
    env.DISCORD_BOT_TOKEN,
    channel.id,
    lastId,
  );

  if (msgsResult.isErr()) {
    console.error(formatHttpError(msgsResult.error));
    return;
  }

  const msgs = msgsResult.value;
  if (msgs.length === 0) return;

  if (!lastId) {
    await saveCursor(env, channel.id, msgs);
    return;
  }

  // Discord snowflake IDs are monotonic per API docs, so string compare
  // orders by creation time ascending.
  const relevant = msgs
    .filter((m) => m.author.id === env.ALLOWED_DISCORD_USER_ID)
    .sort((a, b) => (a.id < b.id ? -1 : 1));

  if (relevant.length === 0) {
    await saveCursor(env, channel.id, msgs);
    return;
  }

  const byDate = groupByDate(relevant);
  const base: Omit<GitHubFileTarget, "path"> = {
    pat: env.GITHUB_PAT,
    owner: env.GITHUB_OWNER,
    repo: env.GITHUB_REPO,
  };

  const writes = await Promise.allSettled(
    Array.from(byDate, ([date, lines]) =>
      appendLines(
        { ...base, path: `${env.INBOX_DIR}/${date}.md` },
        lines,
      ),
    ),
  );

  let failed = false;
  for (const w of writes) {
    if (w.status === "rejected") {
      console.error("github append rejected:", w.reason);
      failed = true;
    } else if (w.value.isErr()) {
      console.error(formatHttpError(w.value.error));
      failed = true;
    }
  }
  if (failed) return;

  const newestId = relevant[relevant.length - 1]?.id;
  if (newestId) await env.MEMO_BOT_KV.put(kvKey(channel.id), newestId);
};

const runScheduled = async (env: ValidatedEnv): Promise<void> => {
  const channelsResult = await listDMChannels(env.DISCORD_BOT_TOKEN);
  if (channelsResult.isErr()) {
    console.error(formatHttpError(channelsResult.error));
    return;
  }
  const dmChannels = channelsResult.value.filter(
    (c) => c.type === DM_CHANNEL_TYPE,
  );
  const results = await Promise.allSettled(
    dmChannels.map((c) => processChannel(env, c)),
  );
  for (const r of results) {
    if (r.status === "rejected") console.error("channel error:", r.reason);
  }
};

export default {
  async scheduled(
    _event: ScheduledEvent,
    rawEnv: unknown,
    ctx: ExecutionContext,
  ): Promise<void> {
    const env = parseEnv(rawEnv);
    ctx.waitUntil(runScheduled(env));
  },
};
