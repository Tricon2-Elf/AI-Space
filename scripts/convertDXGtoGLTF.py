# Import necessary libraries
import sys
from readDXGFile import read_dxg_file
from createGLTF import create_gltf


if __name__ == "__main__":
    # If a filename is not passed as an argument, print usage and exit
    if len(sys.argv) != 2:
        print('Usage: python ConvertFromDXG.py <filename>')
        sys.exit(1)

    # Read the binary file
    file_data = read_dxg_file(sys.argv[1])
    all_meshes = []

    for group in file_data['dxg_groups']:
        for mesh in group['meshes']:
            mesh['name'] = group['name']
            all_meshes.append(mesh)

    gltf_content = create_gltf(all_meshes)
    with open('dxgoutput.gltf', 'w') as f:
        f.write(gltf_content)
