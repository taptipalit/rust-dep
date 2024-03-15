## Framework for static program analysis for Rust

# Generate callgraph 

Prerequisite: The Rust compiler toolchain is installed on the system. 

1. Run `./run.sh` 

This script will --

a) Download and compile the LLVM compiler used by the Rust
compiler toolchain. We need this to build the LLVM pass against. 

b) Clone the `ripgrep` repository and build it while generating the LLVM IR.

c) Analyze the LLVM IR with our `callgraph-pass` LLVM pass. 

d) Generate the JSON file for the callgraph.

2. To clean up the installation, run `./cleanup.sh`
