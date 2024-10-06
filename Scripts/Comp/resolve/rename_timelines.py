from resolve_utils import ResolveUtility

utils = ResolveUtility()


def rename_timelines(pattern):
    """
    rename timelines with a pattern
    """

    project = utils.get_current_project()
    timeline_count = project.GetTimelineCount()
    counter = 0
    for n in range(1, timeline_count + 1):
        timeline = project.GetTimelineByIndex(n)
        timeline_name = timeline.GetName()
        print(timeline_name)
        if timeline_name.startswith(pattern):
            counter += 7
            new_name = f"timeline_{counter:03}"
            timeline.SetName(new_name)


if __name__ == "__main__":
    rename_timelines("tl")
