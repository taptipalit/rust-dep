import csv
import json
import subprocess

def demangle_function_name(name):
    try:
        demangled_name = subprocess.check_output(['rustfilt', name.strip()]).decode('utf-8')
        """
        print(demangled_name)
        if name.strip() != demangled_name.strip():
            print("Demangled " + name + " to " + demangled_name)
        """
        return demangled_name
    except subprocess.CalledProcessError:
        print("Error")
        return name

def parse_csv_to_json(input_file, output_file):
    data = []
    records_parsed = 0  # Initialize a counter for the number of records parsed
    with open(input_file, 'r', newline='') as csvfile:
        reader = csv.reader(csvfile)
        for row in reader:
            parent_function = demangle_function_name(row[0])
            parent_arg_count = int(row[1])
            child_function = demangle_function_name(row[2])
            if "dbg" in child_function:
                continue
            child_arg_count = int(row[3])
            data.append({
                'parentFunction': parent_function,
                'parentArgCount': parent_arg_count,
                'childFunction': child_function,
                'childArgCount': child_arg_count
                })
            records_parsed += 1  # Increment the counter for each record parsed
            if records_parsed % 1000 == 0:
                print(f"{records_parsed} records parsed")

    with open(output_file, 'w') as jsonfile:
        json.dump(data, jsonfile, indent=4)

# Example usage
parse_csv_to_json('callgraph.json', 'output.json')
# print(demangle_function_name("_ZN4core4iter6traits8iterator8Iterator3nth17hee7f48fb893e6816E"))

