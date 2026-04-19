const GCP_PROJECT_ID = 'dotfiles-oda251';
const GITHUB_OWNER = 'oda251';
const GITHUB_REPO = 'obsidian-vault';
const INBOX_DIR = 'Inbox';

const DISCORD_API = 'https://discord.com/api/v10';
const GITHUB_API = 'https://api.github.com';
const DM_CHANNEL_TYPE = 1;
const INITIAL_LIMIT = 1;
const BACKFILL_LIMIT = 100;
const JST_OFFSET_MS = 9 * 60 * 60 * 1000;
const SECRET_CACHE_SEC = 300;

// eslint-disable-next-line no-unused-vars
function pollDMs() {
  const env = loadEnv();
  const channels = discordFetch(env.discordToken, '/users/@me/channels');
  const dmChannels = channels.filter(c => c.type === DM_CHANNEL_TYPE);
  for (const ch of dmChannels) {
    try {
      processChannel(ch, env);
    } catch (e) {
      console.error('channel ' + ch.id + ':', e);
    }
  }
}

// eslint-disable-next-line no-unused-vars
function installTrigger() {
  ScriptApp.getProjectTriggers()
    .filter(t => t.getHandlerFunction() === 'pollDMs')
    .forEach(t => ScriptApp.deleteTrigger(t));
  ScriptApp.newTrigger('pollDMs').timeBased().everyMinutes(15).create();
}

function loadEnv() {
  return {
    discordToken: getSecret('memo-bot-discord-token'),
    githubPat: getSecret('memo-bot-github-pat'),
    allowedUserId: getSecret('memo-bot-allowed-user-id'),
  };
}

function getSecret(secretId) {
  const cache = CacheService.getScriptCache();
  const cached = cache.get(secretId);
  if (cached) return cached;
  const url = 'https://secretmanager.googleapis.com/v1/projects/' + GCP_PROJECT_ID
    + '/secrets/' + secretId + '/versions/latest:access';
  const res = UrlFetchApp.fetch(url, {
    headers: { Authorization: 'Bearer ' + ScriptApp.getOAuthToken() },
    muteHttpExceptions: true,
  });
  if (res.getResponseCode() >= 300) {
    throw new Error('Secret Manager ' + secretId + ': ' + res.getResponseCode() + ' ' + res.getContentText());
  }
  const body = JSON.parse(res.getContentText());
  const value = Utilities.newBlob(Utilities.base64Decode(body.payload.data)).getDataAsString();
  cache.put(secretId, value, SECRET_CACHE_SEC);
  return value;
}

function discordFetch(token, path) {
  const res = UrlFetchApp.fetch(DISCORD_API + path, {
    headers: {
      Authorization: 'Bot ' + token,
      'User-Agent': 'memo-bot-gas',
    },
    muteHttpExceptions: true,
  });
  if (res.getResponseCode() >= 300) {
    throw new Error('Discord ' + path + ': ' + res.getResponseCode() + ' ' + res.getContentText());
  }
  return JSON.parse(res.getContentText());
}

function fetchMessagesAfter(token, channelId, afterId) {
  const qs = afterId
    ? '?after=' + afterId + '&limit=' + BACKFILL_LIMIT
    : '?limit=' + INITIAL_LIMIT;
  return discordFetch(token, '/channels/' + channelId + '/messages' + qs);
}

function processChannel(channel, env) {
  const props = PropertiesService.getScriptProperties();
  const cursorKey = 'last_msg:' + channel.id;
  const lastId = props.getProperty(cursorKey);

  const msgs = fetchMessagesAfter(env.discordToken, channel.id, lastId);
  if (msgs.length === 0) return;

  if (!lastId) {
    props.setProperty(cursorKey, msgs[0].id);
    return;
  }

  const relevant = msgs
    .filter(m => m.author.id === env.allowedUserId)
    .sort((a, b) => (a.id < b.id ? -1 : 1));

  if (relevant.length === 0) {
    props.setProperty(cursorKey, msgs[0].id);
    return;
  }

  const byDate = new Map();
  for (const m of relevant) {
    const parts = toJstParts(m.timestamp);
    const line = formatLine(m, parts.time);
    const list = byDate.get(parts.date) || [];
    list.push(line);
    byDate.set(parts.date, list);
  }

  let failed = false;
  byDate.forEach((lines, date) => {
    try {
      appendLines(env.githubPat, INBOX_DIR + '/' + date + '.md', lines);
    } catch (e) {
      console.error('github ' + date + ':', e);
      failed = true;
    }
  });

  if (!failed) {
    props.setProperty(cursorKey, relevant[relevant.length - 1].id);
  }
}

function toJstParts(iso) {
  const ms = new Date(iso).getTime() + JST_OFFSET_MS;
  const d = new Date(ms);
  const pad = n => String(n).padStart(2, '0');
  return {
    date: d.getUTCFullYear() + '-' + pad(d.getUTCMonth() + 1) + '-' + pad(d.getUTCDate()),
    time: pad(d.getUTCHours()) + ':' + pad(d.getUTCMinutes()),
  };
}

function formatLine(msg, time) {
  const body = (msg.content || '').trim();
  const attachments = (msg.attachments || []).map(a => '[' + a.filename + '](' + a.url + ')');
  const parts = [];
  if (body) parts.push(body);
  parts.push.apply(parts, attachments);
  return '- ' + time + ' 💬 ' + (parts.join(' ') || '(empty)');
}

function appendLines(pat, path, lines) {
  const url = GITHUB_API + '/repos/' + GITHUB_OWNER + '/' + GITHUB_REPO
    + '/contents/' + encodeURI(path);
  const baseHeaders = {
    Authorization: 'Bearer ' + pat,
    Accept: 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    'User-Agent': 'memo-bot-gas',
  };

  let existingSha = null;
  let existingContent = '';
  const getRes = UrlFetchApp.fetch(url, { headers: baseHeaders, muteHttpExceptions: true });
  const getStatus = getRes.getResponseCode();
  if (getStatus === 200) {
    const body = JSON.parse(getRes.getContentText());
    existingSha = body.sha;
    existingContent = Utilities.newBlob(
      Utilities.base64Decode(body.content.replace(/\n/g, ''))
    ).getDataAsString();
  } else if (getStatus !== 404) {
    throw new Error('GET ' + path + ': ' + getStatus + ' ' + getRes.getContentText());
  }

  const separator = existingContent.length === 0 || existingContent.endsWith('\n') ? '' : '\n';
  const newContent = existingContent + separator + lines.join('\n') + '\n';

  const payload = {
    message: 'memo-bot: append ' + lines.length + ' memo(s)',
    content: Utilities.base64Encode(newContent),
  };
  if (existingSha) payload.sha = existingSha;

  const putHeaders = Object.assign({}, baseHeaders, { 'Content-Type': 'application/json' });
  const putRes = UrlFetchApp.fetch(url, {
    method: 'put',
    headers: putHeaders,
    payload: JSON.stringify(payload),
    muteHttpExceptions: true,
  });
  if (putRes.getResponseCode() >= 300) {
    throw new Error('PUT ' + path + ': ' + putRes.getResponseCode() + ' ' + putRes.getContentText());
  }
}
