---
name: replaying-logfire-conversations
description: Replay recorded AI conversations from Logfire traces against provider APIs (Anthropic, Gemini). Use when re-sending, debugging, or A/B testing LLM completions from traced conversations -- overriding system prompts, user messages, models, or running multiple concurrent completions.
---

# Replaying Logfire Conversations

Re-send recorded AI conversations from Logfire traces against live provider APIs.

## When to Use

- **Prompt iteration**: tweak a system prompt or user message and re-run without restarting the app
- **A/B testing**: generate multiple completions from the same conversation state
- **Cross-provider comparison**: replay an Anthropic conversation against Gemini (or vice versa)
- **Debugging**: inspect what would be sent to the API without actually calling it
- **Regression testing**: verify a model still produces acceptable output on a known conversation

## Setup

Set provider API keys as environment variables:

```bash
export ANTHROPIC_API_KEY=sk-ant-...   # for Claude models
export GOOGLE_API_KEY=AIza...          # for Gemini models
```

Or configure in `~/.config/logfire-trace/config.yaml` under `ai_providers`.

## Flags

```
lft replay <source> [flags]
```

| Flag | Alias | Default | Purpose |
|------|-------|---------|---------|
| `--position` | `-p` | `last` | Which message to target (see below) |
| `--input` | `-i` | -- | File whose content replaces the targeted message |
| `--output` | `-o` | stdout | Save JSON result to file |
| `--model-override` | `-m` | -- | Use a different model (auto-detects provider) |
| `--count` | `-n` | `1` | Number of concurrent completions |
| `--dry-run` | -- | false | Show the request without calling the API |
| `--turns` | -- | false | Show conversation turn map and exit (no API call) |
| `--profile` | -- | default | Logfire profile for remote trace fetch |

**Source** can be a local JSON file, a Logfire URL, or a 32-char hex trace ID.

## Position Values (-p)

| Value | Without `-i` (truncate) | With `-i` (replace) |
|-------|------------------------|---------------------|
| `last` | Remove last assistant turn, regenerate | Replace last user message, regenerate |
| `system` | Keep system + first user only | Replace system prompt, regenerate |
| `user:N` | Remove from Nth user message onward | Replace Nth user message, truncate after |
| `assistant:N` | Remove from Nth assistant message onward | Replace Nth assistant message, truncate after |

N is 0-based: `user:0` is the first user message, `user:1` is the second.

## Examples

### Regenerate the last response

```bash
lft replay trace.json
```

### Tweak the system prompt

```bash
echo "You are a concise assistant. Keep responses under 50 words." > concise.txt
lft replay trace.json -p system -i concise.txt -o result.json
```

### Replace a user message

```bash
echo "What are your store hours?" > question.txt
lft replay trace.json -p user:0 -i question.txt
```

### Re-ask from earlier in the conversation

```bash
lft replay trace.json -p user:1
```

### Generate multiple variations

```bash
lft replay trace.json -n 3 -o variations.json
cat variations.json | jq '.results[].response.content[:80]'
```

### Cross-provider comparison

```bash
lft replay trace.json -m gemini-2.5-flash -o gemini.json
cat gemini.json | jq '.results[0].response | {input_tokens, output_tokens}'
```

### Show conversation turn map

```bash
lft replay trace.json --turns
#   system         "You are a shopping assistant..."  (2,847 chars)
#   user:0         "I'm looking for a red dress"      (28 chars)
#   assistant:0    [text + 2 tool_use: product_search] (1,204 chars)
#   tool:0         [2 tool_result]                     (3,891 chars)
#   assistant:1    "Here are some options..."           (412 chars)
#   user:1         "Show me the second one"             (22 chars)
```

### Dry run (inspect without sending)

```bash
lft replay trace.json --dry-run | jq '.request.messages | length'
```

### Replay from a remote trace

```bash
lft replay 019b93fef58a772e9ce3b26b756ced88
lft replay 019b93fef58a772e9ce3b26b756ced88 --profile prod
```

### Combine everything

```bash
lft replay trace.json \
  -p system -i prompt.txt \
  -m gemini-2.5-flash \
  -n 2 \
  -o result.json
```

## Get Command Flags

| Flag | Description |
|------|-------------|
| `-s, --summary` | Show AI conversation summary (view mode) |
| `-t, --tree` | Show span tree (view mode) |
| `-a, --all` | Include all spans (not just AI) |
| `-o, --output` | Custom output path |
| `--stdout` | Output JSON to stdout (no file save) |
| `-p, --profile` | Select profile |
| `-c, --chat` | Fetch by Firestore chat ID |
| `-u, --user` | Fetch latest chat by user email |
| `--env` | Firestore environment: `uat` (default), `prod` |
| `-f, --full` | No truncation in summary |
| `--tools` | Expand tool call args/results in summary |
| `--model` | Filter by model name |
| `--errors` | Only show exception spans |
| `--depth N` | Max tree depth (0 = unlimited) |
| `--no-attrs` | Hide attributes in tree view |
| `--html` | Render to HTML using Quarto |
| `--open` | Open rendered HTML in browser (requires `--html`) |
| `--no-color` | Disable colored output |
| `-V, --verbose` | Show query and span counts |

## Prompt Debugging Workflows

### Bug vs randomness triage

```bash
lft replay <trace_or_url> -n 3 -o triage.json
cat triage.json | jq '.results[] | {index, content: .response.content[:200]}'
```

- **0/3 correct** -- deterministic bug, investigate prompt/tools
- **1-2/3 correct** -- stochastic, consider prompt reinforcement or temperature
- **3/3 correct** -- original was a one-off

### Iterating on a prompt fix

```bash
# 1. Extract current system prompt
lft replay <trace> --dry-run -o dry.json
jq -r '.request.system' dry.json > original_system.txt

# 2. Edit
cp original_system.txt fixed_system.txt
# ... make your targeted edit ...

# 3. Replay and compare
lft replay <trace> -p system -i fixed_system.txt -n 2 -o fixed.json
cat fixed.json | jq -r '.results[].response.content[:500]'
```

## Known Limitations

1. **Tool definitions are included automatically** -- replay extracts tool schemas from `ai.prompt.tools` in the span data.
2. **Gemini rejects tool history** -- traces with tool-call/tool-result messages cause errors. Workaround: use `-p user:0` or `-p system` to truncate past tool calls.
3. **Cross-model comparison is text-only** -- for agentic conversations with tool use, stick to same-provider replay.
4. **Only Anthropic and Google supported** -- other providers return an error.
5. **No streaming** -- responses arrive all at once.
