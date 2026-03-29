import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join, basename, dirname } from "node:path";
import matter from "gray-matter";
import * as v from "valibot";
import type { Workflow, LintError } from "./types.js";

const FrontmatterSchema = v.object({
  description: v.pipe(v.string(), v.minLength(1)),
  inputs: v.record(v.string(), v.string()),
  "requires-approval": v.optional(v.boolean(), false),
  then: v.optional(v.string()),
  callable: v.optional(v.boolean(), true),
});

function discoverWorkflowFiles(workflowsDir: string): string[] {
  if (!existsSync(workflowsDir)) return [];

  const files: string[] = [];
  for (const domain of readdirSync(workflowsDir, { withFileTypes: true })) {
    if (!domain.isDirectory()) continue;
    const domainDir = join(workflowsDir, domain.name);
    for (const file of readdirSync(domainDir, { withFileTypes: true })) {
      if (file.isFile() && file.name.endsWith(".md")) {
        files.push(join(domainDir, file.name));
      }
    }
  }
  return files;
}

export function loadWorkflows(workflowsDir: string): {
  workflows: Map<string, Workflow>;
  errors: LintError[];
} {
  const workflows = new Map<string, Workflow>();
  const errors: LintError[] = [];
  const files = discoverWorkflowFiles(workflowsDir);

  for (const filePath of files) {
    const domain = basename(dirname(filePath));
    const name = basename(filePath, ".md");
    const type = `${domain}/${name}`;

    let raw: string;
    try {
      raw = readFileSync(filePath, "utf-8");
    } catch {
      errors.push({ file: type, message: "Failed to read file" });
      continue;
    }

    const { data, content } = matter(raw);
    const result = v.safeParse(FrontmatterSchema, data);

    if (!result.success) {
      const issues = result.issues.map((i) => i.message).join("; ");
      errors.push({
        file: type,
        message: `Invalid frontmatter: ${issues}`,
      });
      continue;
    }

    workflows.set(type, {
      type,
      domain,
      name,
      frontmatter: result.output,
      body: content.trim(),
      outputs: {},
    });
  }

  // Resolve then references and outputs
  for (const [type, workflow] of workflows) {
    const { then: thenName } = workflow.frontmatter;
    if (!thenName) continue;

    const thenType = `${workflow.domain}/${thenName}`;
    const thenWorkflow = workflows.get(thenType);

    if (!thenWorkflow) {
      errors.push({
        file: type,
        message: `then "${thenName}" references non-existent workflow "${thenType}"`,
      });
      continue;
    }

    const currentInputKeys = new Set(
      Object.keys(workflow.frontmatter.inputs),
    );
    for (const [key, desc] of Object.entries(thenWorkflow.frontmatter.inputs)) {
      if (!currentInputKeys.has(key)) {
        workflow.outputs[key] = desc;
      }
    }
  }

  return { workflows, errors };
}

export function lint(workflowsDir: string): LintError[] {
  const { workflows, errors } = loadWorkflows(workflowsDir);

  // Circular then chains
  for (const [type, workflow] of workflows) {
    if (!workflow.frontmatter.then) continue;

    const visited = new Set<string>();
    let current: string | undefined = type;

    while (current) {
      if (visited.has(current)) {
        errors.push({
          file: type,
          message: `Circular then chain detected: ${[...visited, current].join(" → ")}`,
        });
        break;
      }
      visited.add(current);
      const w = workflows.get(current);
      if (!w?.frontmatter.then) break;
      current = `${w.domain}/${w.frontmatter.then}`;
    }
  }

  // Orphaned non-callable workflows
  const referencedByThen = new Set<string>();
  for (const [, workflow] of workflows) {
    if (workflow.frontmatter.then) {
      referencedByThen.add(`${workflow.domain}/${workflow.frontmatter.then}`);
    }
  }

  for (const [type, workflow] of workflows) {
    if (workflow.frontmatter.callable === false && !referencedByThen.has(type)) {
      errors.push({
        file: type,
        message:
          "Workflow is callable: false but not referenced by any then chain (orphaned)",
      });
    }
  }

  return errors;
}

export function getCallableWorkflows(
  workflows: Map<string, Workflow>,
): Workflow[] {
  return [...workflows.values()].filter(
    (w) => w.frontmatter.callable !== false,
  );
}
