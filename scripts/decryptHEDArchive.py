from io import BytesIO
import sys
import struct
import os

KNOWN_DECRYPTION_KEYS = {
    "16F6": "0BF616B76D6121407576152788F159AB88E7F1DA0F8B506AB1BD24B073C604FC4309B3CDEBC7B166968AC013C8A056D065554F0AB2699C973106128A0FBF0F40",
    "84D4": "5FD484E0C15C0C3DED9BF6087936013D3440783ACEB100A8E20879B8758B10180EA0D9D54D8F6058D1AE9A34EFD6A0E3E615047CA5AECE60D44EFF1D3C563CFA",
    "9495": "779594CCB11842190CC2733ACA0B036853A589D31B2501414EFB833DFCBF653CE63BCEAC30381EA25767DC0262C65E0FBD5A942DF4DD08958749388C86CDA06A",
    "A725": "B9B6DF150AE4CC0155C154C34DFD8DFFE52364FA61364DB8FB6F514DA5D98A1D9318F70203B7085943B21E1238EE34A3A8582BE6B5AF4CF20CAC93DB86082FAFBFB121CFC1A7BFE09869A35B57C3FE56E346E04B5CB46A890ABB6D71A001DF1402EBEC51EF7905A8F7B249C9AF578B0E6F4E49895D202EC02B5BAB8CC0CF314D6D73935B3A57CD518026B26A294C81AC3A5AFE77D3AC2A20F7600AFF4EE6ECF61A779E992BFE15B6EA81A274FAF911C41565B5A002FFD895295036EF4873F1C38CD4E245625CFCF2B44AF6DE9408B6BFE2855439361ACD78C5EA21FB5E5271C3BF08201A6736CF5AF052BD128AB8A8860B2BC0126E5AB7CF23EE41C0249D57C1E4",
    "1D7A": "767A1DEF2FCF62C05CCC641CE80F6D5B5238D7EA0F6F0520AA7F0AED0432052387899C001CC7507BA4C5268AA963772859DECD82199198578560D89EA7B63B47",
    "4EF3": "A1F34E06C6C06133568D724A00768CEAA10E802730047C04CE908CE29FEE76A921A4A3F235A5C1770B2899288205ABBC1DAB3DFF644AC344894E45B6CC16C2DD",
}

base_folder_path = "D:\\Projects\\aiSpace\\finalbuild\\ai sp@ce\\data\\"


#Cache to keep files loaded in RAM so we don't have to keep reading them
dat_file_cache = {}

def read_from_dat_file(file_path, offset, length):
    if file_path not in dat_file_cache:
        with open(file_path, "rb") as f:
            dat_file_cache[file_path] = f.read()
    return dat_file_cache[file_path][offset:offset + length]

def read_all_dat_file(file_path):
    if file_path not in dat_file_cache:
        with open(file_path, "rb") as f:
            dat_file_cache[file_path] = f.read()
    return dat_file_cache[file_path]

def decrypt_data(key, data):
    output = bytearray(len(data))
    for i in range(len(data)):
        output[i] = (data[i] - key[i % len(key)]) % 256
    return bytes(output)

def extract_archive(hed_path, output_path):
    #folder_path = os.path.dirname(hed_path)
    with open(hed_path, "rb") as stream:
        sign = stream.read(4).decode("ascii")
        if sign != 'FPMF':
            print("Isn't a AI Sp@ce archive")
            sys.exit()
        
        stream.read(4) # Unused 4 bytes
        DataSize = struct.unpack("<I", stream.read(4))[0]

        stream.read(4) # Unused 4 bytes
        stream.read(1) # Unused 1 byte

        key = stream.read(2)[::-1].hex().upper()

        stream.seek(16, 0)
        body_raw = stream.read()
        if key not in KNOWN_DECRYPTION_KEYS:
            raise Exception(f"Unknown Encryption Key: {key} | Unknowns: 38958, 20211")
        
        decryption_key = bytes.fromhex(KNOWN_DECRYPTION_KEYS[key])
        body_data = BytesIO(decrypt_data(decryption_key, body_raw))
        body_data.read(8) #Unused
        #Get base name 
        base_name_length = body_data.read(1)[0] * 2
        base_name = body_data.read(base_name_length).decode("utf-16le")
        body_data.read(16) #Unused
        print(base_name)
        dat_key_size = struct.unpack("<I", body_data.read(4))[0]
        dat_key = body_data.read(dat_key_size)

        body_data.read(8) #Unused
        file_count = struct.unpack("<I", body_data.read(4))[0]

        for i in range(0, file_count):
            folder_name_length = body_data.read(1)[0] * 2
            temp_folder = body_data.read(folder_name_length).decode("utf-16le")
            # Read File name length, then read and decode the File name
            file_name_length = body_data.read(1)[0] * 2
            temp_filename = body_data.read(file_name_length).decode("utf-16le")
            temp_pack_num = format(struct.unpack("<I", body_data.read(4))[0], "04x")
            pack_file = base_name.replace("%04x", temp_pack_num)
            pack_path = os.path.join(base_folder_path, pack_file.lstrip("./").replace("/", "\\"))
            file_offset, file_size, checksum, zero = struct.unpack("<IIII", body_data.read(16))
            byte_array = read_from_dat_file(pack_path, file_offset, file_size)
            #Only decrypt if there is a key
            if dat_key_size != 0:
                byte_array = decrypt_data(dat_key, byte_array)
            file_output_path = os.path.join(output_path, temp_folder.lstrip(".\\"), temp_filename.lstrip(".\\"))
            os.makedirs(os.path.dirname(file_output_path), exist_ok=True)
            with open(file_output_path, "wb") as file:
                file.write(byte_array)
            print(f"Wrote: {file_output_path}")



#extract_archive("D:\\Projects\\aiSpace\\finalbuild\\ai sp@ce\\data\\world\\field.hed", "D:\\aitest\\")