def iter_upstream(tool):
    """Yields all upstream inputs for the current tool.

    Yields:
        tool: The input tools.

    """

    def get_connected_input_tools(tool):
        """Helper function that returns connected input tools for a tool."""
        inputs = []
        VALID_INPUT_TYPES = ['Image', 'Particles', 'Mask', 'DataType3D']
        for type_ in VALID_INPUT_TYPES:
            for input_ in tool.GetInputList(type_).values():
                output = input_.GetConnectedOutput()
                if output:
                    input_tool = output.GetTool()
                    inputs.append(input_tool)

        return inputs

    # Initialize process queue with the node's inputs itself
    queue = get_connected_input_tools(tool)

    # We keep track of which node names we have processed so far, to ensure we
    # don't process the same hierarchy again. We are not pushing the tool
    # itself into the set as that doesn't correctly recognize the same tool.
    # Since tool names are unique in a comp in Fusion we rely on that.
    collected = set(tool.Name for tool in queue)

    # Traverse upstream references for all nodes and yield them as we
    # process the queue.
    while queue:
        upstream_tool = queue.pop()
        yield upstream_tool

        # Find upstream tools that are not collected yet.
        upstream_inputs = get_connected_input_tools(upstream_tool)
        upstream_inputs = [t for t in upstream_inputs if
                           t.Name not in collected]

        queue.extend(upstream_inputs)
        collected.update(tool.Name for tool in upstream_inputs)
