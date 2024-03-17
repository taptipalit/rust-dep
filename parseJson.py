import csv
import json
import subprocess
import os
import re

function_map = {}

def parse_ll_file(ll_filename):
    with open(ll_filename, 'r') as f:
        comment = None
        for line in f:
            line = line.strip()
            if line.startswith('; <'):
                comment = line[1:].strip()
            elif comment and line.startswith('define'):
                regex_pattern = r'@"([^"]+)"'
                match = re.search(regex_pattern, line)
                if match:
                    function_name = match.group(1)
                    function_map[function_name] = comment
                    # print(function_name + " -> " + comment)
                else:
                    print("No match for : " + comment)
                comment = None

def demangle_function_name(name):
    if name in function_map:
        return function_map[name]
    else:
        # print("Not found " + name)
        new_name = name.replace("..", "::").replace("$LT$", "<").replace("$GT$",
                 ">").replace("$u20$", " ")
        if name == new_name:
            new_name = subprocess.check_output(['rustfilt',
                new_name.strip()]).decode('utf-8')
        return new_name

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

def find_first_ll_file(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".ll"):
                return os.path.join(root, file)
    return None  # No .ll file found in the directory

# Example usage
ll_file = find_first_ll_file("bitcodes")
parse_ll_file(ll_file)
parse_csv_to_json('callgraph.csv', 'callgraph.json')
# print(demangle_function_name("_ZN4core4iter6traits8iterator8Iterator3nth17hee7f48fb893e6816E"))

