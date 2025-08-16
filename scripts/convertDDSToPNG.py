import sys
import os
import time
from wand.image import Image


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Please provide a path as an argument.")
        sys.exit(1)

    path = sys.argv[1]
    if os.path.isdir(path):
        print(f"{path} is a directory.")
        for dirpath, dirnames, filenames in os.walk(path):
            for filename in filenames:
                # Check if the filename ends with .dds
                if filename.endswith('.dds'):
                    print(f"Processing: {filename}")
                    try:
                        # Define paths and convert .dds to .png
                        old_path = os.path.join(dirpath, filename)
                        new_path = old_path.replace('.dds', '.png')
                        with Image(filename=old_path) as img:
                            img.format = 'png'  # Ensure the image format is PNG before saving to the byte stream
                            img.save(filename=new_path)
                            img.close()
                        # Set permissions and delete original file
                        #os.chmod(old_path, 0o777)
                        os.remove(old_path)
                    except Exception as e:
                        print(f"An error occurred: {e}")