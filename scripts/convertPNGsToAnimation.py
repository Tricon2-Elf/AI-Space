import os
import re
import sys
import subprocess

def create_animation_from_pngs(directory, base_directory):
    folder_name = os.path.basename(directory)
    png_files = [f for f in os.listdir(directory) if f.lower().endswith('.png')]
    if not png_files:
        return

    png_files.sort()
    match = re.match(r"^(.+?)(\d+).png$", png_files[0])
    if match:
        prefix = match.group(1)
        digits = len(match.group(2))
    else:
        print(f"Unexpected filename format in {directory}")
        return

    ffmpeg_command = [
        "ffmpeg",
        "-framerate", "24",
        "-i", os.path.join(directory, f"{prefix}%0{digits}d.png"),
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        os.path.join(base_directory, f"{folder_name}_{prefix.strip('_').strip()}.mp4")
    ]

    subprocess.run(ffmpeg_command)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: script_name.py <base_directory>")
        sys.exit(1)

    base_directory = sys.argv[1]

    # Loop through all sub-directories of the base directory
    for root, dirs, _ in os.walk(base_directory):
        for directory in dirs:
            full_directory_path = os.path.join(root, directory)
            create_animation_from_pngs(full_directory_path, base_directory)
