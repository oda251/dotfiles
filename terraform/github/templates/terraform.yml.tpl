# This file is managed by Terraform. Do not edit manually.
name: Terraform

on:
  pull_request:
    paths: [terraform/**]
  push:
    branches: [main]
    paths: [terraform/**]

permissions:
  contents: read
  pull-requests: write

env:
  GITHUB_TOKEN: $${{ secrets.GH_PAT }}

jobs:
  plan:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Plan
        id: plan
        uses: oda251/dotfiles/.github/actions/terraform-plan@main
        with:
          working_directory: terraform
          tf_api_token: $${{ secrets.TF_API_TOKEN }}
          tf_cloud_organization: $${{ secrets.TF_CLOUD_ORGANIZATION }}

      - name: Comment
        if: always() && steps.plan.outputs.plan_text_path
        uses: oda251/dotfiles/.github/actions/terraform-comment@main
        with:
          pr_number: $${{ github.event.pull_request.number }}
          stack: terraform
          command: plan
          output_path: $${{ steps.plan.outputs.plan_text_path }}
          has_changes: $${{ steps.plan.outputs.has_changes }}
          format: $${{ steps.plan.outputs.format }}
          plan_hash: $${{ steps.plan.outputs.plan_hash }}

  apply-merge:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: oda251/dotfiles/.github/actions/terraform-apply@main
        with:
          working_directory: terraform
          tf_api_token: $${{ secrets.TF_API_TOKEN }}
          tf_cloud_organization: $${{ secrets.TF_CLOUD_ORGANIZATION }}


  gate:
    if: always() && github.event_name == 'pull_request'
    needs: [plan]
    runs-on: ubuntu-latest
    steps:
      - run: exit 1
        if: contains(needs.*.result, 'failure') || contains(needs.*.result, 'cancelled')
