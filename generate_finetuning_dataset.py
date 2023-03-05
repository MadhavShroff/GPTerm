#!/usr/bin/env python3
import argparse
import os
import requests
from pprint import pprint
import random

current_shell = os.getenv('SHELL').split('/')[-1] # e.g. bash, zsh, etc.
# Create data directory if it doesn't exist
if not os.path.exists('./data'):
    os.mkdir('./data')
input_file = './data/history_data.txt'
output_file = './data/finetuning_dataset.txt'
key = os.getenv('OPENAI_API_KEY')

# Set default value for number of calls
default_number_of_calls = 3

parser = argparse.ArgumentParser(description='Curl calls for shell script descriptions.')
parser.add_argument('-n', '--num-pairs', default=default_number_of_calls, type=int,
                    help=f'number of curl calls to make, default: {default_number_of_calls}')
args = parser.parse_args()

with open(input_file, 'r') as f_in:
    lines = f_in.readlines()

# Print error message and exit if input file is empty
if len(lines) == 0:
    print(f'Error: {input_file} is empty.')
    exit(1)

count = 0
with open(output_file, 'a+') as f_out:
    for command_i in random.sample(lines, args.number_of_calls):
        if count >= args.number_of_calls:
            break

        command_i = command_i.strip()
        pprint("Request:")
        pprint(f'Give a one line description of this {current_shell} shell script: "{command_i}"')
        # command_i = "git clone https://github.com/MadhavShroff/HypothesizerDebugger; open HypothesizerDebugger; cd Hypothesizer; git add .; git commit -m \"Updated UI\""
        response = requests.post('https://api.openai.com/v1/chat/completions', headers={
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {key}'
        }, json={
            'model': 'gpt-3.5-turbo',
            'messages': [
                {'role': 'system', 'content': 'Output a single sentence, first-person prompt that preceeds the shell script the user provides. Brevity is key.'},
                {'role': 'user', 'content': f'Write the natural task description that may produce this {current_shell} shell script: "mkdir images && mv *.jpg images"'},
                {'role': 'system', 'content': 'Move all jpegs to a new folder called images'},
                {'role': 'user', 'content': f'Write the natural task description that may produce this {current_shell} shell script: "{command_i}"'},
            ]
        }).json()
        pprint(response)
        prompt_completion = {
          "completion": command_i,
          "prompt": response['choices'][0]['message']['content']
        }
        f_out.write(str(prompt_completion) + '\n')
        count += 1