# GPTerm

Command line tool for generating prompts to perform tasks in the terminal. 
ex. `gpterm "Move all jpegs to a new folder called images` -> `mkdir images && mv *.jpg images`

## Installation
    
    ```bash
        # So far...
        git clone https://github.com/MadhavShroff/GPTerm
        cd gpterm
        python3.11 -m venv venv
        source venv/bin/activate
        pip3 install openai
        python3.11 read_zsh_history.py # This will read and parse your zsh_history file into data/history_data.txt
        export OPENAI_API_KEY=<your openai api key>

        # This will generate a dataset for finetuning the model, stores (pair, completion) pairs in data/finetuning_dataset.txt. -n or --num-pairs is the number of pairs to generate
        python3.11 generate_finetuning_dataset.py -n 100 

        # Things yet to implememnt:

        # Finetune the model using the created dataset
        # The finetuned model reference is stored, and used to generate commands based on user input
        python3.11 finetune_model.py

        # Finally, use the finetuned model to generate commands based on user input
        python3.11 generate_command_example.py

        # Install the command line tool
        python3.11 setup.py install

        # To run the command line tool
        gpterm "rename all files in the current directory to lowercase"

        -> for file in *; do mv -- "$file" "${file:l}"; done
    ```

## How it (will be) built

GPTerm is built using the [GPT-3](https://openai.com/blog/openai-api/) API. The idea is to use a finetuned model of the API to generate prompts for the user to perform tasks in the terminal. The fine tuning is done using the zsh_history or bash_history files. The prompt-completion pairs are generated using openai's code description API. 

1. On install, config setup will find the zsh_history or bash_history file. It will be compiled into a list of prompts for the code description API. The API returns a list of completions for the prompt. ex: 

    ```JSONL
        [{
            "command": "ssh user1@178.34.25.24 -i ~/.ssh/id_rsa",
            "potential prompt": "ssh into server 178.34.25.24 as user1 using my private key"
        } ...]
    ```
    
The prompt-completion pairs are then saved to a file. An example is in data/finetuning_dataset.txt. 

2. The base gpt3 model is fine tuned using the prompt-completion pairs. The fine tuned model is then saved to a file.

3. The fine tuned model is used to generate prompts for the user to perform tasks in the terminal. The user can then run the prompt and the fine tuned model will complete the command. ex:

    ```bash
        # user input
        gpterm "rename all files in the current directory to lowercase"

        for file in *; do mv -- "$file" "${file:l}"; done
    ```