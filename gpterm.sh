#!/bin/bash
# Script to call
# Uses jq to parse the JSON response from OpenAI's API

CONFIG_FILE="$HOME/.gpterm_config"

# Check if config file exists, otherwise create it with a default model
if [ ! -f "$CONFIG_FILE" ]; then
  echo "text-davinci-003" > "$CONFIG_FILE"
fi

# Read the current model from the config file
MODEL=$(cat "$CONFIG_FILE")

call_gpt() {
  curl -s https://api.openai.com/v1/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d "{
    \"model\": \"$MODEL\",
    \"prompt\": \"Write a ${SHELL##*/} command to ${ARG} \n\n###\n\n\",
    \"temperature\": 0,
    \"max_tokens\": 200,
    \"top_p\": 1,
    \"frequency_penalty\": 0,
    \"presence_penalty\": 0,
    \"stop\": [\"\\n\\n###\\n\\n\"]
  }"
}

call_gpt35_turbo() {
  curl -s https://api.openai.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d "{
    \"model\": \"gpt-3.5-turbo\",
    \"messages\": [
      {\"role\": \"system\", \"content\": \"You generate ${SHELL##*/} code or commands that perform the task given by the user. You reply with the command string only, with no other text except the command to execute that will successfully perform the task given by the user.\"},
      {\"role\": \"user\", \"content\": \"${ARG}\"}
    ]
  }"
}

while getopts "m:lh" opt; do
  case $opt in
    m)
      # check if the model is valid
      if [ "$OPTARG" != "text-davinci-003" ] && 
         [ "$OPTARG" != "gpt-3.5-turbo" ]; then
        echo "ERROR: Invalid model, use -l to list the available models"
        exit 1
      fi
      MODEL="$OPTARG"
      echo "$MODEL" > "$CONFIG_FILE"
      echo "Model successfully updated to $MODEL"
      exit 0
      ;;
    l)
      echo "text-davinci-003"
      echo "gpt-3.5-turbo"
      exit 0
      ;;
    h|*)
      echo "Usage: $(basename "$0") [-m model] [-l] [-h] arg"
      exit 0
      ;;
  esac
done

# Remove the parsed options from the positional parameters
shift $((OPTIND-1))

ARG="$1"

if [ "$MODEL" = "gpt-3.5-turbo" ]; then
  output=$(call_gpt35_turbo)
else
  output=$(call_gpt)
fi

if [ -z "$output" ]; then
  echo "ERROR: curl returned an empty response"
  # stop execution of the script
  exit 1
fi

# Check the model used and parse the output accordingly
if [ "$MODEL" = "gpt-3.5-turbo" ]; then
  text=$(echo "$output" | jq -r '.choices[0].message.content')
elif [ "$MODEL" = "text-davinci-003" ]; then
  text=$(echo "$output" | jq -r '.choices[0].text')
fi

# If text is empty or "null", print the output
if [ -z "$text" ] || [ "$text" = "null" ]; then
  echo "$output"
else
  echo "$text"
fi
