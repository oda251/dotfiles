"""Claude Code Discord notification bot with bidirectional communication."""

from __future__ import annotations

import asyncio
import json
import logging
import os
import subprocess
import time
from enum import Enum

import discord
from aiohttp import web
from discord import ui

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# 設定
# ---------------------------------------------------------------------------
DISCORD_BOT_TOKEN = os.environ["DISCORD_BOT_TOKEN"]
DISCORD_CHANNEL_ID = int(os.environ["DISCORD_CHANNEL_ID"])
API_PORT = int(os.environ.get("CLAUDE_BOT_PORT", "19280"))
# 同一イベントの重複通知を抑制する秒数
DEBOUNCE_SECONDS = int(os.environ.get("CLAUDE_BOT_DEBOUNCE", "10"))

# ---------------------------------------------------------------------------
# Zellij 操作
# ---------------------------------------------------------------------------
ZELLIJ_SESSION = os.environ.get("ZELLIJ_SESSION_NAME", "")


def zellij_write(text: str, session: str | None = None) -> bool:
    """Zellij の対象ペインにキーストロークを送信する。"""
    cmd = ["zellij"]
    sess = session or ZELLIJ_SESSION
    if sess:
        cmd += ["--session", sess]
    cmd += ["action", "write-chars", text]
    try:
        subprocess.run(cmd, check=True, timeout=5)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired) as e:
        log.warning("zellij write-chars failed: %s", e)
        return False


# ---------------------------------------------------------------------------
# Discord UI コンポーネント
# ---------------------------------------------------------------------------


class PermissionView(ui.View):
    """権限確認用の許可/拒否ボタン。"""

    def __init__(self, session: str | None = None) -> None:
        super().__init__(timeout=300)
        self.session = session

    @ui.button(label="許可", style=discord.ButtonStyle.green, emoji="✅")
    async def allow(self, interaction: discord.Interaction, button: ui.Button) -> None:
        zellij_write("y", self.session)
        await interaction.response.edit_message(
            content=interaction.message.content + "\n\n→ **許可しました**",
            view=None,
        )

    @ui.button(label="拒否", style=discord.ButtonStyle.red, emoji="❌")
    async def deny(self, interaction: discord.Interaction, button: ui.Button) -> None:
        zellij_write("n", self.session)
        await interaction.response.edit_message(
            content=interaction.message.content + "\n\n→ **拒否しました**",
            view=None,
        )


class SelectionView(ui.View):
    """選択式質問用のボタン群。"""

    def __init__(
        self,
        options: list[dict],
        session: str | None = None,
    ) -> None:
        super().__init__(timeout=300)
        self.session = session
        self.waiting_free_input = False
        self.message: discord.Message | None = None

        for i, opt in enumerate(options):
            label = opt.get("label", f"Option {i + 1}")
            btn = ui.Button(
                label=f"{i + 1}. {label}"[:80],
                style=discord.ButtonStyle.primary,
                custom_id=f"select_{i}",
            )
            btn.callback = self._make_select_callback(i, len(options))
            self.add_item(btn)

        # 自由入力ボタン
        free_btn = ui.Button(
            label="✏️ 自由入力",
            style=discord.ButtonStyle.secondary,
            custom_id="select_free",
        )
        free_btn.callback = self._free_input_callback
        self.add_item(free_btn)

    def _make_select_callback(self, index: int, total: int):
        async def callback(interaction: discord.Interaction) -> None:
            # "Other" は最後の選択肢なので、index が total 未満なら通常選択肢
            # Claude Code の TUI では Tab/矢印キーで移動、Enter で確定
            # 最初の選択肢にフォーカスがある前提で、下矢印で index 回移動
            keys = "\x1b[B" * index + "\n"
            zellij_write(keys, self.session)
            selected_label = interaction.data.get("custom_id", "")
            await interaction.response.edit_message(
                content=interaction.message.content + f"\n\n→ **選択肢 {index + 1} を選択しました**",
                view=None,
            )

        return callback

    async def _free_input_callback(self, interaction: discord.Interaction) -> None:
        self.waiting_free_input = True
        await interaction.response.edit_message(
            content=interaction.message.content + "\n\n✏️ **テキストを送信してください** (次のメッセージを自由入力として扱います)",
            view=None,
        )


class InteractionState(Enum):
    IDLE = "idle"
    WAITING_FREE_INPUT = "waiting_free_input"


# ---------------------------------------------------------------------------
# Bot 本体
# ---------------------------------------------------------------------------


class ClaudeNotifyBot(discord.Client):
    def __init__(self) -> None:
        intents = discord.Intents.default()
        intents.message_content = True
        super().__init__(intents=intents)
        self.channel: discord.TextChannel | None = None
        self.state = InteractionState.IDLE
        # セッション情報: session_id -> {zellij_session, ...}
        self.sessions: dict[str, dict] = {}
        # 最後に操作していたセッション (返信のデフォルト送信先)
        self.active_session_id: str | None = None
        # デバウンス用: (event_name, session_id) -> last_timestamp
        self._last_notify: dict[tuple[str, str], float] = {}
        # 選択式の自由入力待ちビュー
        self._pending_selection_view: SelectionView | None = None

    async def on_ready(self) -> None:
        log.info("Bot ready: %s", self.user)
        self.channel = self.get_channel(DISCORD_CHANNEL_ID)  # type: ignore[assignment]
        if not self.channel:
            log.error("Channel %s not found", DISCORD_CHANNEL_ID)

    async def on_message(self, message: discord.Message) -> None:
        if message.author.bot:
            return
        if message.channel.id != DISCORD_CHANNEL_ID:
            return

        text = message.content.strip()
        if not text:
            return

        # 選択式質問の自由入力待ち
        if self._pending_selection_view and self._pending_selection_view.waiting_free_input:
            view = self._pending_selection_view
            self._pending_selection_view = None
            # "Other" を選択 (最後の選択肢 = 一番下) してからテキスト入力
            # Other は選択肢の最後にあるので、End キーで末尾に移動して Enter
            zellij_write("\x1b[F\n", view.session)
            await asyncio.sleep(0.3)
            zellij_write(text + "\n", view.session)
            await message.reply(f"→ 自由入力を送信しました: `{text}`")
            self.state = InteractionState.IDLE
            return

        # 通常のテキスト返信 → アクティブセッションへ送信
        session_info = self.sessions.get(self.active_session_id or "")
        zellij_session = session_info.get("zellij_session") if session_info else None
        if zellij_write(text + "\n", zellij_session):
            await message.add_reaction("📨")
        else:
            await message.reply("⚠️ Zellij への送信に失敗しました")

    # ------------------------------------------------------------------
    # 通知受信 (ローカル HTTP API から呼ばれる)
    # ------------------------------------------------------------------

    async def handle_notify(self, data: dict) -> None:
        if not self.channel:
            log.warning("Channel not available, skipping notification")
            return

        event = data.get("hook_event_name", "Unknown")
        session_id = data.get("session_id", "unknown")
        cwd = data.get("cwd", "")
        zellij_session = data.get("zellij_session", ZELLIJ_SESSION)

        # セッション情報を保存
        self.sessions[session_id] = {"zellij_session": zellij_session, "cwd": cwd}
        self.active_session_id = session_id

        # デバウンス
        key = (event, session_id)
        now = time.time()
        last = self._last_notify.get(key, 0)
        if now - last < DEBOUNCE_SECONDS:
            log.info("Debounced notification: %s (session=%s)", event, session_id[:8])
            return
        self._last_notify[key] = now

        if event == "Notification":
            await self._handle_notification_event(data, session_id, cwd, zellij_session)
        elif event == "Stop":
            await self._handle_stop_event(data, session_id, cwd)
        else:
            embed = discord.Embed(
                title=f"Claude Code — {event}",
                description=data.get("message", "(no message)"),
                color=discord.Color.greyple(),
            )
            embed.add_field(name="Session", value=f"`{session_id[:8]}`", inline=True)
            embed.add_field(name="CWD", value=f"`{cwd}`", inline=True)
            await self.channel.send(embed=embed)

    async def _handle_notification_event(
        self, data: dict, session_id: str, cwd: str, zellij_session: str
    ) -> None:
        notification_type = data.get("notification_type", "")
        message = data.get("message", "")
        title = data.get("title", "通知")

        if notification_type == "permission_prompt":
            embed = discord.Embed(
                title="🔐 Claude Code — 権限確認",
                description=message,
                color=discord.Color.orange(),
            )
            embed.add_field(name="Session", value=f"`{session_id[:8]}`", inline=True)
            embed.add_field(name="CWD", value=f"`{cwd}`", inline=True)
            view = PermissionView(session=zellij_session)
            await self.channel.send(embed=embed, view=view)

        elif notification_type == "elicitation_dialog":
            # 選択式質問
            options = data.get("options", [])
            embed = discord.Embed(
                title="❓ Claude Code — 質問",
                description=message,
                color=discord.Color.blue(),
            )
            if options:
                option_text = "\n".join(
                    f"**{i + 1}.** {opt.get('label', '?')} — {opt.get('description', '')}"
                    for i, opt in enumerate(options)
                )
                embed.add_field(name="選択肢", value=option_text, inline=False)

            embed.add_field(name="Session", value=f"`{session_id[:8]}`", inline=True)
            embed.add_field(name="CWD", value=f"`{cwd}`", inline=True)

            if options:
                view = SelectionView(options=options, session=zellij_session)
                self._pending_selection_view = view
                await self.channel.send(embed=embed, view=view)
            else:
                # 選択肢がない場合はテキスト入力待ち
                self.state = InteractionState.WAITING_FREE_INPUT
                embed.set_footer(text="テキストを送信して返信してください")
                await self.channel.send(embed=embed)

        else:
            embed = discord.Embed(
                title=f"🔔 Claude Code — {title}",
                description=message,
                color=discord.Color.yellow(),
            )
            embed.add_field(name="Type", value=f"`{notification_type}`", inline=True)
            embed.add_field(name="Session", value=f"`{session_id[:8]}`", inline=True)
            await self.channel.send(embed=embed)

    async def _handle_stop_event(self, data: dict, session_id: str, cwd: str) -> None:
        stop_reason = data.get("stop_reason", "end_turn")
        embed = discord.Embed(
            title="✅ Claude Code — 応答完了",
            description=f"応答が完了しました (`{stop_reason}`)",
            color=discord.Color.green(),
        )
        embed.add_field(name="Session", value=f"`{session_id[:8]}`", inline=True)
        embed.add_field(name="CWD", value=f"`{cwd}`", inline=True)
        embed.set_footer(text="テキストを送信して次の指示を送れます")
        await self.channel.send(embed=embed)


# ---------------------------------------------------------------------------
# ローカル HTTP API (Hook スクリプトからの受信用)
# ---------------------------------------------------------------------------


async def run_http_api(bot: ClaudeNotifyBot) -> None:
    app = web.Application()

    async def handle_notify(request: web.Request) -> web.Response:
        try:
            data = await request.json()
        except json.JSONDecodeError:
            return web.Response(status=400, text="invalid json")
        asyncio.create_task(bot.handle_notify(data))
        return web.Response(text="ok")

    async def handle_health(request: web.Request) -> web.Response:
        return web.Response(text="ok")

    app.router.add_post("/notify", handle_notify)
    app.router.add_get("/health", handle_health)

    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, "127.0.0.1", API_PORT)
    await site.start()
    log.info("HTTP API listening on 127.0.0.1:%d", API_PORT)


# ---------------------------------------------------------------------------
# エントリポイント
# ---------------------------------------------------------------------------


async def main() -> None:
    bot = ClaudeNotifyBot()
    await run_http_api(bot)
    await bot.start(DISCORD_BOT_TOKEN)


if __name__ == "__main__":
    asyncio.run(main())
