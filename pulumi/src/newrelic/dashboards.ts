import * as newrelic from "@pulumi/newrelic";
import { Config } from "@/lib/config.ts";

const { accountId } = Config.newrelic;

type Pos = { row: number; column: number; width: number; height: number };

const widget = (title: string, pos: Pos, query: string) => ({
  title,
  ...pos,
  nrqlQueries: [{ accountId, query }],
});

export const claudeCodeOverview = new newrelic.OneDashboard("claude_code_overview", {
  name: "Claude Code Overview",
  permissions: "private",
  pages: [
    {
      name: "Cost & Tokens",
      widgetLines: [
        widget(
          "Daily Cost (USD)",
          { row: 1, column: 1, width: 6, height: 3 },
          "SELECT sum(claude_code.cost.usage) FROM Metric TIMESERIES 1 day SINCE 7 days ago",
        ),
        widget(
          "Cost by Model",
          { row: 1, column: 7, width: 6, height: 3 },
          "SELECT sum(claude_code.cost.usage) FROM Metric FACET model TIMESERIES 1 day SINCE 7 days ago",
        ),
        widget(
          "Daily Token Usage by Type",
          { row: 4, column: 1, width: 6, height: 3 },
          "SELECT sum(claude_code.token.usage) FROM Metric FACET type TIMESERIES 1 day SINCE 7 days ago",
        ),
        widget(
          "Token Usage by Model",
          { row: 4, column: 10, width: 3, height: 3 },
          "SELECT sum(claude_code.token.usage) FROM Metric FACET model TIMESERIES 1 day SINCE 7 days ago",
        ),
      ],
      widgetBillboards: [
        widget(
          "Cache Hit Ratio",
          { row: 4, column: 7, width: 3, height: 3 },
          "SELECT filter(sum(claude_code.token.usage), WHERE type = 'cacheRead') / (filter(sum(claude_code.token.usage), WHERE type = 'input') + filter(sum(claude_code.token.usage), WHERE type = 'cacheRead')) * 100 AS 'Cache %' FROM Metric SINCE 1 day ago",
        ),
      ],
    },
    {
      name: "Activity",
      widgetBillboards: [
        widget(
          "Sessions",
          { row: 1, column: 1, width: 3, height: 2 },
          "SELECT sum(claude_code.session.count) AS 'Sessions' FROM Metric SINCE 1 day ago",
        ),
        widget(
          "Lines Changed",
          { row: 1, column: 4, width: 3, height: 2 },
          "SELECT sum(claude_code.lines_of_code.count) AS 'Lines' FROM Metric SINCE 1 day ago",
        ),
        widget(
          "Commits",
          { row: 1, column: 7, width: 3, height: 2 },
          "SELECT sum(claude_code.commit.count) AS 'Commits' FROM Metric SINCE 1 day ago",
        ),
        widget(
          "PRs",
          { row: 1, column: 10, width: 3, height: 2 },
          "SELECT sum(claude_code.pull_request.count) AS 'PRs' FROM Metric SINCE 1 day ago",
        ),
        widget(
          "Lines Added vs Removed",
          { row: 3, column: 1, width: 4, height: 2 },
          "SELECT filter(sum(claude_code.lines_of_code.count), WHERE type = 'added') AS 'Added', filter(sum(claude_code.lines_of_code.count), WHERE type = 'removed') AS 'Removed' FROM Metric SINCE 1 day ago",
        ),
      ],
      widgetLines: [
        widget(
          "Active Time (User vs CLI)",
          { row: 3, column: 5, width: 8, height: 3 },
          "SELECT sum(claude_code.active_time.total) FROM Metric FACET type TIMESERIES 1 day SINCE 7 days ago",
        ),
      ],
    },
    {
      name: "Tools & Skills",
      widgetPies: [
        widget(
          "Tool Decisions",
          { row: 1, column: 1, width: 6, height: 3 },
          "SELECT sum(claude_code.code_edit_tool.decision) FROM Metric FACET tool_name SINCE 7 days ago",
        ),
      ],
      widgetBars: [
        widget(
          "Edit Decisions by Language",
          { row: 1, column: 7, width: 6, height: 3 },
          "SELECT sum(claude_code.code_edit_tool.decision) FROM Metric FACET language, decision SINCE 7 days ago",
        ),
        widget(
          "Top Tools Used",
          { row: 4, column: 1, width: 6, height: 3 },
          "SELECT count(*) FROM Log WHERE service.name = 'claude-code' AND event.name = 'tool_result' FACET tool_name SINCE 7 days ago",
        ),
        widget(
          "Skill Usage Ranking",
          { row: 4, column: 7, width: 6, height: 3 },
          "SELECT count(*) FROM Log WHERE service.name = 'claude-code' AND event.name = 'tool_result' AND tool_name = 'Skill' FACET message SINCE 7 days ago",
        ),
        widget(
          "File References (Read/Glob/Grep)",
          { row: 7, column: 1, width: 6, height: 3 },
          "SELECT count(*) FROM Log WHERE service.name = 'claude-code' AND event.name = 'tool_result' AND tool_name IN ('Read', 'Glob', 'Grep') FACET tool_name SINCE 7 days ago",
        ),
        widget(
          "MCP Server Tool Usage",
          { row: 7, column: 7, width: 6, height: 3 },
          "SELECT count(*) FROM Log WHERE service.name = 'claude-code' AND event.name = 'tool_result' AND tool_name LIKE 'mcp__%' FACET tool_name SINCE 7 days ago",
        ),
      ],
    },
    {
      name: "API Performance",
      widgetLines: [
        widget(
          "API Latency (p50 / p95)",
          { row: 1, column: 1, width: 6, height: 3 },
          "SELECT percentile(duration_ms, 50, 95) FROM Log WHERE service.name = 'claude-code' AND event.name = 'api_request' TIMESERIES 1 hour SINCE 7 days ago",
        ),
        widget(
          "API Errors",
          { row: 1, column: 7, width: 6, height: 3 },
          "SELECT count(*) FROM Log WHERE service.name = 'claude-code' AND event.name = 'api_error' FACET message TIMESERIES 1 hour SINCE 7 days ago",
        ),
      ],
      widgetTables: [
        widget(
          "Most Read Files (Top 20)",
          { row: 4, column: 1, width: 6, height: 4 },
          "SELECT count(*) FROM Log WHERE service.name = 'claude-code' AND event.name = 'tool_result' AND tool_name = 'Read' AND tool_input.file_path IS NOT NULL FACET tool_input.file_path LIMIT 20 SINCE 7 days ago",
        ),
        widget(
          "User Prompts (Recent)",
          { row: 4, column: 7, width: 6, height: 4 },
          "SELECT timestamp, prompt FROM Log WHERE service.name = 'claude-code' AND event.name = 'user_prompt' LIMIT 50 SINCE 7 days ago",
        ),
      ],
    },
  ],
});
