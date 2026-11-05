#!/usr/bin/env bash

CWD="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

OLLAMA_HOST=${OLLAMA_HOST:-"http://localhost:11434"}

SYS='You are a terse coding assistant. Answer only what was asked.
- No greetings, no preamble, no restating the question, no closing summary.
- Prose: max 3 short sentences. Use a list only if the answer is genuinely a list.'

MODEL=
select_model() {
  local models=()
  readarray -t models < <(curl -sf "$OLLAMA_HOST/api/tags" | jq -r '.models[].name')
  if [ "${#models[@]}" -eq 0 ]; then
    echo "No model available in ollama." >&2
    exit 1
  elif [ "${#models[@]}" -eq 1 ]; then
    MODEL=${models[0]}
  else
    MODEL=$(printf '%s\n' "${models[@]}" | fzf)
  fi

  if [ -z "$MODEL" ]; then
    echo "No model selected, exiting..."
    exit 0
  fi
}
select_model

send_message() {
  local prompt=$1
  jq -nc \
    --arg model "$MODEL" \
    --arg sys "$SYS" \
    --arg prompt "$prompt" \
    '{
      model:$model,
      stream:true,
      messages:[
        {role:"user",content:$prompt},
        {role:"system",content:$sys}
      ],
      options:{temperature:0.3,num_predict:400}
    }' |
    curl -sfN "$OLLAMA_HOST/api/chat" -d @- |
    jq --unbuffered -j '.message.content // empty'
}

SESSION="bash-harness-$(date +%s)"
SESSION_DIR="$CWD/sessions/$SESSION"
mkdir -p "$SESSION_DIR"
touch "$SESSION_DIR/chat.txt"

while true; do
  IFS= read -r -p "> " USER_PROMPT
  if [ -z "$USER_PROMPT" ]; then
    continue
  fi

  tmp=$(mktemp)

  CONTEXT=$(tail -100 "$SESSION_DIR/chat.txt")
  FULL_PROMPT=$(printf '%s\nUser: %s' "$CONTEXT" "$USER_PROMPT")

  printf '%s' 'Agent: '
  send_message "$FULL_PROMPT" | tee "$tmp"
  printf '\n'


  RES=$(cat "$tmp")

  printf '%s\n\n' "User: $USER_PROMPT" >>"$SESSION_DIR/chat.txt"
  printf '%s\n\n' "Agent: $RES" >>"$SESSION_DIR/chat.txt"

  rm "$tmp"
done
