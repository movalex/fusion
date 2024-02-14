def connect_to_fusion():
    import BlackmagicFusion as bmd

    fusion = bmd.scriptapp("Fusion")
    comp = fusion.GetCurrentComp()
    flow = comp.CurrentFrame.FlowView
    return fusion, comp, flow


fusion, comp, flow = connect_to_fusion()


class NodeHelper:
    def __init__(self, node=None):
        self.fusion = fusion
        self.comp = comp
        self.flow = flow
        if node is None:
            self._node, self._name = self.get_active_nodes()
        elif isinstance(node, dict):
            self.print_node_list(node)
            self._node = node[1]
            self._name = node[1].Name
        else:
            self._node = node
            self._name = node.Name

    def __str__(self):
        return self._name

    def __repr__(self):
        return self._name

    def print_node_list(self, tools):
        print("Currently selected: ")
        for tool in tools.values():
            print(" "*4, tool.Name)

    def get_active_nodes(self):
        active_tool = self.comp.ActiveTool
        if active_tool:
            return (active_tool, active_tool.Name)
        node_list = self.comp.GetToolList(True)
        if node_list:
            self.print_node_list(node_list)
            return (node_list[1], node_list[1].Name)
        else:
            # active tool is the one in the Inspector Not the selected one
            raise RuntimeError("No Tool Active in Fusion")

    def position(self):
        pos = self.flow.GetPosTable(self._node).values()
        return pos


# This works
a = NodeHelper()
print(repr(a))
print(a.position())

# This way too
node = comp.FindTool("CC1")
b = NodeHelper(node)
print(repr(b))
print(b.position())

# And this also
c = NodeHelper(comp.GetToolList(True))
print(repr(c))
print(c.position())


