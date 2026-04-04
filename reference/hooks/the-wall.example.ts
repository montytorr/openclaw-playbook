type BeforeToolCall = {
  toolName: string;
  args: Record<string, unknown>;
};

const SECRET_PATTERNS = [
  /AKIA[0-9A-Z]{16}/,
  /sk-[a-zA-Z0-9]{20,}/,
  /ghp_[a-zA-Z0-9]{36}/,
  /-----BEGIN[\s\S]*PRIVATE KEY-----/,
];

function stringifySafe(value: unknown): string {
  try {
    return JSON.stringify(value);
  } catch {
    return String(value);
  }
}

export default async function beforeToolCall(event: BeforeToolCall) {
  const body = stringifySafe(event.args);
  for (const pattern of SECRET_PATTERNS) {
    if (pattern.test(body)) {
      return {
        allow: false,
        reason: `Blocked by the-wall: possible credential pattern matched ${pattern}`,
      };
    }
  }

  const destructiveExec =
    event.toolName === 'exec' &&
    /(rm\s+-rf|reboot|shutdown|mkfs|killall)/.test(body);

  if (destructiveExec) {
    return {
      allow: false,
      reason: 'Blocked pending human approval: destructive exec pattern detected',
    };
  }

  return { allow: true };
}
