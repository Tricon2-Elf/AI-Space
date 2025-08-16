import sys
import os
from pprint import pprint
from convertMapToCSV import processVRAMapFile
import csv

def find_files_by_ext(basedirectory, ext):
    result = []
    seen = set()
    for directory, _, files in os.walk(basedirectory):
        for filename in [f for f in files if f.lower().endswith(ext) and f not in seen]:
            seen.add(filename)
            result.append((filename, os.path.join(directory, filename)))
    return result

def get_path_by_filename(filename, file_list):
    file_dict = dict(file_list)
    return file_dict.get(filename, "")

def ProcessMap(sectionname, row):
    if(sectionname in row and row[sectionname] != ""):
        VRAFileName = row[sectionname]
        print(f"Processing Map: {VRAFileName}")
        VRAFileLoc = get_path_by_filename(VRAFileName, vrafiles)
        if(VRAFileLoc != ""):
            print(f"Filename: {VRAFileName} | MapFileLoc: {VRAFileLoc}")
            vracsv = processVRAMapFile(VRAFileLoc)
            return vracsv
    return ""

def ProcessRow(row, vrafiles):
    print(f"Processing Map: {row['World Name']}:{row['Map Name']}")

    WorldName = row['World Name']
    MapName = row['Map Name']
    #Process Map VRA
    mapcsv = ProcessMap('Map VRA', row)
    finaloutput = ""
    if(mapcsv != ""):
        mapcsv = "\n".join("Map, " + line for line in mapcsv.split("\n"))
        finaloutput += f"{mapcsv}\n"
    #Process Object VRA
    objectcsv = ProcessMap('Object VRA', row)
    if(objectcsv != ""):
        objectcsv = "\n".join("Object, " + line for line in objectcsv.split("\n"))
        finaloutput += f"{objectcsv}\n"
    #Process Effects VRA
    effectscsv = ProcessMap('Effects VRA', row)
    if(effectscsv != ""):
        effectscsv = "\n".join("Effects, " + line for line in effectscsv.split("\n"))
        finaloutput += f"{effectscsv}\n"
    #Process Distant VRA
    distantcsv = ProcessMap('Distant VRA', row)
    if(distantcsv != ""):
        distantcsv = "\n".join("Distant, " + line for line in distantcsv.split("\n"))
        finaloutput += f"{distantcsv}\n"
    #Process Sky VRAs
    #if('Sky 1 VRA' in map and map['Sky 1 VRA'] != ""):
    #    Sky1VRAFileName = map['Sky 1 VRA']
    #    Sky1VRAFileLoc = get_path_by_filename(Sky1VRAFileName, vrafiles)
    #    Sky1CSV = processVRAMapFile(Sky1VRAFileLoc)

    #if('Sky 2 VRA' in map and map['Sky 2 VRA'] != ""):
    #    Sky2VRAFileName = map['Sky 2 VRA']
    #    Sky2VRAFileLoc = get_path_by_filename(Sky2VRAFileName, vrafiles)
    #    Sky2CSV = processVRAMapFile(Sky2VRAFileLoc)
    directory_path = os.path.join(f"Maps/{WorldName}")
    file_path = os.path.join(directory_path, f"{MapName}.csv")
    os.makedirs(directory_path, exist_ok=True)
    if os.path.exists(file_path):
        os.remove(file_path)
    with open(file_path, 'w') as file:
        file.write(finaloutput)
    return



if __name__ == "__main__":
    if len(sys.argv) == 0:
        print("Usage: convertAllMaps.py <basedirectory> <maplist>")
        sys.exit(1)

    basedirectory = sys.argv[1]
    maplist = sys.argv[2]
    vrafiles = find_files_by_ext(basedirectory, '.vra')
    with open('listofmaps.csv', mode='r') as file:
        reader = csv.DictReader(file)
        for row in reader:
            ProcessRow(row, vrafiles)