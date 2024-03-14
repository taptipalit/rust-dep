#!/bin/bash

if [ ! -f llvm ]; then
	mkdir llvm
fi

cd llvm

rustc --version --verbose | grep 'LLVM' | awk '{ print $3}' \
  |	xargs echo \
	"https://github.com/llvm/llvm-project/releases/download/llvmorg-$1/llvm-$1.src.tar.xz" \
	| export LLVM_ARCHIVE="llvm-$1.src.tar.xz" \
	| export LLVM_SRC="llvm-project-$1.src" \
	| wget $1

tar Jxvf $LLVM_ARCHIVE

cd $LLVM_SRC

cmake -S llvm -B release-build -G "Unix Makefiles" \
	-DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_DUMP=ON -DLLVM_ENABLE_FFI=ON \
  -DLLVM_ENABLE_PROJECTS="clang;compiler-rt;lld" 

cd release-build
make -j8

if [ ! -f projects ]; then
	mkdir projects
fi

