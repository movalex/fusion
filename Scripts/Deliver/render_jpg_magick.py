#!/usr/bin/env python

"""
    This is a Davinci Resolve ffmpeg render script that is triggered by render job in the deliver page.
    It needs to be placed in the following OS specific directory:
    Mac OS X:   ~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Deliver
    Windows:    %APPDATA%\Blackmagic Design\DaVinci Resolve\Fusion\Scripts\Deliver\
    Linux:      /opt/resolve/Fusion/Scripts/Deliver/   (or /home/resolve/Fusion/Scripts/Deliver depending on installation)

    This trigger script will receive the following 3 global variables:
    "job" : job id.
    "status" : job status
    "error" : error string(if any)

    A logfile called log.txt of the stderr will be output in the same directory as where the rendered files are placed in.
"""

import mimetypes
import os
import re
import socket
import subprocess
import sys
from pathlib import Path

DEBUG = False


def getJobDetailsBasedOnId(project, jobId):
    jobList = project.GetRenderJobList()
    for jobDetail in jobList:
        if jobDetail["JobId"] == jobId:
            return jobDetail

    return ""


def is_movie_format(file_name):
    file_type = mimetypes.guess_type(file_name)
    if file_type[0]:
        return file_type[0].startswith("video")
    exts = (
        ".avi",
        ".dv",
        ".dvx",
        ".h264",
        ".m2ts",
        ".m2v",
        ".m4v",
        ".mkv",
        ".mov",
        ".movie",
        ".mp4",
        ".mp4v",
        ".mpeg",
        ".mpg",
        ".mpg2",
        ".mts",
        ".mtv",
        ".mxf",
        ".qt",
        ".ts",
        ".vid",
        ".xvid",
    )
    if Path(file_name).suffix.lower() in exts:
        return True


def build_command(job_details):
    file_path = Path(job_details["TargetDir"], job_details["OutputFilename"])

    print(f"[File Path]: {file_path}")

    log_filename = Path(file_path.parent) / "log.txt"
    frame_rate = job_details["FrameRate"]
    mark_in = job_details["MarkIn"]

    # app_path = "C:\Program Files\ImageMagick-7.1.0-Q16-HDRI\magick.exe"
    app_path = "magick"

    print(f"[App Used] {Path(app_path).name}")
    padding = ""

    if not is_movie_format(file_path.name):
        padding = re.search("\d+$", file_path.stem).group()
        scene = int(padding)

        print(f"sequence padding: {len(padding)}")

        serialize = Path(re.sub("\d+$", r"*", file_path.stem) + file_path.suffix)
        command_input_path = file_path.parent / serialize
        Path.mkdir(file_path.parent / "JPG", parents=True, exist_ok=True)
        serialize = Path(
            re.sub(f"\d+$", rf"%0{len(padding)}d", file_path.stem) + file_path.suffix
        )
        output_filename = file_path.parent / "JPG" / Path(serialize.stem + ".jpg")

        command = (
            f"{app_path} {command_input_path} -alpha off -colorspace sRGB -scene"
            f" {scene} {output_filename}"
        )
        return command, log_filename


def show_message(project_name):
    messageToSend = (
        f"Job rendered by hostname: {socket.gethostname()}\nproject name:"
        f" {project_name}\n"
    )
    messageToSend += "Message initiated by script: {0}\n".format(
        os.path.abspath(sys.argv[0])
    )
    messageToSend += f'job id: {job}\njob status: {status}\nerror (if any): "{error}"\n'
    messageToSend += f"Detailed job status: {detailedStatus}\n"

    print(messageToSend)


def main():
    project = resolve.GetProjectManager().GetCurrentProject()
    timeline = project.GetCurrentTimeline()
    frame_rate = timeline.GetSetting("timelineFrameRate") or "25"
    project_name = project.GetName()
    detailedStatus = project.GetRenderJobStatus(job)
    job_details = getJobDetailsBasedOnId(project, job)

    if DEBUG:
        show_message(project_name)
        print(f"Job Details: {job_details}\n")

    command, log_file = build_command(job_details)
    print(f"[Command]\n{command}")
    with open(log_file, "wb") as f:
        subprocess.Popen(command, stderr=f, stdout=f)


if __name__ == "__main__":
    main()
