# Import necessary libraries
from pprint import pprint
import sys
import os
from readDXGFile import read_dxg_file
from createGLTF import create_gltf
from readVRAFile import parse_file
from wand.image import Image
import base64
from io import BytesIO
import traceback

failedvras = []


def convert_dds_to_base64_png(dds_path):
    with Image(filename=dds_path) as img:
        # Save the image to a byte stream
        byte_stream = BytesIO()
        img.format = 'png'  # Ensure the image format is PNG before saving to the byte stream
        img.save(file=byte_stream)
        raw_bytes = byte_stream.getvalue()
        base64_encoded = base64.b64encode(raw_bytes).decode('utf-8')
        
        return base64_encoded

def find_texture_index(images, texturename):
    for idx, image in enumerate(images):
        if image["name"] == texturename:
            return idx
    return None

def convert_dds_to_pngfile(dds_path, png_path):
    with Image(filename=dds_path) as img:
        img.save(filename=png_path)

def findModelDirs(basedirectory):
    # List to hold directories with 'attr', 'model', and 'tex' subfolders
    modelDirs = []
    
    # Walking through the root directory
    for dirpath, dirnames, filenames in os.walk(basedirectory):
        # Check if all three special folders are in the current directory
        if 'attr' in dirnames:
            modelDirs.append(dirpath)
    return modelDirs

def find_files_by_ext(basedirectory, ext):
    result = []
    seen = set()
    for directory, _, files in os.walk(basedirectory):
        for filename in [f for f in files if f.lower().endswith(ext) and f not in seen]:
            seen.add(filename)
            result.append((filename, os.path.join(directory, filename)))
    return result

def get_path_by_filename(filename, file_list):
    for base_name, uri in file_list:
        if base_name == filename:
            return uri
    return ""

def processObjectDirectory(basedirectory, newdirectory, texturefilelocations, modelfilelocations):
    required_folders = {'attr'}
    if(newdirectory == ""):
        newdirectory = basedirectory
    existing_folders = {folder for folder in os.listdir(basedirectory) if os.path.isdir(os.path.join(basedirectory, folder))}
    if required_folders.issubset(existing_folders):
        #Read the VRA file in /attr/
        for dirpath, dirnames, filenames in os.walk(f'{basedirectory}\\attr'):
            for filename in filenames:
                if filename.endswith('.vra'):
                    try:
                        vrapath = os.path.join(f'{basedirectory}\\attr', filename)
                        vrabasefilename, _ = os.path.splitext(filename)
                        print(f"Processing: {vrapath}")
                        vrafile = parse_file(vrapath)
                        if('Models' in vrafile):
                            print("This is a map file. Skipping")
                            continue
                        
                        finalfileuri = f"{newdirectory}\\{vrabasefilename}.gltf"
                        if os.path.exists(finalfileuri):
                            print(f"{vrabasefilename}.gltf Already exported")
                            continue
                        meshfilename = os.path.basename(vrafile['attribute']['Geometry'])
                        meshfile = get_path_by_filename(meshfilename, modelfilelocations)
                        if(not meshfile):
                            raise Exception(f"Mesh doesn't exist '{meshfilename}'")
                        #Read the dxg
                        file_data = read_dxg_file(meshfile)

                        #Load and loop the materials
                        materials = []
                        for mat in vrafile['material_set']['material']:
                            if 'texture' in mat:
                                texname = os.path.basename(mat['texture']['diffuse']['fname'])
                                texpath = f"{basedirectory}\\tex\\{texname}"
                                #Check if the file actually exists. if not grab the path from the backup
                                if not os.path.exists(texpath):
                                    texpath = get_path_by_filename(texname, texturefilelocations)
                                    if(not texpath):
                                        raise Exception(f"Cant find texture {texname}")
                                mat['texturefile'] = os.path.basename(texname)
                                mat['texture_data_base64'] = convert_dds_to_base64_png(texpath)
                            materials.append(mat)
                        all_meshes = []
                        for idx,mesh in enumerate(vrafile['geometry']['mesh']):
                            group = file_data['dxg_groups'][idx]
                            currentMatID = mesh['lod0']['material_id']
                            for gmesh in group['meshes']:
                                gmesh['name'] = group['name']
                                if 'texturefile' in materials[currentMatID]:
                                    gmesh['texturename'] = materials[currentMatID]['texturefile']
                                    gmesh['texturedata'] = materials[currentMatID]['texture_data_base64']
                                    gmesh['doubleSided'] = materials[currentMatID]['param_block']['twoSided']
                                all_meshes.append(gmesh)
                        gltf_content = create_gltf(all_meshes, 1)
                        with open(finalfileuri, 'w') as f:
                            f.write(gltf_content)
                    except Exception as e:
                        failedvras.append(f"{filename}: Exception: {e} {traceback.format_exc()}")

if __name__ == "__main__":
    # If a filename is not passed as an argument, print usage and exit
    if len(sys.argv) <= 1:
        print('Usage: python convertModelToGLTF.py <filename>')
        sys.exit(1)

    basedirectory = sys.argv[1]
    newdirectory = ""
    if(len(sys.argv) > 2):
        newdirectory = sys.argv[2]
    if not os.path.exists(basedirectory):
        print(f"Error: Directory '{basedirectory}' does not exist.")
        sys.exit(1)
    texturefilelocations = find_files_by_ext(basedirectory, '.dds')
    modelfilelocations = find_files_by_ext(basedirectory, '.dxg')
    ModelDirectories = findModelDirs(basedirectory)
    for dir in ModelDirectories:
        processObjectDirectory(dir, newdirectory, texturefilelocations, modelfilelocations)
    pprint(f"Failed on {len(failedvras)}")
    for failedvra in failedvras:
        print(failedvra)