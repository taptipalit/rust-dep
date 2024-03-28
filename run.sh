#!/bin/bash

which rustc

if [ $? -ne 0 ]; then
	echo "Rust not found. Can't proceed"
	exit -1
fi

# We need gold linker to link it without crapping out due to memory

git clone --depth 1 git://sourceware.org/git/binutils-gdb.git binutils
mkdir gold-build
cd gold-build
../binutils/configure --enable-gold --enable-plugins --disable-werror
make all-gold -j8


cd ..
# change the system-wide linker after backing it up
mv /usr/bin/ld /usr/bin/ld-bkup
ln -s "$(realpath ./gold-build/gold/ld-new)" /usr/bin/ld

VER=$(rustc --version --verbose | grep 'LLVM' | awk '{ print $3}')
if [ ! -d llvm ]; then
	mkdir llvm
	cd llvm
	set -x
	export \
		URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-$VER/llvm-project-$VER.src.tar.xz" \
		&& export LLVM_ARCHIVE="llvm-project-$VER.src.tar.xz" \
		&& export LLVM_SRC="llvm-project-$VER.src" \
		&& wget $URL

	tar Jxvf $LLVM_ARCHIVE

	cd $LLVM_SRC

	cmake -S llvm -B release-build -G "Unix Makefiles" \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_ENABLE_DUMP=ON -DLLVM_ENABLE_FFI=ON \
		-DLLVM_ENABLE_PROJECTS="clang;compiler-rt;lld" 

	cd release-build
	make -j8
	cd ../../..
fi


BIN_PATH=$(realpath "./llvm/llvm-project-$VER.src/release-build/bin")

# Add LLVM to PATH
export PATH="/home/tpalit/.cargo/bin:$BIN_PATH:$PATH"
export LLVM_DIR="$BIN_PATH"
export LLVM_HOME="$BIN_PATH"

if [ ! -d projects ]; then
	mkdir projects
fi

cd projects

if [ ! -d ripgrep ]; then
	git clone https://github.com/BurntSushi/ripgrep.git
	cd ripgrep
else
	cd ripgrep
	git pull
fi

exit 0
cargo rustc -- --emit=llvm-ir

cd ../..
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
