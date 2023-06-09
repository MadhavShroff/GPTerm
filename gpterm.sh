#!/bin/bash
# Script to call
# Uses jq to parse the JSON response from OpenAI's API

APPEND_SYS_FILE="$HOME/.gpterm_append_sys"
CONFIG_FILE="$HOME/.gpterm_config"

# Check if config file exists, otherwise create it with a default model
if [ ! -f "$CONFIG_FILE" ]; then
  echo "text-davinci-003" > "$CONFIG_FILE"
fi

APPEND_SYS=""
if [ -f "$APPEND_SYS_FILE" ]; then
  APPEND_SYS=$(cat "$APPEND_SYS_FILE")
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

call_gpt4() {
  curl -s https://api.openai.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d "{
    \"model\": \"gpt-4\",
    \"messages\": [
      {\"role\": \"system\", \"content\": \"You generate ${SHELL##*/} code or commands that perform the task given by the user. You reply with the command string only, with no other text except the command to execute that will successfully perform the task given by the user. Think about the answer step by step, but in the end give the user only the command(s) they need to accomplish their task. ${APPEND_SYS}\"},
      {\"role\": \"user\", \"content\": \"Compile all Java files in the current directory, then start a new server listening on port 8000 with Main class as the entry point.\"},
      {\"role\": \"assistant\", \"content\": \"javac *.java;\"},
      {\"role\": \"user\", \"content\": \"Download this youtube video:https://www.youtube.com/watch?v=Ff4fRgnuFgQ&ab_channel=LexFridman and crop the length from 31:24 to 31:52\"},
      {\"role\": \"assistant\", \"content\": \"yt-dlp --exec 'ffmpeg -i {} -ss 00:31:24 -to 00:31:52 -c copy {}.mp4' https://www.youtube.com/watch?v=Ff4fRgnuFgQ&ab_channel=LexFridman --keep-video --embed-subs\"},
      {\"role\": \"user\", \"content\": \"${ARG}\"}
    ]
  }"
}

add_append_sys() {
  echo "$1" >> "$APPEND_SYS_FILE"
  echo "Append system prompt successfully added"
}

while getopts "m:a:lh" opt; do
  case $opt in
    m)
      # check if the model is valid
      if [ "$OPTARG" != "text-davinci-003" ] && 
         [ "$OPTARG" != "gpt-3.5-turbo" ] &&
         [ "$OPTARG" != "gpt-4" ] &&
         [ "$OPTARG" != "gpt4" ]; then
        echo "ERROR: Invalid model, use -l to list the available models"
        exit 1
      fi
      MODEL="$OPTARG"
      echo "$MODEL" > "$CONFIG_FILE"
      echo "Model successfully updated to $MODEL"
      exit 0
      ;;
    a)
      add_append_sys "$OPTARG"
      exit 0
      ;;
    l)
      echo "text-davinci-003"
      echo "gpt-3.5-turbo"
      echo "gpt-4"
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
elif [ "$MODEL" = "gpt-4" ] || [ "$MODEL" = "gpt4" ]; then
  output=$(call_gpt4)
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
elif [ "$MODEL" = "gpt-4" ] || [ "$MODEL" = "gpt4" ]; then
  text=$(echo "$output" | jq -r '.choices[0].message.content')
fi

# If text is empty or "null", print the output
if [ -z "$text" ] || [ "$text" = "null" ]; then
  echo "$output"
else
  echo "$text"
fi
