# This file is managed by Terraform. Do not edit manually.
name: Terraform

on:
  pull_request:
    paths: [terraform/**]
  push:
    branches: [main]
    paths: [terraform/**]
  issue_comment:
    types: [created]

permissions:
  contents: read
  pull-requests: write

env:
  GITHUB_TOKEN: $${{ secrets.GH_PAT }}

jobs:
%{ for stack in stacks ~}
  plan-${replace(stack, "/", "-")}:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Plan
        id: plan
        uses: oda251/dotfiles/.github/actions/terraform-plan@main
        with:
          working_directory: ${stack}
          tf_api_token: $${{ secrets.TF_API_TOKEN }}
          tf_cloud_organization: $${{ secrets.TF_CLOUD_ORGANIZATION }}

      - name: Comment
        if: always() && steps.plan.outputs.plan_text_path
        uses: oda251/dotfiles/.github/actions/terraform-comment@main
        with:
          pr_number: $${{ github.event.pull_request.number }}
          stack: ${stack}
          command: plan
          output_path: $${{ steps.plan.outputs.plan_text_path }}
          has_changes: $${{ steps.plan.outputs.has_changes }}
          format: $${{ steps.plan.outputs.format }}
          plan_hash: $${{ steps.plan.outputs.plan_hash }}

  apply-merge-${replace(stack, "/", "-")}:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: oda251/dotfiles/.github/actions/terraform-apply@main
        with:
          working_directory: ${stack}
          tf_api_token: $${{ secrets.TF_API_TOKEN }}
          tf_cloud_organization: $${{ secrets.TF_CLOUD_ORGANIZATION }}

%{ endfor ~}
  apply-comment:
    if: >
      github.event_name == 'issue_comment' &&
      github.event.issue.pull_request &&
      github.event.comment.body == '/apply' &&
      github.event.comment.author_association == 'OWNER'
    runs-on: ubuntu-latest
    steps:
      - name: Get PR ref and validate
        id: pr
        uses: actions/github-script@v7
        with:
          script: |
            const pr = await github.rest.pulls.get({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: context.issue.number,
            });
            const files = await github.rest.pulls.listFiles({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: context.issue.number,
            });
            const hasTf = files.data.some(f => f.filename.startsWith('terraform/'));
            if (!hasTf) {
              core.setFailed('PR has no terraform changes');
              return;
            }
            core.setOutput('ref', pr.data.head.ref);

      - uses: actions/checkout@v4
        with:
          ref: $${{ steps.pr.outputs.ref }}

%{ for stack in stacks ~}
      - name: Apply ${stack}
        id: apply-${replace(stack, "/", "-")}
        uses: oda251/dotfiles/.github/actions/terraform-apply@main
        with:
          working_directory: ${stack}
          tf_api_token: $${{ secrets.TF_API_TOKEN }}
          tf_cloud_organization: $${{ secrets.TF_CLOUD_ORGANIZATION }}

      - name: Comment ${stack}
        if: always() && steps.apply-${replace(stack, "/", "-")}.outputs.apply_text_path
        uses: oda251/dotfiles/.github/actions/terraform-comment@main
        with:
          pr_number: $${{ github.event.issue.number }}
          stack: ${stack}
          command: apply
          output_path: $${{ steps.apply-${replace(stack, "/", "-")}.outputs.apply_text_path }}
          format: diff

%{ endfor ~}
