//=============================================================================
// FILE:
//    HelloWorld.cpp
//
// DESCRIPTION:
//    Visits all functions in a module, prints their names and the number of
//    arguments via stderr. Strictly speaking, this is an analysis pass (i.e.
//    the functions are not modified). However, in order to keep things simple
//    there's no 'print' method here (every analysis pass should implement it).
//
// USAGE:
//    New PM
//      opt -load-pass-plugin=libHelloWorld.dylib -passes="hello-world" `\`
//        -disable-output <input-llvm-file>
//
//
// License: MIT
//=============================================================================
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/JSON.h"
#include <unicode/ustream.h>
#include <unicode/unistr.h>


using namespace llvm;

using namespace llvm::json;
//-----------------------------------------------------------------------------
// HelloWorld implementation
//-----------------------------------------------------------------------------
// No need to expose the internals of the pass to the outside world - keep
// everything in an anonymous namespace.
namespace {

json::Object createJsonCallInst(Function &F, CallInst &CI) {
	json::Object J;

	icu::UnicodeString parentName = icu::UnicodeString::fromUTF8(F.getName().str().c_str());
	parentName.findAndReplace("$LT$", u"<");
	parentName.findAndReplace("$GT$", u">");
	parentName.findAndReplace("$u20$", u" ");

	std::string parentNameUTF;
	parentName.toUTF8String(parentNameUTF);

	J.try_emplace("parent_function", parentNameUTF);
	J.try_emplace("parent_function_arg_count", F.arg_size());
	Function *Callee = CI.getCalledFunction();
	if (Callee) {
		icu::UnicodeString functionName = icu::UnicodeString::fromUTF8(Callee->getName().str().c_str());
		functionName.findAndReplace("$LT$", u"<");
		functionName.findAndReplace("$GT$", u">");
		functionName.findAndReplace("$u20$", u" ");

		std::string functionNameUTF;
		functionName.toUTF8String(functionNameUTF);
		J.try_emplace("called_function", functionNameUTF);
		J.try_emplace("called_function_arg_count", Callee->arg_size());
	}/* else {
		J.try_emplace("called_function", "indirect");
		J.try_emplace("called_function_arg_count", -1);
	}
	*/
	return J;
}

// This method implements what the pass does
void visitor(Function &F) {
	// Create a JSON array to store all CallInsts
	json::Array CallInstArray;

	// Iterate over all instructions in the function
	for (auto &BB : F) {
		for (auto &I : BB) {
			// Check if the instruction is a CallInst
			if (auto *CI = dyn_cast<CallInst>(&I)) {

				// Print the target of the CallInst
				if (Function *Callee = CI->getCalledFunction()) {
				errs() << "CallInst target: " << Callee->getName() << "\n";
				}
				/*
				// Create JSON object for CallInst
				json::Object CallInstJson = createJsonCallInst(F, *CI);
				// Add JSON object to the array
				CallInstArray.push_back(std::move(CallInstJson));
				*/
			}
		}
	}
	// Print the JSON array
	//llvm::outs() << json::Value(std::move(CallInstArray)) << "\n";
}

// New PM implementation
struct HelloWorld : PassInfoMixin<HelloWorld> {
  // Main entry point, takes IR unit to run the pass on (&F) and the
  // corresponding pass manager (to be queried if need be)
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
		llvm::outs() << "{";
    visitor(F);
		llvm::outs() << "}";
    return PreservedAnalyses::all();
  }

  // Without isRequired returning true, this pass will be skipped for functions
  // decorated with the optnone LLVM attribute. Note that clang -O0 decorates
  // all functions with optnone.
  static bool isRequired() { return true; }
};
} // namespace

//-----------------------------------------------------------------------------
// New PM Registration
//-----------------------------------------------------------------------------
llvm::PassPluginLibraryInfo getHelloWorldPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "HelloWorld", LLVM_VERSION_STRING,
          [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef Name, FunctionPassManager &FPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name == "hello-world") {
                    FPM.addPass(HelloWorld());
                    return true;
                  }
                  return false;
                });
          }};
}

// This is the core interface for pass plugins. It guarantees that 'opt' will
// be able to recognize HelloWorld when added to the pass pipeline on the
// command line, i.e. via '-passes=hello-world'
extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return getHelloWorldPluginInfo();
}
