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

    A logfile called log.txt of the stderr will be output in the same directory as where the rendered file is placed in.
"""

import mimetypes
import os
import platform
import re
import shlex
import socket
import subprocess
import sys
from pathlib import Path


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
    print(f"file path: {file_path}")
    ffmpeg_log_filename = Path(file_path.parent) / "log.txt"
    output_filename = os.path.join(file_path.parent, str(file_path.stem) + "_h264.mp4")
    frame_rate = job_details["FrameRate"]
    mark_in = job_details["MarkIn"]
    os_platform = platform.system()
    print(f"[OS]: {os_platform}")
    # Check if the OS is Windows by searching for the Program Files folder
    if os_platform == "Windows":
        ffmpeg_path = "C:\\ffmpeg\\bin\\ffmpeg"
    elif os_platform == "Darwin":
        ffmpeg_path = "/usr/local/bin/ffmpeg"
    else:
        ffmpeg_path = "/usr/bin/ffmpeg"

    print(f"[FFMPEG Path] {ffmpeg_path}")
    padding = ""
    ffmpeg_apply_gamma_correction = ""

    if not is_movie_format(file_path.name):
        try:
            padding = re.search("\d+$", file_path.stem).group()
        except AttributeError:
            print("no sequence number found, render script stopped")
            sys.exit()
        print(f"sequence padding: {len(padding)}")
        file_path = os.path.join(file_path.parent, 
            re.sub("(.*[_.])\d+$", r"\1%0{}d".format(len(padding)), file_path.stem) + file_path.suffix
        )
        if Path(file_path).suffix in [".exr", ".dpx"]:
            print("[FFMPEG EXR Gammma Transform]")
            # Convert a linear exr to REC 709
            # ffmpegApplyGammaCorrection = '-apply_trc bt709'
            # or
            # Convert a linear exr file to sRGB
            ffmpeg_apply_gamma_correction = "-apply_trc iec61966_2_1"

    command = (
        f"{ffmpeg_path} {ffmpeg_apply_gamma_correction} -framerate {frame_rate} -f"
        f" image2 -start_number {mark_in} -i  {str(file_path)} -r {frame_rate} -y "
        " -f mp4 -vcodec libx264 -pix_fmt yuv420p"
        f" -acodec aac -strict -2  {output_filename}"
    )
    return command, ffmpeg_log_filename

def main():
    project = resolve.GetProjectManager().GetCurrentProject()
    timeline = project.GetCurrentTimeline()
    frame_rate = timeline.GetSetting("timelineFrameRate") or "25"
    project_name = project.GetName()
    detailedStatus = project.GetRenderJobStatus(job)
    job_details = getJobDetailsBasedOnId(project, job)
    messageToSend = (
        f"Job rendered by hostname: {socket.gethostname()}\nproject name:"
        f" {project_name}\n"
    )
    messageToSend += "Message initiated by script: {0}\n".format(
        os.path.abspath(sys.argv[0])
    )
    messageToSend += f'job id: {job}\njob status: {status}\nerror (if any): "{error}"\n'
    messageToSend += f"Detailed job status: {detailedStatus}\n"
    messageToSend += f"Job Details: {job_details}\n"

    print(messageToSend)
    ffmpeg_command, log_file = build_command(job_details)
    print(f"[FFMPEG command]\n{ffmpeg_command}")
    with open(log_file, "wb") as f:
        subprocess.run(shlex.split(ffmpeg_command), stderr=f)

if __name__ == "__main__":
    main()


