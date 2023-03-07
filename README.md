# GPTerm

Command line tool for generating prompts to perform tasks in the terminal. 
ex. `gpterm "Move all jpegs to a new folder called images` -> `mkdir images && mv *.jpg images`

## WARNING
This is a work in progress. The AI may output commands that are dangerous to run. The AI is also not perfect. It may output commands that are not what you want. Please check the output before running the command. There exist several potential improvements that can be made, by way of altering the fine_tuning dataset, tweaking hyperparameters, and prompt engineering.

Your zsh_history or bash_history file will be read and parsed into a dataset for finetuning the model. The dataset will be saved LOCALLY to data/finetuning_dataset.txt. The finetuned model will then be sent to the OpenAI fine tuning API using your API key. The model after fine tuning will be used to generate prompts for the user to perform tasks in the terminal. The user can then enter the prompt and the fine tuned model will fetch the command. 

Know that, from terminal commands history, any API keys, ssh details, instance IPs, or any other private information will sent to the OpenAI API. OpenAI has a [privacy policy](https://beta.openai.com/privacy). Please be aware of the privacy limitations of the API you are using.

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
        python3.11 generate_finetuning_dataset.py -n 1000

        # This will prepare the dataset for finetuning the model. It will store the prepared dataset in data/finetuning_dataset_prepared.jsonl
        openai tools fine_tunes.prepare_data -f ./data/finetuning_dataset.jsonl

        # Create a Finetuned model using the created dataset (this often takes minutes, but can take hours if there are many jobs in the queue or your dataset is large)
        openai api fine_tunes.create -t "./data/finetuning_dataset_prepared.jsonl"

        # Finally, specify the fine tuned model id in an environment variable
        export OPENAI_FINETUNED_MODEL_ID=<your finetuned model id>

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

3. The fine tuned model is used to generate prompts for the user to perform tasks in the terminal. The user can then run the prompt and the fine tuned model will complete the command. The hope is that through fine tuning, the model will be able to generate prompts that have more contextual accuracy than a general base model.

ex:
    ```bash
        # user input
        gpterm "rename all files in the current directory to lowercase"

        for file in *; do mv -- "$file" "${file:l}"; done
    ```