import sys
import os
from readVRAFile import parse_file
import math

def quaternion_to_euler(w, x, y, z):
    # Roll (X-axis rotation)
    t0 = 2 * (w * x + y * z)
    t1 = 1 - 2 * (x**2 + y**2)
    roll_x = math.degrees(math.atan2(t0, t1))

    # Pitch (Y-axis rotation)
    t2 = max(-1, min(1, 2 * (w * y - z * x)))
    pitch_y = math.degrees(math.asin(t2))

    # Yaw (Z-axis rotation)
    t3 = 2 * (w * z + x * y)
    t4 = 1 - 2 * (y**2 + z**2)
    yaw_z = math.degrees(math.atan2(t3, t4))

    return roll_x, pitch_y, yaw_z

def dir_to_quaternion(dir_value):
    # Convert dir value to angle in radians
    theta = dir_value * math.pi / 2  # pi/2 is 90 degrees in radians

    # Calculate the components of the quaternion
    w = math.cos(theta / 2)
    x = 0
    y = math.sin(theta / 2)
    z = 0

    return (x, y, z, w)

def processVRAMapFile(vrapath):
    vrafile = parse_file(vrapath)
    print(f"Processing {vrapath}")
    #File contains models. Process it like a Object file(Obj, Sky, Fx)
    if('Models' in vrafile):
        print("File is a Models file")
        return processVRAMapObjectFile(vrapath)
    #File contains chipdata. Process like a Chip file(Map/Ground)
    elif('ChipData' in vrafile): 
        print("File is a Chips file")
        return processVRAMapChipFile(vrapath)
    elif('fx_objects' in vrafile):
        print("File is fx file")
        return processVRAMapEffectsFile(vrapath)
    else:
        raise Exception("Invalid map file")

def processVRAMapEffectsFile(vrapath):
    output = ""
    vraobject = parse_file(vrapath)
    
    for item in vraobject['fx_objects']['fx']:
        objectname = item['id']
        objectpos = ', '.join([str(f * 0.01) for f in item['pos']])
        #somewhat unsure of the quaternion layout. Believe its X,Z,Y Need to do some testing
        #                                  w              x               y               z
        #euler_angles = quaternion_to_euler(item['rot'][3], item['rot'][0], item['rot'][1], item['rot'][2])
        #objectrot = f"{euler_angles[0]}, {euler_angles[1]}, {euler_angles[2]}"
        objectrot = f"{item['rot'][0]}, {item['rot'][1]}, {item['rot'][2]}, {item['rot'][3]}"
        objectscale = f"{item['scale'][0] * -0.01}, {item['scale'][1] * 0.01}, {item['scale'][2] * 0.01}"
        output += f"{objectname}, {objectpos}, {objectrot}, {objectscale}\n"
    return output.strip()


def processVRAMapObjectFile(vrapath):
    output = ""
    vraobject = parse_file(vrapath)
    for item in vraobject['Models']['object']:
        objectname = item['name']
        objectpos = ', '.join([str(f * 0.01) for f in item['pos']])
        #somewhat unsure of the quaternion layout. Believe its X,Z,Y Need to do some testing
        #euler_angles = quaternion_to_euler(item['rot'][3], item['rot'][0], item['rot'][1], item['rot'][2])
        #objectrot = f"{euler_angles[0]}, {euler_angles[1]}, {euler_angles[2]}"
        objectrot = f"{item['rot'][0]}, {item['rot'][1]}, {item['rot'][2]}, {item['rot'][3]}"
        objectscale = f"{item['scale'][0] * -0.01}, {item['scale'][1] * 0.01}, {item['scale'][2] * 0.01}"
        output += f"{objectname}, {objectpos}, {objectrot}, {objectscale}\n"
    return output.strip()

def processVRAMapChipFile(vrapath):
    output = ""
    vraobject = parse_file(vrapath)
    chipsize = vraobject['Config']['ChipSize']/100
    gridnums = vraobject['Config']['GridNums']-1
    for line, data in vraobject['ChipData'].items():
        tempdata = data
        if not isinstance(tempdata['Cell'], list) or not all(isinstance(i, list) for i in tempdata['Cell']):
            tempdata['Cell'] = [tempdata['Cell']]
        if not isinstance(tempdata['Dir'], list):
            tempdata['Dir'] = [tempdata['Dir']]
        objectname = os.path.basename(tempdata['MdlName'])
        #TODO: Chip Rotation
        objectrot = '0, 0, 0, 0'#Rotation is based on 'Dir' not sure on how it works yet. Could just use the object scale?
        #objectscale = f"{tempdata['Size'][0]*-0.01}, 0.01, {tempdata['Size'][1]*0.01}"
        objectscale = f"-0.01, 0.01, 0.01"
        for i, pos in enumerate(tempdata['Cell']):
            rotation = dir_to_quaternion(tempdata['Dir'][i])
            objectrot = f"{rotation[0]}, {rotation[1]}, {rotation[2]}, {rotation[3]}"
            #objectpos = f"{-520 + (pos[0] * chipsize)}, 0, {520 + (pos[1] * -chipsize)}"
            objectpos = f"{((pos[0]-(gridnums/2)) * chipsize)}, 0, {((pos[1]-(gridnums/2)) * -chipsize)}"
            output += f"{objectname}, {objectpos}, {objectrot}, {objectscale}\n"
    return output.strip()

if __name__ == "__main__":
    # If a filename is not passed as an argument, print usage and exit
    if len(sys.argv) <= 1:
        print('Usage: python convertMapToCSV.py <filename>')
        sys.exit(1)
    VRAPath = sys.argv[1]
    output = processVRAMapFile(VRAPath)
    csvpath = VRAPath.replace('.vra', '.csv')
    if os.path.exists(csvpath):
        os.remove(csvpath)
    with open(csvpath, 'a') as file:
        file.write(output)
