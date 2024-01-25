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


def rename_output(job_details, prefix=None):
    if prefix is None:
        prefix = ""

    file_path = Path(job_details["TargetDir"], job_details["OutputFilename"])
    subfolder = Path(job_details["TargetDir"], job_details["TimelineName"])
    file_path = file_path.parent / subfolder / file_path.name
    print(f"processing file {file_path.name}")

    prefixed_file_path = file_path.with_name(prefix + file_path.name)
    print(f"New name: {prefixed_file_path}")
    file_path.replace(prefixed_file_path)


def main():
    project = resolve.GetProjectManager().GetCurrentProject()
    timeline = project.GetCurrentTimeline()
    frame_rate = timeline.GetSetting("timelineFrameRate") or "25"
    project_name = project.GetName()
    detailedStatus = project.GetRenderJobStatus(job)
    job_details = getJobDetailsBasedOnId(project, job)
    rename_output(job_details, prefix="СЗ_")
    

if __name__ == "__main__":
    main()
