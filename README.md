# GPTerm

Command line tool for generating POSIX Shell commands from Natural language prompts to perform tasks in the terminal. 

For example, 
`$ gpterm "Move all jpegs to a new folder called images` -> `mkdir images && mv *.jpg images`

The default mode of operation uses text-davinci-003, as it shows the best performance. The model used can be modified in gpterm.sh

The zsh_history or bash_history file will be read and parsed into a dataset for finetuning the model. The dataset will be saved to data/finetuning_dataset.txt. The finetuned model will then be sent to the OpenAI fine tuning API using your API key. This adds contextual awareness to the model, making it more useful. 

Know that, from terminal commands history, any API keys, ssh details, instance IPs, or any other private information will sent to the OpenAI API. OpenAI has a [privacy policy](https://beta.openai.com/privacy). Please be aware of the privacy limitations of the API you are using.

Note: OpenAi currently does not support fine tuning of the gpt-3.5-turbo model or any of the codex models. Fine tuning on the davinci models is available, but its performance and accuracy is not as good as the untuned gpt-3.5-turbo model. (Tested on 1121 prompt-completion pairs)
Hopefully, finetuning of the codex models when allowed will 

## Installation
    
        1. Clone the repository
        $ git clone https://github.com/MadhavShroff/GPTerm
        $ cd gpterm

        2. Read, clean and write your zsh_history file into data/history_data.txt. 
        (To skip the history gathering part, go to step 5. The text-davinci-003 model is used, and it's performance is decent out of the box)

        If using bash
        $ bash read_bash_history.sh
        
        If using zsh
        $ python3.11 read_zsh_history.py 

        3. Receive an API Key ("sk-...") from OpenAi and store in environment variable 
        export OPENAI_API_KEY=<your openai api key>

        4a. (Optionally) generate a dataset for finetuning the model, stores (pair, completion) pairs in data/finetuning_dataset.txt. -n or --num-pairs is the number of pairs to generate. use '-sc' or '--shellcheck' (0/1) to disable/enable shellcheck. You must have it installed if using this option. 
        (Note: This will take some time if you are on OpenAi's the free trial, as rate limiting is in effect) 
        $ python3.11 generate_finetuning_dataset.py -n 1000

        4b. Prepare the dataset for finetuning the model. This command will store the prepared dataset in data/finetuning_dataset_prepared.jsonl
        $ openai tools fine_tunes.prepare_data -f ./data/finetuning_dataset.jsonl

        4c. Create a Finetuned model using the generated dataset (this often takes minutes, but can take hours if there are many jobs in the queue or your dataset is large)
        $ openai api fine_tunes.create -t "./data/finetuning_dataset_prepared.jsonl"

        4d. Finally, specify the fine tuned model id in an environment variable
        $ export OPENAI_FINETUNED_MODEL_ID=<your finetuned model id>

        5. Install the command line tool (The tool will be installed even if finetuning is not performed)
        $ bash install.sh

        6. Run the command line tool
        $ gpterm "rename all files in the current directory to lowercase"
        ╰─ for file in *; do mv -- "$file" "${file:l}"; done
        
(Note: You must copy the returned text and paste it in the command line to run it.)

## WARNING
This is a work in progress. The AI may output commands that are dangerous to run. The AI is also not perfect. There are no guardrails to prevent it from returning dangerous code that may delete or modify files irreparably. Please check the output before running the command. There exist several potential improvements that can be made, by way of altering the fine_tuning dataset, tweaking hyperparameters, and prompt engineering.

## How it is built

GPTerm is built using the [GPT-3](https://openai.com/blog/openai-api/) API. The idea is to use a finetuned model of the API to generate prompts for the user to perform tasks in the terminal. The fine tuning is done using the zsh_history or bash_history files. The prompt-completion pairs are generated using openai's code description API. Yes, AI is used to finetune a different AI. Open to PRs debtaing philosophical implications. 

1. On install, config setup will find the zsh_history or bash_history file. Each command from your shell history is sent to OpenAI's gpt-3.5-turbo chat completion API. It generates the Natural Language description of the command, and generates a prompt completion pair as such: 

    ```JSON
        [{
            "prompt": "Compile all Java files in the current directory, then start a new server listening on port 8000 with Main class as the entry point.\n\n###\n\n", 
            "completion": " javac *.java; java -cp . Main server start 8000;\n\n###\n\n"
        }]
    ```
    
The list of prompt-completion pairs are then saved to a .jsonl file. See data/finetuning_dataset.txt for an example.

2. The base davinci model is fine tuned using the prompt-completion pairs. The fine tuned model id is then saved to an environment variable.

3. The fine tuned model is used to generate contextually aware commands for the user to perform tasks in the terminal.

For example :

    $ gpterm "rename all files in the current directory to lowercase"
    ╰─ for file in *; do mv -- "$file" "${file:l}"; done
