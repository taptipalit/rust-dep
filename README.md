## Framework for static program analysis for Rust

## Option 1: Use the Docker container

1. Pull the container image.

`docker pull taptipalit/rust-dep`

2. Launch the container

`docker run -it taptipalit/rust-dep:latest bash` 

3. Run the analysis

`./analyze.sh`

This generates the output in `callgraph.json`.

### Analyze a new application

1. Git clone the repo and `cd` into it. 

2. Run `cargo rustc -- --emit=llvm-ir`. This will generate a `<APP_NAME>.ll`
	 file in the `target/debug/...` directory.

3. Replace the bitcode in `../bitcodes/` directory with this `<APP_NAME>.ll`
	 file. 

4. Run `analyze.sh` again.

[TODO: Support multiple bitcode files]

## Option 2: Build the toolchain on local machine
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
