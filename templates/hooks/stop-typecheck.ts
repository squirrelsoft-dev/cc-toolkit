import type { StopHookInput, HookJSONOutput } from "@anthropic-ai/claude-agent-sdk";

const input: StopHookInput = await Bun.stdin.json();

const gitStatus = await Bun.$`git status --porcelain`.quiet().text();

if (gitStatus.trim().length === 0) {
  const output: HookJSONOutput = { decision: "approve" };
  console.log(JSON.stringify(output));
  process.exit(0);
}

const typecheckErrors = await Bun.$`bun typecheck 2>&1 || npx tsc --noEmit 2>&1`.throws(false).quiet().text();

if (typecheckErrors.trim().length > 0 && typecheckErrors.includes("error TS")) {
  const output: HookJSONOutput = {
    decision: "block",
    reason: `Type errors detected. Fix these before stopping.\n\n${typecheckErrors}`,
  };
  console.log(JSON.stringify(output));
  process.exit(0);
}

const output: HookJSONOutput = { decision: "approve" };
console.log(JSON.stringify(output));
