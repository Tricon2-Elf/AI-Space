import json
import re
import sys
from pprint import pprint
import os

varnames = []
def parse_value(value,debug=0):
    rawvalue = value
    try:
        pattern = r'(.*?)\[(.*?)\](.*)'
        match = re.match(pattern, value)
        if match:
            vartype, varnum, val = match.groups()
            varnum = int(varnum)
            val = val.strip().strip(',')
            # Split the values using ',' as the separator
            vals = val.split(',')
            if(debug):
                print(f'-----------------------------------')
                print(f'vartype: "{vartype}"')
                print(f'varnum: "{varnum}"')
                print(f'val: "{val}"')
            if vartype.startswith('int'):
                #Fix since a single broken file
                if ')' in vals[-1]:
                    vals[-1] = vals[-1].split(')')[0]
                vals = list(map(int, vals))
            elif vartype == "float":
                vals = list(map(float, vals))
            elif vartype.startswith('vector'):
                # Based on the vector type, split the list into appropriate chunks
                chunk_size = int(vartype[-1])
                vals = [list(map(float, vals[i:i+chunk_size])) for i in range(0, len(vals), chunk_size)]
            elif vartype == "quat":
                # Split the list into chunks of 4 for quats
                vals = [list(map(float, vals[i:i+4])) for i in range(0, len(vals), 4)]
            elif vartype == "string":
                vals = [v.strip().strip('\"') for v in vals]
            else:
                raise Exception(f"Unknown Vartype {vartype}")
            
            # If there's only one element, return it directly, otherwise return the list
            return vals[0] if len(vals) == 1 else vals
        else:
            raise Exception(f"Line is incorrect")
    except Exception as e:
        print(f'Thrown exception: {str(e)} value: "{value}" RAW: "{rawvalue}"')

def parse_lines(lines):
    data = {}
    multi_line_value = None
    for line in lines:
        line = line.strip()
        
        # Check if we're currently parsing a multi-line value
        if multi_line_value is not None:
            multi_line_value += " " + line  # Append the line to the ongoing multi-line value
            if ')' in line:
                # If this line ends the multi-line value, process it
                name, value = multi_line_value.strip('()').split(' ', 1)
                if name not in varnames:
                    varnames.append(name)
                data[name] = parse_value(value)  # Assuming `parse_value` is defined elsewhere
                multi_line_value = None  # Reset the multi-line value
            continue

        if line.startswith('{'):
            name = line.strip('{}')
            nested_obj = parse_lines(lines)
            if name in data:
                if isinstance(data[name], list):
                    data[name].append(nested_obj)
                else:
                    data[name] = [data[name], nested_obj]
            else:
                data[name] = nested_obj
        elif line.startswith('}'):
            return data
        elif line.startswith('('):
            if ')' in line:
                name, value = line.strip('()').split(' ', 1)
                if name not in varnames:
                    varnames.append(name)
                data[name] = parse_value(value)  # Assuming `parse_value` is defined elsewhere
            else:
                # This line starts a multi-line value, so store it and continue processing lines
                multi_line_value = line
    if('geometry' in data and isinstance(data['geometry']['mesh'], dict)):
        data['geometry']['mesh'] = [data['geometry']['mesh']]
    if('Models' in data and isinstance(data['Models']['object'], dict)):
        data['Models']['object'] = [data['Models']['object']]
    if('fx_objects' in data and isinstance(data['fx_objects']['fx'], dict)):
        data['fx_objects']['fx'] = [data['fx_objects']['fx']]
    if('material_set' in data and isinstance(data['material_set']['material'], dict)):
        data['material_set']['material'] = [data['material_set']['material']]
    return data


def parse_file(file_name):
    with open(file_name, 'r', encoding='shift_jis') as f:
        lines = iter(f.readlines())
    vra = parse_lines(lines)

    return vra

if __name__ == "__main__":
    # If a filename is not passed as an argument, print usage and exit
    if len(sys.argv) != 2:
        print('Usage: python loadVRAfile.py <filename>')
        sys.exit(1)
    path = sys.argv[1]
    if os.path.isfile(path):
        data = parse_file(path)

