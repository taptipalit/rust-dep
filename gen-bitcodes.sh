#!/bin/bash

rm bitcodes/*
if [ ! -d bitcodes ]; then
	mkdir bitcodes
fi
find . -name "rg-*.ll" -exec cp {} ./bitcodes \;

cd bitcodes

find . -type f -name "rg-*.ll" -print0 | while IFS= read -r -d '' file; do
  rustfilt < "$file" > "$file.processed"
done

cd ..

echo $PWD

# Build the pass
rm -rf pass-build
mkdir pass-build
cd pass-build
cmake -DLT_LLVM_INSTALL_DIR=$LLVM_DIR $(realpath ../callgraph-pass/Callgraph/)
make

echo $PWD
which opt
cd ../
# Run the pass
opt -load-pass-plugin ./pass-build/libCallgraph.so -passes=hello-world -disable-output \
	bitcodes/rg-*.ll > callgraph.csv

# Convert CSV to JSON
python3 parseJson.py
