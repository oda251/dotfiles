import type { ResultAsync } from "neverthrow";
import * as v from "valibot";
import { fetchJson, USER_AGENT, type HttpClientError } from "@/http.ts";

const DISCORD_API = "https://discord.com/api/v10";
const INITIAL_LIMIT = 1;
const BACKFILL_LIMIT = 100;

const UserSchema = v.object({ id: v.string() });

const ChannelSchema = v.object({
  id: v.string(),
  type: v.number(),
  recipients: v.optional(v.array(UserSchema)),
});

const AttachmentSchema = v.object({
  url: v.string(),
  filename: v.string(),
  content_type: v.optional(v.string()),
});

const MessageSchema = v.object({
  id: v.string(),
  channel_id: v.string(),
  author: UserSchema,
  content: v.string(),
  timestamp: v.string(),
  attachments: v.array(AttachmentSchema),
});

export type DiscordChannel = v.InferOutput<typeof ChannelSchema>;
export type DiscordMessage = v.InferOutput<typeof MessageSchema>;

const requestInit = (token: string): RequestInit => ({
  headers: {
    Authorization: `Bot ${token}`,
    "User-Agent": USER_AGENT,
  },
});

export const listDMChannels = (
  token: string,
): ResultAsync<DiscordChannel[], HttpClientError> => {
  const path = "/users/@me/channels";
  return fetchJson(
    "discord",
    `${DISCORD_API}${path}`,
    requestInit(token),
    v.array(ChannelSchema),
    path,
  );
};

export const fetchMessagesAfter = (
  token: string,
  channelId: string,
  afterId: string | null,
): ResultAsync<DiscordMessage[], HttpClientError> => {
  const qs = afterId
    ? `?after=${afterId}&limit=${BACKFILL_LIMIT}`
    : `?limit=${INITIAL_LIMIT}`;
  const path = `/channels/${channelId}/messages${qs}`;
  return fetchJson(
    "discord",
    `${DISCORD_API}${path}`,
    requestInit(token),
    v.array(MessageSchema),
    path,
  );
};
