#!/bin/bash
#transform the list of files into the array format

allBenchs=("KNAPSACK" "U-KNAPSACK" "MINMAX")
numFuncs=3

tmux new-session -d  -c "$HOME/Documentos/programming/python/idlhc-code" -s ${allBenchs[$1]}
for ((i=0; i <= $numFuncs; i++)); do
	tmux new-window -t ${allBenchs[$1]} "$HOME/.conda/envs/idlhc_updated_env/bin/python main_tcc.py 30 $i ${allBenchs[$1]} 0 1"
	echo ""
done

