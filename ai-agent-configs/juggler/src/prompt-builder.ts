import type { Workflow } from "./types.js";

export function buildWorkerPrompt(
  workflow: Workflow,
  inputs: Record<string, string>,
  taskId: string,
): string {
  const sections: string[] = [];

  sections.push(`## 共通フロー

1. タスク内容と inputs を確認する
2. 要件不足 → juggler reject 理由
3. 実行する（以下のワークフローに従う）
4. セルフレビュー
5a. OK → juggler done${formatOutputArgs(workflow.outputs)}
5b. 問題あり → juggler reject 理由

タスクID: ${taskId}`);

  sections.push(`## Inputs\n`);
  for (const [key, value] of Object.entries(inputs)) {
    sections.push(`- **${key}**: ${value}`);
  }

  if (Object.keys(workflow.outputs).length > 0) {
    sections.push(`\n## 完了時に返す Outputs\n`);
    for (const [key, desc] of Object.entries(workflow.outputs)) {
      sections.push(`- **${key}**: ${desc}`);
    }
  }

  sections.push(`\n## ワークフロー\n\n${workflow.body}`);

  return sections.join("\n");
}

function formatOutputArgs(outputs: Record<string, string>): string {
  const keys = Object.keys(outputs);
  if (keys.length === 0) return "";
  const example = Object.fromEntries(keys.map((k) => [k, "..."]));
  return ` '${JSON.stringify(example)}'`;
}
