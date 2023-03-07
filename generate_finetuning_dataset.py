#!/usr/bin/env python3
import argparse
import os
import requests
from pprint import pprint
import random
import json
import time
import subprocess

# current_shell = os.getenv('SHELL').split('/')[-1] # e.g. bash, zsh, etc.
current_shell = 'bash'

# Specify input and output files
input_file = './data/history_data.txt'
output_file = './data/finetuning_dataset.jsonl'
# Get OpenAI API key from environment variable
key = os.getenv('OPENAI_API_KEY')
# Create data directory if it doesn't exist
if not os.path.exists('./data'):
    os.mkdir('./data')
# Set default value for number of calls
default_number_of_calls = 5
min_command_length = 2

# Parse arguments
parser = argparse.ArgumentParser(description='Curl calls for shell script descriptions.')
# Argument for number of API calls to make. Default value is 5.
parser.add_argument('-n', '--num-pairs', default=default_number_of_calls, type=int, help=f'number of curl calls to make, default: {default_number_of_calls}')
# Argument for 0/1 flag to use shellcheck for generating fine_tuning_dataset
parser.add_argument('-sc', '--shellcheck', default=1, type=int, help=f'0: do not use shellcheck, 1: use shellcheck, default: 0')
args = parser.parse_args()

# Read input file
# TODO: Add interactive mode to allow user to choose from a random sample of commands
# Interactive mode allows user to enter the size of the sample
# Interactive mode allows user to generate random samples until they are satisfied with the sample
# Interactive mode also allows user to choose whether to use shellcheck or not
# Interactive mode is optional. Default parameter values can be used to generate the dataset. 
# defaults: sample_size = 5, use_shellcheck = False. 
def get_lines(input_file):
    # Create a temp file 
    if not os.path.exists("./temp") and args.shellcheck == 1:
        os.system(f'touch temp')

    # Method to check if syntax of a (bash) command is valid
    def is_valid_command(command):
        command = f'#!/bin/{current_shell} \n {command}'
        with open("./temp", "w") as f:
            f.write(command)
        # Assert that current shell is bash
        # TODO: Add support for other shells
        assert current_shell == 'bash'
        # run shellcheck on temp file, suppress output
        res = subprocess.call(["shellcheck", "./temp", "-f", "json"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        open("./temp", "w").close()
        return res == 0
    
    def remove_duplicates(commands):
        seen = set()
        for command in commands:
            if command not in seen:
                seen.add(command)
                yield command

    # read lines from input file (history_data.txt)
    with open(input_file, 'r') as f_in:
        lines = f_in.readlines()
    if len(lines) == 0:
        print(f'Error: {input_file} is empty.')
        exit(1)
    if(args.num_pairs > len(lines)):
        print(f'Warning: {args.num_pairs} is greater than the number of lines in {input_file}.')
        print(f'Using {len(lines)} lines instead.')
        args.num_pairs = len(lines)
    
    # Randomly sample lines from input file
    sample = random.sample([x for x in lines if len(x) >= min_command_length], args.num_pairs)
    # remove duplicate commands
    sample = list(remove_duplicates(sample))
    # If shellcheck is enabled, filter out invalid commands
    if args.shellcheck == 1:
        sample = [command for command in sample if is_valid_command(command)]
        os.system(f'rm temp')
    return sample

def call_openai_api(command):
    return requests.post('https://api.openai.com/v1/chat/completions', headers={
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {key}'
    }, json={
        'model': 'gpt-3.5-turbo',
        'messages': [
            {'role': 'system', 
                'content': 'Write a one-line, first-person prompt that preceeds the shell script provided by the user. \
                Brevity is key. If the script is invalid, the prompt should be ERROR only.'},
            {'role': 'user', 'content': f'Write the natural task description that may produce this {current_shell} shell script: "mkdir images && mv *.jpg images"'},
            {'role': 'system', 'content': 'Move all jpegs to a new folder called images'},
            {'role': 'user', 'content': f'Write the natural task description that may produce this {current_shell} shell script: "{command}"'},
        ]
    }).json()


def generate_finetuning_dataset():
    count = 0
    with open(output_file, 'a+') as f_out:
        for command_i in get_lines(input_file):
            if count >= args.num_pairs:
                break

            command_i = command_i.strip()
            if command_i == 'cd' or command_i == 'ls' or command_i == 'pwd' :
                print(f'Skipping {command_i}.')
                continue
            print(f'Requested   : {command_i}')
            response = call_openai_api(command_i)
            # if error, print error message and continue
            if 'error' in response and 'message' in response['error'] and response['error']['message'].startswith('Rate limit reached') :
                print(f'Error: Rate limit reached. Sleeping for 20 seconds.')
                time.sleep(20)
                response = call_openai_api(command_i)
            if 'choices' in response and response['choices'][0]['message']['content'].startswith("ERROR") :
                print(f'Error: Invalid command {command_i}')
                continue
            if 'choices' in response and 'content' in response['choices'][0]['message'] :
                try :
                    print("Response    : " + response['choices'][0]['message']['content'])
                    prompt_completion = {
                        "prompt": response['choices'][0]['message']['content'] + "\n\n###\n\n",
                        "completion": " " + command_i + "\n\n###\n\n"
                    }
                    # Convert to JSON string using json.dumps() and write to file
                    f_out.write(json.dumps(prompt_completion) + '\n')
                    count += 1
                except:
                    print(response)
            else :
                print(response)

if __name__ == '__main__':
    generate_finetuning_dataset()