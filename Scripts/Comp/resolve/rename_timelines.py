def rename_timelines():
    """
    rename timelines with a pattern
    """

    project = resolve.GetProjectManager().GetCurrentProject()
    tl_count = project.GetTimelineCount()
    counter = 0
    for n in range(1, tl_count + 1):
        timeline = project.GetTimelineByIndex(n)
        print(timeline)
        tl_name = timeline.GetName()
        if tl_name.startswith("tl"):
            counter += 7
            new_name = f"timeline_{counter:03}"
            timeline.SetName(new_name)


if __name__ == "__main__":
    rename_timelines()
