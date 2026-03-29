# Instance-level provider for managing dashboards and data sources
provider "grafana" {
  alias = "instance"
  url   = grafana_cloud_stack.this.url
  auth  = grafana_cloud_stack_service_account_token.dashboard_admin.key
}

resource "grafana_cloud_stack_service_account" "dashboard_admin" {
  stack_slug = grafana_cloud_stack.this.slug
  name       = "terraform-dashboard-admin"
  role       = "Admin"
}

resource "grafana_cloud_stack_service_account_token" "dashboard_admin" {
  stack_slug         = grafana_cloud_stack.this.slug
  name               = "terraform"
  service_account_id = grafana_cloud_stack_service_account.dashboard_admin.id
}

resource "grafana_folder" "claude_code" {
  provider = grafana.instance
  title    = "Claude Code"
}

resource "grafana_dashboard" "claude_code_overview" {
  provider = grafana.instance
  folder   = grafana_folder.claude_code.id

  config_json = jsonencode({
    title       = "Claude Code Overview"
    description = "Claude Code usage metrics and telemetry"
    timezone    = "browser"
    refresh     = "5m"
    time = {
      from = "now-7d"
      to   = "now"
    }
    panels = [
      {
        id    = 1
        title = "Daily Cost (USD)"
        type  = "timeseries"
        gridPos = {
          h = 8
          w = 12
          x = 0
          y = 0
        }
        targets = [{
          datasource   = { type = "prometheus" }
          expr         = "sum(increase(claude_code_cost_usage_total[1d]))"
          legendFormat = "Cost"
        }]
        fieldConfig = {
          defaults = {
            unit = "currencyUSD"
          }
        }
      },
      {
        id    = 2
        title = "Daily Token Usage"
        type  = "timeseries"
        gridPos = {
          h = 8
          w = 12
          x = 12
          y = 0
        }
        targets = [
          {
            datasource   = { type = "prometheus" }
            expr         = "sum by (type) (increase(claude_code_token_usage_total[1d]))"
            legendFormat = "{{type}}"
          }
        ]
      },
      {
        id    = 3
        title = "Sessions per Day"
        type  = "stat"
        gridPos = {
          h = 4
          w = 6
          x = 0
          y = 8
        }
        targets = [{
          datasource   = { type = "prometheus" }
          expr         = "sum(increase(claude_code_session_count_total[1d]))"
          legendFormat = "Sessions"
        }]
      },
      {
        id    = 4
        title = "Lines of Code Changed"
        type  = "stat"
        gridPos = {
          h = 4
          w = 6
          x = 6
          y = 8
        }
        targets = [{
          datasource   = { type = "prometheus" }
          expr         = "sum(increase(claude_code_lines_of_code_count_total[1d]))"
          legendFormat = "Lines"
        }]
      },
      {
        id    = 5
        title = "Commits Created"
        type  = "stat"
        gridPos = {
          h = 4
          w = 6
          x = 12
          y = 8
        }
        targets = [{
          datasource   = { type = "prometheus" }
          expr         = "sum(increase(claude_code_commit_count_total[1d]))"
          legendFormat = "Commits"
        }]
      },
      {
        id    = 6
        title = "PRs Created"
        type  = "stat"
        gridPos = {
          h = 4
          w = 6
          x = 18
          y = 8
        }
        targets = [{
          datasource   = { type = "prometheus" }
          expr         = "sum(increase(claude_code_pull_request_count_total[1d]))"
          legendFormat = "PRs"
        }]
      },
      {
        id    = 7
        title = "Active Time"
        type  = "timeseries"
        gridPos = {
          h = 8
          w = 12
          x = 0
          y = 12
        }
        targets = [{
          datasource   = { type = "prometheus" }
          expr         = "sum(increase(claude_code_active_time_total[1d]))"
          legendFormat = "Active Time"
        }]
        fieldConfig = {
          defaults = {
            unit = "s"
          }
        }
      },
      {
        id    = 8
        title = "Tool Decisions"
        type  = "piechart"
        gridPos = {
          h = 8
          w = 12
          x = 12
          y = 12
        }
        targets = [{
          datasource   = { type = "prometheus" }
          expr         = "sum by (tool) (increase(claude_code_code_edit_tool_decision_total[7d]))"
          legendFormat = "{{tool}}"
        }]
      },
      {
        id    = 9
        title = "User Prompts (Recent)"
        type  = "logs"
        gridPos = {
          h = 10
          w = 24
          x = 0
          y = 20
        }
        targets = [{
          datasource = { type = "loki" }
          expr       = "{service_name=\"claude-code\"} |= \"user_prompt\""
        }]
      }
    ]
  })
}
