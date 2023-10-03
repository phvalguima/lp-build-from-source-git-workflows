#!/usr/bin/env python3

import requests

BASE_DIR = "resources"

with requests.Session() as s:
    s.auth = ("username", "password")  # TODO: change with correct credentials
    for version in ["8.3"]:  # ["8.2.1", "8.0.2", "7.4.2", "7.6", "7.6.1", "8.1.1"]:
        print(version)
        for scope in ["bin", "all"]:
            print(f"\t{scope}")

            file_name = f"gradle-{version}-{scope}"
            with open(f"{BASE_DIR}/{file_name}.zip.sha256") as f_checksum:
                checksum = f_checksum.read()
                print(f"\t\t{checksum}")

            for ext in ["zip"]:  # zip.sha256
                f_name = f"{BASE_DIR}/{file_name}.{ext}"
                with open(f_name, mode="rb") as data:
                    print(f"\t\tUploading: {f_name}")

                    response = s.request(
                        method="PUT",
                        url=f"https://jfrog.io/artifactory/.../gradle/{file_name}.{ext}", # .{ext}",  TODO: change endpoint, and remove extensions when  uploading checksum
                        verify=True,
                        data=data,
                        headers={
                            "Accept": "application/json",
                            "Content-Type": "application/vnd.org.jfrog.artifactory.storage.ItemCreated+json",   # TODO: comment when uploading checksum
                            "X-Checksum-Sha256": checksum,     # TODO: comment when uploading checksum
                        }
                    )
                    print(f"\t\t\t{response.text}")
