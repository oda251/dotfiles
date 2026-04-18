import type { DiscordMessage } from "@/discord.ts";

const JST_OFFSET_MS = 9 * 60 * 60 * 1000;

export interface JstParts {
  date: string;
  time: string;
}

export const toJstParts = (iso: string): JstParts => {
  const ms = new Date(iso).getTime() + JST_OFFSET_MS;
  const d = new Date(ms);
  const yyyy = d.getUTCFullYear();
  const mm = String(d.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(d.getUTCDate()).padStart(2, "0");
  const hh = String(d.getUTCHours()).padStart(2, "0");
  const mi = String(d.getUTCMinutes()).padStart(2, "0");
  return { date: `${yyyy}-${mm}-${dd}`, time: `${hh}:${mi}` };
};

export const formatLine = (msg: DiscordMessage): string => {
  const { time } = toJstParts(msg.timestamp);
  const parts: string[] = [];
  const body = msg.content.trim();
  if (body) parts.push(body);
  for (const a of msg.attachments) {
    parts.push(`[${a.filename}](${a.url})`);
  }
  const content = parts.join(" ") || "(empty)";
  return `- ${time} 💬 ${content}`;
};
