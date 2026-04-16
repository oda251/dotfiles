// Embedded workflow templates deployed to managed repos via github.RepositoryFile.
// Mirrors terraform/github/templates/*.yml.tpl content 1:1 so the import is
// content-identical (lifecycle.ignoreChanges on content keeps subsequent edits
// out of Pulumi's drift detection).

export const gateWorkflow = `# This file is managed by Terraform. Do not edit manually.
name: Gate

on:
  pull_request:

jobs:
  gate:
    if: always()
    needs: []
    runs-on: ubuntu-latest
    steps:
      - run: exit 1
        if: contains(needs.*.result, 'failure') || contains(needs.*.result, 'cancelled')
`;

export const terraformWorkflow = `# This file is managed by Terraform. Do not edit manually.
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

jobs:
  plan:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4

      - name: Fetch Infisical Secrets
        uses: Infisical/secrets-action@v1.0.12
        with:
          method: "universal"
          client-id: \${{ secrets.INFISICAL_CLIENT_ID }}
          client-secret: \${{ secrets.INFISICAL_CLIENT_SECRET }}
          env-slug: "prod"
          project-slug: \${{ vars.INFISICAL_PROJECT_SLUG }}
          secret-path: "/terraform/env"

      - name: Plan
        id: plan
        uses: oda251/dotfiles/.github/actions/terraform-plan@main
        with:
          working_directory: terraform

      - name: Comment
        if: always() && steps.plan.outputs.plan_text_path
        uses: oda251/dotfiles/.github/actions/terraform-comment@main
        with:
          pr_number: \${{ github.event.pull_request.number }}
          stack: terraform
          command: plan
          output_path: \${{ steps.plan.outputs.plan_text_path }}
          has_changes: \${{ steps.plan.outputs.has_changes }}
          format: \${{ steps.plan.outputs.format }}
          plan_hash: \${{ steps.plan.outputs.plan_hash }}

  apply-merge:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4

      - name: Fetch Infisical Secrets
        uses: Infisical/secrets-action@v1.0.12
        with:
          method: "universal"
          client-id: \${{ secrets.INFISICAL_CLIENT_ID }}
          client-secret: \${{ secrets.INFISICAL_CLIENT_SECRET }}
          env-slug: "prod"
          project-slug: \${{ vars.INFISICAL_PROJECT_SLUG }}
          secret-path: "/terraform/env"

      - uses: oda251/dotfiles/.github/actions/terraform-apply@main
        with:
          working_directory: terraform
`;
