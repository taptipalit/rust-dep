## Framework for static program analysis for Rust

### Generate callgraph 

Prerequisite: The Rust compiler toolchain is installed on the system. 

Tested with: RustC version: 1.75.0, LLVM version: 17.0.6

1. Run `./run.sh` 

This script will --

a) Download and compile the LLVM compiler used by the Rust
compiler toolchain. We need this to build the LLVM pass. 

b) Clone the `ripgrep` repository and build it while generating the LLVM IR.

c) Compile the `callgraph-pass` LLVM pass. 

d) Analyze the LLVM IR with our `callgraph-pass` LLVM pass. 

e) Generate the JSON file for the callgraph.

2. To clean up the installation, run `./cleanup.sh`

### Known Issues

1. Symbol-name mangling has issues. 
The LLVM IR has strange Unicode encodings for function names. If you generate
the text LLVM IR format file then it has comments that contain the unmangled
names. But some seem missing.
2. TODO: add more attributes to the JSON file.
