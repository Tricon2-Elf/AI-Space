
# Import necessary libraries
import os
from struct import unpack

def read_null_terminated_strings(data, encoding='Shift_JIS'):
    """Function to read null-terminated strings from binary file."""
    return [str_.decode(encoding) for str_ in data.split(b'\x00') if str_]

def read_group_header(file):
    """Function to unpack the binary data in the file."""
    flag_b1 = unpack('<I', file.read(4))[0]
    offset_f1 = unpack('<I', file.read(4))[0]
    flag_b2 = unpack('<I', file.read(4))[0]
    flag_b3 = unpack('<I', file.read(4))[0]
    offset_g = unpack('<I', file.read(4))[0]
    vertices_nr = unpack('<H', file.read(2))[0]
    normals_nr = unpack('<H', file.read(2))[0]
    uv_nr = unpack('<I', file.read(4))[0]
    data_v_nr = unpack('<I', file.read(4))[0]
    weight_map_nr = unpack('<I', file.read(4))[0]

    mesh_count = flag_b3 & 255

    return {
        'flag_b1': flag_b1,
        'offset_f1': offset_f1,
        'flag_b2': flag_b2,
        'flag_b3': flag_b3,
        'offset_g': offset_g,
        'vertices_nr': vertices_nr,
        'normals_nr': normals_nr,
        'uv_nr': uv_nr,
        'data_v_nr': data_v_nr,
        'weight_map_nr': weight_map_nr,
        'mesh_count': mesh_count
    }

def read_group(file, name):

    start_of_group_location = file.tell()
    group_header = read_group_header(file)
    # meshes
    meshes = [read_mesh(file) for _ in range(group_header['mesh_count'])]

    # vertex coordinates
    vertices = [unpack('<f', file.read(4))[0] for _ in range(group_header['vertices_nr'] * 3)]

    # normal vector
    normals = [unpack('<f', file.read(4))[0] for _ in range(group_header['normals_nr'] * 3)]

    # UV coordinates
    uv_count = group_header['uv_nr']
    uvs = []
    for i in range(uv_count * 2):
        u_value = unpack('<f', file.read(4))[0]
        uvs.append(u_value if i % 2 == 0 else u_value)

    for mesh in meshes:
        #Generate Vertices
        act_vertices = []
        for i in range(mesh['mesh_header']['vertex_info_nr']):
            offset = mesh['vertex_lut'][i] * 3
            x = vertices[offset]
            y = vertices[offset + 1]
            z = vertices[offset + 2]
            act_vertices.append((x, y, z))
        mesh['vertices'] = act_vertices

        #Generate Faces
        act_normals = []
        for i in range(mesh['mesh_header']['vertex_info_nr']):
            offset = mesh['normal_lut'][i] * 3
            x = normals[offset]
            y = normals[offset + 1]
            z = normals[offset + 2]
            act_normals.append((x, y, z))
        mesh['normals'] = act_normals

        #Generate UV
        act_uvs = []
        if(mesh['uv_lut'] != 65535):
            if(uv_count != 0):
                for i in range(mesh['mesh_header']['vertex_info_nr']):
                    offset = mesh['uv_lut'][i] * 2
                    x = uvs[offset + 0]
                    y = uvs[offset + 1]
                    act_uvs.append((x, y))
                mesh['uvs'] = act_uvs
    # dataV
    data_v_count = group_header['data_v_nr']
    data_v = bytearray()
    if data_v_count > 0:
        data_v = bytearray(file.read(data_v_count * 4))

    # weight map
    weight_map = [unpack('<f', file.read(4))[0] for _ in range(group_header['weight_map_nr'])]

    # remaining data. Unsure what it is
    
    remaining = start_of_group_location + group_header['offset_f1'] + 8
    file.seek(remaining, os.SEEK_SET)
    return {
        'header': group_header,
        'meshes': meshes,
        'vertices_length': len(vertices)/3,
        'normals_length': len(normals)/3,
        'name': name
    }

def read_mesh_header(file):
    """Function to read the mesh header from a binary file."""
    vertex_info_nr, face_info_nr = unpack('<HH', file.read(4))
    name_t_nr, data_u_nr, vertices_offset = unpack('<III', file.read(12))
    return {
        'vertex_info_nr': vertex_info_nr,
        'face_info_nr': face_info_nr,
        'name_t_nr': name_t_nr,
        'data_u_nr': data_u_nr,
        'vertices_offset': vertices_offset
    }

def read_mesh(file):
    mesh_header = read_mesh_header(file)

    #read vertex information
    vertex_lut = []
    normal_lut = []
    uv_lut = []
    for _ in range(mesh_header['vertex_info_nr']):
        vertex_lut.append(unpack('<H', file.read(2))[0])
        normal_lut.append(unpack('<H', file.read(2))[0])
        uv_lut.append(unpack('<H', file.read(2))[0])
        file.read(4)# discard next 4 bytes
    #read surface information
    face_info = []
    for _ in range(mesh_header['face_info_nr']):
        face = (unpack('<H', file.read(2))[0], unpack('<H', file.read(2))[0], unpack('<H', file.read(2))[0])
        face_info.append(face)

    #name T
    nameT = ""
    if mesh_header['name_t_nr'] != 0:
        n = unpack('<I', file.read(4))[0]
        nameT = read_null_terminated_strings(file.read(n))
    n = ((mesh_header['data_u_nr'] + 3) // 4) * 4
    file.seek(n, 1)

    return {
        'mesh_header': mesh_header,
        'nameT': nameT,
        'vertex_lut': vertex_lut,
        'normal_lut': normal_lut,
        'uv_lut': uv_lut,
        'faces': face_info
    }

def read_dxg_header(file):
    """Function to read the file header."""
    
    header_data = unpack('<HHHHIII', file.read(20))
    flag_a1, flag_a2, flag_a3, flag_a4, num_of_groups, next_data_offset, group_name_length = header_data

    bit_flags = [bool(flag_a3 & (1 << i)) for i in range(6)]
    mesh_exists, aux_a_exists, aux_b_exist, aux_c_exist, _, aux_d_exists = bit_flags

    #Read the names of the groups in the file. These are null terminated strings
    group_names = read_null_terminated_strings(file.read(group_name_length))
    file_size = next_data_offset+20
    current_pos = file.tell()
    auxheader = []
    if(aux_a_exists):
        file.seek(next_data_offset)
        file.read(8) #Discard 8 bytes
        file.read(8) #Discard 8 bytes
        auxheader = unpack('<HHHHIII', file.read(20))
        nr_aux_elems = auxheader[2]
        aux_list_size = auxheader[4]
        #nr_aux_elems, aux_list_size = unpack('<II', file.read(8))
        file_size = next_data_offset + aux_list_size+28
    file.seek(current_pos)
    return {
        #'flag_a1': flag_a1,
        #'flag_a2': flag_a2,
        #'flag_a3': flag_a3,
        #'flag_a4': flag_a4,
        'nr_groups': num_of_groups,
        'next_data_offset': next_data_offset,
        'group_name_size': group_name_length,
        'mesh_data_present': mesh_exists,
        'aux_data_a0_or_a1_present': aux_a_exists,
        'aux_data_b_present': aux_b_exist,
        'aux_data_c_present': aux_c_exist,
        'aux_data_d_present': aux_d_exists,
        'group_names': group_names,
        'file_size': file_size,
        'auxhead': auxheader
    }

def read_dxg_file(filename, headerOnly):
    """Function to read a binary file."""
    # Check the file extension
    if not filename.lower().endswith('.dxg'):
        raise ValueError(f'Invalid file extension for file {filename}. Expected .dxg')


    with open(filename, 'rb') as file:
        # Read and decode the file identifier
        identifier = file.read(4).decode('ascii')

        # If the identifier is not 'DXG ', raise an error
        if identifier != 'DXG ':
            raise ValueError(f'Invalid file identifier {identifier}. Expected DXG')
        # Read the file header
        dxg_header = read_dxg_header(file)
        if(headerOnly):
            return dxg_header
        filedata = {}
        filedata['dxg_header'] = dxg_header
        if dxg_header["mesh_data_present"]:
            #Need to implement something to check if there are any groups or how many groups and loop through read_group
            dxg_groups = [read_group(file, dxg_header['group_names'][i]) for i in range(dxg_header['nr_groups'])]
            filedata['dxg_groups'] = dxg_groups
    return filedata  # Return the header data
