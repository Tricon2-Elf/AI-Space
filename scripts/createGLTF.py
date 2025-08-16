# Import necessary libraries
import struct
import base64
import json

ARRAY_BUFFER = 34962
ELEMENT_ARRAY_BUFFER = 34963
def find_texture_index(images, texturename):
    for idx, image in enumerate(images):
        if image["name"] == texturename:
            return idx
    return None

def create_gltf(meshes, imbedtexture=0):
    buffers = []
    bufferViews = []
    accessors = []
    images = []
    textures = []
    samplers = [{}]
    materials = []
    meshes_gltf = []
    nodes = []

    accessor_offset = 0

    for mesh in meshes:
        #vertices, normals, uvs, faces = mesh
        vertices = mesh['vertices']
        normals = mesh['normals']
        uvs = []
        if('uvs' in mesh):
            uvs = mesh['uvs']
        faces = mesh['faces']

        #Flatten vertices
        vertex_data = []
        for vertex in vertices:
            vertex_data.extend(vertex)

        #Flatten normals
        normal_data = []
        for normal in normals:
            normal_data.extend(normal)

        #Flatten faces
        indices_data = []
        for face in faces:
            indices_data.extend(face)

        # Convert data to bytes
        vertex_bytes = b''.join(struct.pack('f', v) for vertex in vertices for v in vertex)
        normal_bytes = b''.join(struct.pack('f', n) for normal in normals for n in normal)
        indices_bytes = b''.join(struct.pack('H', i) for face in faces for i in face)
        #Capture the length of the indices array
        indices_actualsize = len(indices_bytes)
        #Need to pad the indices_bytes array due to Accessor alignment has to be correct. for UVs this is 4.
        padding_length = (4 - (len(indices_bytes) % 4)) % 4
        indices_bytes += b'\x00' * padding_length
        if('uvs' in mesh):
            uv_bytes = b''.join(struct.pack('f', uv) for uv_pair in uvs for uv in uv_pair)
            buffer_bytes = vertex_bytes + normal_bytes + indices_bytes + uv_bytes
        else:
            buffer_bytes = vertex_bytes + normal_bytes + indices_bytes
        buffer_data_base64 = base64.b64encode(buffer_bytes).decode('utf-8')

        # Add to buffers list
        buffers.append({
            "byteLength": len(buffer_bytes),
            "uri": "data:application/octet-stream;base64," + buffer_data_base64
        })

        material = {}
        #Adding Image and texture info
        if 'texturedata' in mesh:
            imageindex = 0
            index = find_texture_index(images, mesh['texturename'])
            if index is None:
                if(imbedtexture):
                    images.append({"name": mesh['texturename'],"uri": f"data:image/png;base64,{mesh['texturedata']}"})  # assuming PNG format
                else:
                    images.append({"uri": mesh['texturepath']})  # assuming PNG format
                imageindex = len(images) - 1
            else:
                imageindex = index
            textures.append({"source": imageindex, "sampler": 0})


            #mesh['doubleSided']
            material = {
                "pbrMetallicRoughness": {
                    "baseColorTexture": {
                        "index": len(textures) - 1,
                    }
                },
                "doubleSided": False,
                "alphaMode": "BLEND"
            }
        else:
            
            material = {
                "doubleSided": False
            }

        #if 'texturedata' in mesh:
        if('doubleSided' in mesh and mesh['doubleSided']):
            material["doubleSided"] = True
        materials.append(material)
        # Buffer Views
        bufferViews.extend([
            {#Vertices
                "name": "Vertices",
                "buffer": len(buffers) - 1,  # Point to the last buffer added
                "byteOffset": 0,
                "byteLength": len(vertex_bytes),
                "target": ARRAY_BUFFER 
            },
            {#Normals
                "name": "Normals",
                "buffer": len(buffers) - 1,
                "byteOffset": len(vertex_bytes),
                "byteLength": len(normal_bytes),
                "target": ARRAY_BUFFER
            },
            {#Faces
                "name": "Faces",
                "buffer": len(buffers) - 1,
                "byteOffset": ((len(vertex_bytes) + len(normal_bytes))),
                "byteLength": indices_actualsize,
                "target": ELEMENT_ARRAY_BUFFER
            }
        ])
        if 'texturedata' in mesh:
            bufferViews.extend([{#UVs
                "name": "UVs",
                    "buffer": len(buffers) - 1,
                    "byteOffset": len(vertex_bytes) + len(normal_bytes) + len(indices_bytes),
                    "byteLength": len(uvs) * 8,
                    "target": ARRAY_BUFFER
                }])

        # Accessors
        accessors.extend([
            {#Vertices
                "name": "Vertices",
                "bufferView": accessor_offset,
                "byteOffset": 0,
                "componentType": 5126,  # FLOAT
                "count": len(vertices),
                "type": "VEC3",
                "max": [max([v[i] for v in vertices]) for i in range(3)],
                "min": [min([v[i] for v in vertices]) for i in range(3)]
            },
            {#Normals
                "name": "Normals",
                "bufferView": accessor_offset + 1,
                "byteOffset": 0,
                "componentType": 5126,  # FLOAT
                "count": len(normals),
                "type": "VEC3"
            },
            {#Faces
                "name": "Faces",
                "bufferView": accessor_offset + 2,
                "byteOffset": 0,
                "componentType": 5123,  # UNSIGNED_SHORT
                "count": len(faces)*3,
                "type": "SCALAR",
                "max": [max([num for sublist in faces for num in sublist])],
                "min": [min([num for sublist in faces for num in sublist])]
            }
        ])
        if 'texturedata' in mesh:
            accessors.extend([
                {#UVs
                    "name": "UVs",
                    "bufferView": accessor_offset + 3,
                    "byteOffset": 0,
                    "componentType": 5126,  # FLOAT
                    "count": len(uvs),
                    "type": "VEC2"
                }])
        # Meshes
        attributes = {
            "POSITION": accessor_offset,
            "NORMAL": accessor_offset + 1,
        }

        if 'texturedata' in mesh:
            attributes["TEXCOORD_0"] = accessor_offset + 3

        meshes_gltf.append({
            "name": mesh['name'],
            "primitives": [{
                "indices": accessor_offset + 2,
                "attributes": attributes,
                "material": len(materials) - 1
            }]
        })

        nodes.append({"mesh": len(meshes_gltf) - 1})

        if 'texturedata' in mesh:
            accessor_offset += 4
        else:
            accessor_offset += 3

    gltf = {
        "asset": {
            "generator" : "DXG to GFTL",
            "version": "2.0"
        },
        "buffers": buffers,
        "bufferViews": bufferViews,
        "accessors": accessors,
        "materials": materials,
        "meshes": meshes_gltf,
        "nodes": nodes,
        "scenes": [{
            "nodes": list(range(len(meshes)))
        }],
        "scene": 0
    }

    #These should only be included if there are any textures at all
    if(textures):
        gltf["images"] = images
        gltf["textures"] = textures
        gltf["samplers"] = samplers

    return json.dumps(gltf, indent=2)
