resource "newrelic_one_dashboard" "claude_code_overview" {
  name        = "Claude Code Overview"
  permissions = "private"

  # ── Cost ──
  page {
    name = "Cost & Tokens"

    widget_line {
      title  = "Daily Cost (USD)"
      row    = 1
      column = 1
      width  = 6
      height = 3
      nrql_query {
        query = "SELECT sum(claude_code_cost_usage_total) FROM Metric TIMESERIES 1 day SINCE 7 days ago"
      }
    }

    widget_line {
      title  = "Cost by Model"
      row    = 1
      column = 7
      width  = 6
      height = 3
      nrql_query {
        query = "SELECT sum(claude_code_cost_usage_total) FROM Metric FACET model TIMESERIES 1 day SINCE 7 days ago"
      }
    }

    widget_line {
      title  = "Daily Token Usage by Type"
      row    = 4
      column = 1
      width  = 6
      height = 3
      nrql_query {
        query = "SELECT sum(claude_code_token_usage_total) FROM Metric FACET type TIMESERIES 1 day SINCE 7 days ago"
      }
    }

    widget_billboard {
      title  = "Cache Hit Ratio"
      row    = 4
      column = 7
      width  = 3
      height = 3
      nrql_query {
        query = "SELECT filter(sum(claude_code_token_usage_total), WHERE type = 'cacheRead') / (filter(sum(claude_code_token_usage_total), WHERE type = 'input') + filter(sum(claude_code_token_usage_total), WHERE type = 'cacheRead')) * 100 AS 'Cache %' FROM Metric SINCE 1 day ago"
      }
    }

    widget_line {
      title  = "Token Usage by Model"
      row    = 4
      column = 10
      width  = 3
      height = 3
      nrql_query {
        query = "SELECT sum(claude_code_token_usage_total) FROM Metric FACET model TIMESERIES 1 day SINCE 7 days ago"
      }
    }
  }

  # ── Activity ──
  page {
    name = "Activity"

    widget_billboard {
      title  = "Sessions"
      row    = 1
      column = 1
      width  = 3
      height = 2
      nrql_query {
        query = "SELECT sum(claude_code_session_count_total) AS 'Sessions' FROM Metric SINCE 1 day ago"
      }
    }

    widget_billboard {
      title  = "Lines Changed"
      row    = 1
      column = 4
      width  = 3
      height = 2
      nrql_query {
        query = "SELECT sum(claude_code_lines_of_code_count_total) AS 'Lines' FROM Metric SINCE 1 day ago"
      }
    }

    widget_billboard {
      title  = "Commits"
      row    = 1
      column = 7
      width  = 3
      height = 2
      nrql_query {
        query = "SELECT sum(claude_code_commit_count_total) AS 'Commits' FROM Metric SINCE 1 day ago"
      }
    }

    widget_billboard {
      title  = "PRs"
      row    = 1
      column = 10
      width  = 3
      height = 2
      nrql_query {
        query = "SELECT sum(claude_code_pull_request_count_total) AS 'PRs' FROM Metric SINCE 1 day ago"
      }
    }

    widget_billboard {
      title  = "Lines Added vs Removed"
      row    = 3
      column = 1
      width  = 4
      height = 2
      nrql_query {
        query = "SELECT filter(sum(claude_code_lines_of_code_count_total), WHERE type = 'added') AS 'Added', filter(sum(claude_code_lines_of_code_count_total), WHERE type = 'removed') AS 'Removed' FROM Metric SINCE 1 day ago"
      }
    }

    widget_line {
      title  = "Active Time (User vs CLI)"
      row    = 3
      column = 5
      width  = 8
      height = 3
      nrql_query {
        query = "SELECT sum(claude_code_active_time_total) FROM Metric FACET type TIMESERIES 1 day SINCE 7 days ago"
      }
    }
  }

  # ── Tools ──
  page {
    name = "Tools & Skills"

    widget_pie {
      title  = "Tool Decisions"
      row    = 1
      column = 1
      width  = 6
      height = 3
      nrql_query {
        query = "SELECT sum(claude_code_code_edit_tool_decision_total) FROM Metric FACET tool_name SINCE 7 days ago"
      }
    }

    widget_bar {
      title  = "Edit Decisions by Language"
      row    = 1
      column = 7
      width  = 6
      height = 3
      nrql_query {
        query = "SELECT sum(claude_code_code_edit_tool_decision_total) FROM Metric FACET language, decision SINCE 7 days ago"
      }
    }

    widget_bar {
      title  = "Top Tools Used"
      row    = 4
      column = 1
      width  = 6
      height = 3
      nrql_query {
        query = "SELECT count(*) FROM Log WHERE service.name = 'claude-code' AND event_name = 'tool_result' FACET tool_name SINCE 7 days ago"
      }
    }

    widget_bar {
      title  = "Skill Usage Ranking"
      row    = 4
      column = 7
      width  = 6
      height = 3
      nrql_query {
        query = "SELECT count(*) FROM Log WHERE service.name = 'claude-code' AND event_name = 'tool_result' AND tool_name = 'Skill' AND skill_name IS NOT NULL FACET skill_name SINCE 7 days ago"
      }
    }

    widget_bar {
      title  = "File References (Read/Glob/Grep)"
      row    = 7
      column = 1
      width  = 6
      height = 3
      nrql_query {
        query = "SELECT count(*) FROM Log WHERE service.name = 'claude-code' AND event_name = 'tool_result' AND tool_name IN ('Read', 'Glob', 'Grep') FACET tool_name SINCE 7 days ago"
      }
    }

    widget_bar {
      title  = "MCP Server Tool Usage"
      row    = 7
      column = 7
      width  = 6
      height = 3
      nrql_query {
        query = "SELECT count(*) FROM Log WHERE service.name = 'claude-code' AND event_name = 'tool_result' AND mcp_server_scope IS NOT NULL FACET mcp_server_scope SINCE 7 days ago"
      }
    }
  }

  # ── API ──
  page {
    name = "API Performance"

    widget_line {
      title  = "API Latency (p50 / p95)"
      row    = 1
      column = 1
      width  = 6
      height = 3
      nrql_query {
        query = "SELECT percentile(duration_ms, 50, 95) FROM Log WHERE service.name = 'claude-code' AND event_name = 'api_request' TIMESERIES 1 hour SINCE 7 days ago"
      }
    }

    widget_line {
      title  = "API Errors"
      row    = 1
      column = 7
      width  = 6
      height = 3
      nrql_query {
        query = "SELECT count(*) FROM Log WHERE service.name = 'claude-code' AND event_name = 'api_error' FACET status_code TIMESERIES 1 hour SINCE 7 days ago"
      }
    }

    widget_table {
      title  = "Most Read Files (Top 20)"
      row    = 4
      column = 1
      width  = 6
      height = 4
      nrql_query {
        query = "SELECT count(*) FROM Log WHERE service.name = 'claude-code' AND event_name = 'tool_result' AND tool_name = 'Read' AND file_path IS NOT NULL FACET file_path LIMIT 20 SINCE 7 days ago"
      }
    }

    widget_table {
      title  = "User Prompts (Recent)"
      row    = 4
      column = 7
      width  = 6
      height = 4
      nrql_query {
        query = "SELECT timestamp, message FROM Log WHERE service.name = 'claude-code' AND event_name = 'user_prompt' LIMIT 50 SINCE 7 days ago"
      }
    }
  }
}
