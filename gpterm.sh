#!/bin/bash
# Script tp call 
# Uses jq to parse the JSON response from OpenAI's API

ARG="$1"
output=$(curl -s https://api.openai.com/v1/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d "{
  \"model\": \"text-davinci-003\",
  \"prompt\": \"Write a ${SHELL##*/} command to ${ARG} \n\n###\n\n\",
  \"temperature\": 0,
  \"max_tokens\": 200,
  \"top_p\": 1,
  \"frequency_penalty\": 0,
  \"presence_penalty\": 0,
  \"stop\": [\"\\n\\n###\\n\\n\"]
}")

text=$(echo "$output" | jq -r '.choices[0].text')

# If text is empty or  "null", print the output
if [ -z "$text" ] || [ "$text" = "null" ]; then
  echo "$output"
else
  echo "$text"
fi