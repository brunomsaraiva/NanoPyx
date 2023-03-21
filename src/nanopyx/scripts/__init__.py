import os
import sys


def find_files(root_dir: str, extension: str) -> list:
    """
    Returns a list of files with given extension in the root directory.
    :param root_dir: Root directory to search
    :param extension: File extension to search for
    :return: List of files with given extension
    """
    target_files = []
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith(extension):
                path = os.path.join(root, file)
                target_files.append(path)
                # print(f"Found file: {path}")

    return target_files
