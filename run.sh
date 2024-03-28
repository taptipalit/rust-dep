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

echo "export PATH=\"/home/tpalit/.cargo/bin:$BIN_PATH:$PATH\"" >> ~/.bashrc
echo "export LLVM_DIR=\"$BIN_PATH\"" >> ~/.bashrc
echo "export LLVM_HOME=\"$BIN_PATH\"" >> ~/.bashrc

source ~/.bashrc



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

cargo rustc -- --emit=llvm-ir

cd ../..



