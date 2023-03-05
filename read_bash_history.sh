#!/bin/bash
HISTFILE=~/.bash_history
set -o history
history | sed 's/^ *[0-9]* *//' > data/history_data.txt