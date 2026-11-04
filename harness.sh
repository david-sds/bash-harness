#!/usr/bin/env bash

CWD="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INITIAL_USER_PROMPT=$1
MODEL="qwen3-coder:30b"
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

  CONTEXT=$(tail -30 "$SESSION_DIR/chat.txt")
  FULL_PROMPT=$(printf '%s\nUser: %s' "$CONTEXT" "$USER_PROMPT")

  printf 'Agent: '
  ollama run --nowordwrap "$MODEL" "$FULL_PROMPT" | tee "$tmp"

  RES=$(cat "$tmp")

  printf '%s\n\n' "User: $USER_PROMPT" >> "$SESSION_DIR/chat.txt"
  printf '%s\n\n' "Agent: $RES" >> "$SESSION_DIR/chat.txt"

  rm "$tmp"
done
