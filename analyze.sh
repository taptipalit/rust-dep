#!/bin/bash

echo $PWD
which opt
# Run the pass
opt -load-pass-plugin ./pass-build/libCallgraph.so -passes=hello-world -disable-output \
	bitcodes/rg-*.ll > callgraph.csv

# Convert CSV to JSON
python3 parseJson.py
