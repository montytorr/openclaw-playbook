type AfterToolCall = {
  toolName: string;
  args: Record<string, unknown>;
  result?: unknown;
};

const TRACKED_TOOLS = new Set(['write', 'edit', 'exec', 'sessions_spawn']);

export default async function afterToolCall(event: AfterToolCall) {
  if (!TRACKED_TOOLS.has(event.toolName)) return { allow: true };

  // This is intentionally simple: in a real implementation you would query
  // your task database / recent task log and verify a matching in-progress task
  // exists before allowing state-changing work to continue silently.
  return {
    allow: true,
    note: `Reminder: confirm a task exists for ${event.toolName}`,
  };
}
