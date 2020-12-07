--[[
Copyright (C) 2019 Wheatfield Media INC - All Rights Reserved
Unauthorized copying of this file, via any medium is strictly prohibited
Proprietary and confidential
Written by Wheatfield Media INC [vfxgrace29@gmail.com], October 2019

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE 
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--


local FU_ConnectNode = {}
local lastIndex = 0


function FU_ConnectNode:Init()
	self.activeNode = comp.ActiveTool
	self.nodeList = comp:GetToolList(true)
	self.maskInput = false
	self.replaceInput = true
	self.nameAttr = {}
	self.attrIDNode = {}
	self.templateNodeCount = 0
	self.upNode = nil
	self.inputID = {}

	self.templateNode = {}
	self.templateNodeIndex = {}
	self.templateNodeInput = {}
		
	self.SingleToMulti = 1
	self.MultiToMulti = 2
	self.MultiToSingle = 3
	
	self.connectType = 0

	self.ui = fu.UIManager
	self.App = bmd.UIDispatcher(self.ui)
	self.width = 800
	self.height = 450
	
	self.showIndex = 0
	self.fontSize = 14
	
	self.inputType = {"Image","DataType3D"}	
end


function FU_ConnectNode:GetNodeNameAttr()
	self.nameAttr = {}
	self.attrIDNode = {}
	self.templateNodeCount = 0

	for _,tool in pairs(self.nodeList) do 	
		self.nameAttr[tool.Name] = true
		if not self.attrIDNode[tool.ID] then	
			self.attrIDNode[tool.ID] = {}
			self.templateNodeCount = self.templateNodeCount + 1
			table.insert(self.attrIDNode[tool.ID],tool)		
		else
			table.insert(self.attrIDNode[tool.ID],tool)
		end
	end
end


function FU_ConnectNode:SortNodeList()
	local flow = comp.CurrentFrame.FlowView
	for k,v in pairs(self.attrIDNode) do
		table.sort(v,function(m,n) local _,y1 = flow:GetPos(m) local _,y2 = flow:GetPos(n) return y1 < y2 end)
	end
end


function FU_ConnectNode:GetConnectType()
	self:GetNodeNameAttr()
	
	self.upNode = nil
	self.inputID = {}
	self.templateNode = {}
	
	if self.activeNode then
		local tool = self.activeNode
		for m = 1,#self.inputType do
			local inputList = tool:GetInputList(self.inputType[m])
			if inputList then
				
				for i = 1,#inputList do			
					local data = inputList[i]:GetConnectedOutput()
					if data then					
						local node = data:GetTool()			
						if self.nameAttr[node.Name] then
							self.upNode = node
							self.templateNode[1] = tool
							self.inputID[1] = inputList[i].ID
							return self.SingleToMulti
						end					
					end
				end
			end
		end
			
		local output = tool:FindMainOutput(1)
		local connectInputs = output:GetConnectedInputs()
		
		if connectInputs then
			for _,input in pairs(connectInputs) do			 
				if input:GetAttrs()["INPS_DataType"] then				
					local node = input:GetTool()
					
					if self.nameAttr[node.Name] then			
						self.upNode = tool
						self.templateNode[1] = node
						self.inputID[1] = input.ID			
						
						return self.MultiToMulti
					end
				end
			end
		end
		self.upNode = tool
		return self.MultiToSingle
	else
		self:ShowWindow()
	end
end


function FU_ConnectNode:SingleConnectMulti()
	comp:StartUndo("SingleConnectMulti")
	
	for i = 1,#self.nodeList do	
		if self.nodeList[i] ~= self.upNode or self.nodeList[i] ~= self.templateNode[1] then
			local input = self.nodeList[i][self.inputID[1]]	
			if input then		
				input:ConnectTo(self.upNode:FindMainOutput(1))	
			end
		end
	end
	comp:EndUndo(true)
end


function FU_ConnectNode:SortMultiNodeList()
	local flow = comp.CurrentFrame.FlowView
	self.TestID = self.attrIDNode

	for k,v in pairs(self.attrIDNode) do
		table.sort(v,function(m,n) local x1,y1 = flow:GetPos(m) local x2,y2 = flow:GetPos(n) return y1 < y2 end)
	end
end


function FU_ConnectNode:GetTemplateNodes()
	local isEnd = true
	local node = self.upNode
	self.templateNode[1] = node
	local count = 1
	self.templateNodeInput = {}

	while isEnd do
		local outputList = node:FindMainOutput(1):GetConnectedInputs()
		
		if #outputList == 0 then
			isEnd = false
		else
			local isFind = false	

			for i = 1,#outputList do	
				node = outputList[i]:GetTool()
				if node then
					if self.nameAttr[node.Name] then					
						count = count + 1
						self.templateNode[count] = node
						self.templateNodeInput[count] = outputList[i].Name
						self.inputID[count] = outputList[i].ID
						break
					end			
				end
			end	
		end
	end
end


function FU_ConnectNode:GetMultiTemplate()
	self:SortMultiNodeList()
	local isEnd = true
	local node = self.upNode
	local count = 1
	
	self.templateNode[count] = node
	
	self.templateNameInfo ={}
	self.templateNameInfo = {[node.Name] = true}
	
	self.templateInfo = {}	
	self.templateInfo[count] = {node}
	self.templateIDInfo = {}
	self.templateIDInfo[node.ID] = {node}

	while isEnd do
		local outputList = node:FindMainOutput(1):GetConnectedInputs()
		if #outputList == 0 then
			isEnd = false
		else
			for i = 1,#outputList do
				
				if outputList[i]:GetAttrs()["INPS_DataType"] then
					node = outputList[i]:GetTool()			
					if node then			
						if self.nameAttr[node.Name] then
							if not self.templateNameInfo[node.Name] then
								count = count + 1
								self.templateNode[count] = node
								self.templateInfo[count] = {}
								table.insert(self.templateInfo[count],node)
								table.insert(self.templateInfo[count],outputList[i].ID)
								self.templateNameInfo[node.Name] = true

								if not self.templateIDInfo[node.ID] then						
									self.templateIDInfo[node.ID] = {node}		
								else				
									table.insert(self.templateIDInfo[node.ID],node)						
								end
							else
								table.insert(self.templateInfo[count],outputList[i].ID)	
							end
						end			
					end
				end
			end			
		end
	end
	
	self.matrixGrid = {}
	self.headerInfo = {}

	local flow = comp.CurrentFrame.FlowView
	for k,v in pairs(self.templateIDInfo) do
		local tmp = self.attrIDNode[k]
		local total = #tmp
		local step = #v
		
		if step == 1 then
			self.matrixGrid[k.."TemplateCount"..1] = tmp
			self.headerInfo[k.."TemplateCount"..1] = true
		else
			local num = 1
			local offset = 0
			for i = 1,total,step do 
				local head = k.."TemplateCount"..num
				self.matrixGrid[head] = {}
				self.headerInfo[head] = true

				for n = 1,step do 
					table.insert(self.matrixGrid[head],tmp[n+offset])			
				end
				table.sort(self.matrixGrid[head],function(k,v) local x1,_ = flow:GetPos(k) local x2,_ = flow:GetPos(v) return x1 < x2 end)
				
				offset = offset + step
				num = num+1
			end

			local reSort = {}
			for i = 1,total/step do			
				local head = k.."TemplateCount"..i

				for t = 1,#self.matrixGrid[head] do
					if reSort[t] then
						table.insert(reSort[t],self.matrixGrid[head][t])
					else
						reSort[t] = {}			
						table.insert(reSort[t],self.matrixGrid[head][t])		
					end	
				end
			end

			for i = 1,step do
				local head = k.."TemplateCount"..i
				self.matrixGrid[head] = reSort[i]
			end
			
		end
	end

	self.headerInfoSort = {}
	
	for i  = 1,count do
		local id = self.templateNode[i].ID
		for k = 1,count do
			if self.headerInfo[id.."TemplateCount"..k] then
				self.headerInfo[id.."TemplateCount"..k] = false
				self.headerInfoSort[i] = id.."TemplateCount"..k
				break
			end
		end
	end
end


function FU_ConnectNode:MultiConnectMulti()
	self:GetMultiTemplate()
	comp:StartUndo("MultiConnectMulti")
	
	for i = 2,#self.headerInfoSort do 
		local currentList = self.matrixGrid[self.headerInfoSort[i]]
		local prevList = self.matrixGrid[self.headerInfoSort[i-1]]
		local infoList = self.templateInfo[i]
		local num = 0
		if #currentList <= #prevList then
			num = #currentList
		else
			num = #prevList
		end
			
		for i = 2,num do
			for k = 2,#infoList do
				currentList[i][infoList[k]]:ConnectTo(prevList[i]:FindMainOutput(1))
			end
		end
	end
	comp:EndUndo(true)
end


function FU_ConnectNode:MultiConnectSingle(replaceNode)
	local node = self.activeNode

	if node.ID == "Merge3D" then
		comp:StartUndo("MultiConnectSingle")
		if replaceNode then
			local index = 1
			for i = 1,#self.nodeList do
				local selectNode = self.nodeList[i]
				local output = selectNode:FindMainOutput(1)
				if selectNode ~= node and output:GetAttrs()["OUTS_DataType"] == "DataType3D" then				
					node["SceneInput"..index]:ConnectTo(output)
					index = index + 1
				end
			end
		else
			for i = 1,#self.nodeList do
				local selectNode = self.nodeList[i]
				local output = selectNode:FindMainOutput(1)

				local outputList = output:GetConnectedInputs()
				local connect = true
				
				for _,input in pairs(outputList) do
					if input:GetAttrs()["INPS_DataType"] then				
						local tool = input:GetTool()			
						if tool == node then
							connect = false
						end		
					end
				end				

				if selectNode ~= node and output:GetAttrs()["OUTS_DataType"] == "DataType3D" and connect then
					local index = 1
					while node["SceneInput"..index]:GetAttrs().INPB_Connected == true do
						index = index+1		
					end
					node["SceneInput"..index]:ConnectTo(output)
				end		
			end
		end
		comp:EndUndo(true)
	else
		self:ShowWindow()
	end
end


function FU_ConnectNode:ConnectSelectNodes()
	local input = self:GetConnectType()

	if input == self.SingleToMulti then
		self:SingleConnectMulti()
	elseif input == self.MultiToMulti then
		self:MultiConnectMulti()
	elseif input == self.MultiToSingle then
		self:MultiConnectSingle()
	end
end


function FU_ConnectNode:GetFirstNode()
	self.upNode = nil
	self.templateNode = {}
	self.templateNodeIndex = {}
	self.templateNodeInput = {}
	
	isStartNode = false
	self:GetNodeNameAttr()
	
	local firstNode = nil
	local firstInput = nil
	
	for _,node in pairs(self.nodeList) do
		for i = 1,#self.inputType do
			local inputList = node:GetInputList(self.inputType[i])

			if inputList then
				for _,input in pairs(inputList) do
					local data = input:GetConnectedOutput()

					if data then
						local tool = data:GetTool()
						if self.nameAttr[tool.Name] then
							firstNode = tool
							firstInput = input
							break
						end
					end
				end
			end
			if firstNode then
				break
			end
		end
		
		if firstNode then
			break
		end
	
	end
	
	if firstNode then
		while true do
			local inputList = firstNode:GetInputList()
			local isAllEmpty = true

			if inputList then
				for _,input in pairs(inputList) do
					local data = input:GetConnectedOutput()
					if data then	
						local tool = data:GetTool()
						if self.nameAttr[tool.Name] then					
							firstNode = tool
							isAllEmpty = false
							break
						end
					end
				end

				if isAllEmpty then
					break
				end
			else
				self.upNode = firstNode
				break
			end
		end
		self.upNode = firstNode
	end
end


function FU_ConnectNode:GetUpNode()
	self:GetFirstNode()
	if self.upNode then
		local isEnd = true
		local node = self.upNode
		self.templateNode[1] = node

		local count = 1
		while isEnd do
			local outputList = node:FindMainOutput(1):GetConnectedInputs()
			if #outputList == 0 then
				isEnd = false
				break
			else	
				
				for _,input in pairs(outputList) do 
					if input:GetAttrs()["INPS_DataType"] then
						
						node = input:GetTool()
						if not self.nameAttr[node.Name] then
							isEnd = false
						else
							count = count + 1
							self.templateNode[count] = node
							self.templateNodeInput[count] = outputList[1].Name
							break
						end
					end	
				end
			end
		end
	end	
end


function FU_ConnectNode:GetUpNodeUI()
	self:GetFirstNode()
	
	if self.upNode then
		local isEnd = true
		local node = self.upNode
		local count = 0

		local downTool = nil	
		local inputNodeList = node:FindMainOutput(1):GetConnectedInputs()
		
		for i = 1,#inputNodeList do	
			if inputNodeList[i]:GetAttrs()["INPS_DataType"] then
				local tool = inputNodeList[i]:GetTool()
				if self.nameAttr[tool.Name] then
					count = count+1
					downTool = tool
					self.templateNode[count] = node
					self.templateNodeInput[count] = inputNodeList[i].ID
					self.inputID[count] = inputNodeList[i].Name
				end
			end		
		end

		for i = 1,#self.inputType do
			local inputList = downTool:GetInputList(self.inputType[i])
			for _,input in pairs(inputList) do
				if input ~= self.inputID[1] then
					local data = input:GetConnectedOutput()
					if data then		
						local tool = data:GetTool()
						if self.nameAttr[tool.Name] and (tool ~= self.upNode) then
							count = count + 1
							self.inputID[count] = input.Name
							self.templateNode[count] = tool
							self.templateNodeInput[count] = input.ID
						end
					end
				end
			end
		end
		table.insert(self.templateNode,downTool)
	end
end


function FU_ConnectNode:WindowControl()
	self.widget = self.App:AddWindow({
		ID = "FU_ConnectNode",WindowTitle = "Tool Connect Manager v1.0",
		WindowFlags = {
			Dialog = true,
			MSWindowsFixedSizeDialogHint = true,
		},
		FixedSize = {self.width,self.height},
		Spacing = 0, 

		self.ui:VGroup
		{
			self.ui:TabBar{ID = "SwitchTab",Font = self.ui:Font{PixelSize = self.fontSize},Weight = 0.0},
			self.ui:Stack{
				ID = "TabStack",
				Weight = 12.0,

				self.ui:VGroup
				{
					Weight = 0.0,
					self.ui:HGroup
					{
						Weight = 0.8,
						self.ui:Tree {ID = "SingleToMultiTree",Font = self.ui:Font{PixelSize = self.fontSize},SelectionMode = "ExtendedSelection",Events = {ItemDoubleClicked=true, ItemClicked=true},},
						self.ui:HGroup
						{
							Weight = 0.2,
							self.ui:Tree {ID = "DownInputInfo",Font = self.ui:Font{PixelSize = self.fontSize}, Events = {ItemDoubleClicked=true, ItemClicked=true},},
						}		
					},				
				},
				
				self.ui:Tree {ID = "NodeInfoTree",Font = self.ui:Font{PixelSize = self.fontSize},Events = {ItemDoubleClicked=true, ItemClicked=true},},		
			},

			self.ui:HGroup
			{
				Weight = 0.2,
				self.ui:CheckBox {ID = "ReplaceConnect",Font = self.ui:Font{PixelSize = self.fontSize}, Text = self.UIInfo.ReplaceConnect},
				self.ui:CheckBox {ID = "LimitID",Font = self.ui:Font{PixelSize = self.fontSize}, Text = self.UIInfo.LimitID},
				self.ui.VGap(0,5.0),
				self.ui:Button { ID = "AddTemplate",Font = self.ui:Font{PixelSize = self.fontSize},Text = self.UIInfo.AddTemplate,FixedSize = {120,30}},
				self.ui:Button { ID = "ConnectButton",Font = self.ui:Font{PixelSize = self.fontSize},Text = self.UIInfo.ConnectButton,FixedSize = {120,30}},		
				self.ui:Button { ID = "CannleButton",Font = self.ui:Font{PixelSize = self.fontSize},Text = self.UIInfo.CannleButton,FixedSize = {120,30}},
			},
		},
	})
end


function FU_ConnectNode:TranslateUI()
	self.EnglishUI = {
		ReplaceConnect = "Replace Connected",
		LimitID = "Only Same ID",
		AddTemplate = "Add Template",
		ConnectButton = "Connect",
		CannleButton = "Close",
		
		Tab1 = "Single to Multi",
		Tab2 = "Multi to Multi",
		Tab3 = "Multi to Single",
		
		Header1 = "Num",
		Header2 = "Name",
		Header3 = "Type",
		Header4 = "Input",
		
		Header5 = "Down Input",
		
		Warning = "Warning",
		Message1 = "The template is None,Please add connected template.",
		Message2 = "The template is not connect, Please connect template node.",
		Message3 = "Failed to find the template, Please add the template",
		Message4 = "Failed to find the Merge3D, Please make the Merge3D node active.",
		Message5 = "Selected Node is None, Please select nodes.",
		Message6 = "Selected Node or Active Node is None, Please select nodes.",
		Message7 = "Only Merge3D node is selected, Please select other Nodes.",
	}

	self.UIInfo = self.EnglishUI
end


function FU_ConnectNode:ShowWindow()
	self:WindowControl()
	self.Items = self.widget:GetItems()
	self.stack = self.Items.TabStack
	self.stack.CurrentIndex = 0
	self.tab = self.Items.SwitchTab
	self.limitID = self.Items.LimitID
	self.replaceConnect = self.Items.ReplaceConnect
	self.replaceConnect.Checked = true
	self.tab:AddTab(self.UIInfo.Tab1)
	self.tab:AddTab(self.UIInfo.Tab2)
	self.tab:AddTab(self.UIInfo.Tab3)

	self.tab.CurrentIndex = self.showIndex 

	self.NodeInfoTree = self.Items.NodeInfoTree
	self.SingleToMultiTree = self.Items.SingleToMultiTree
	self.DownInputInfo = self.Items.DownInputInfo
	
	self.nodeTree = { self.SingleToMultiTree,self.NodeInfoTree,self.DownInputInfo }

	self:SetTree()
	self:EventChanged()
end


function FU_ConnectNode:AddTemplate()
	self.widget.On.AddTemplate.Clicked = function(ev)		
		local index = self.tab.CurrentIndex
		local currentTree = nil
		
		if index == 0 then	
			currentTree = self.SingleToMultiTree	
		else
			currentTree = self.NodeInfoTree
		end

		for _,item in pairs(self.nodeTree) do
			item:Clear()
		end

		self.nodeList = comp:GetToolList(true)
		self.activeNode = comp.ActiveTool
		
		if #self.nodeList == 0 then	
			self:ShowMessage(self.UIInfo.Warning,self.UIInfo.Message5)
			return		
		end

		if index == 0 then
			self:GetUpNodeUI()	
		elseif index == 1 then
			self:GetUpNode()
		else
					
			self.activeNode = comp.ActiveTool
			if self.activeNode then
				self:GetConnectType()
				self:GetTemplateNodes()
			else
				self.upNode = self.nodeList[1]		
			end
		end
	
		self.inputID = {}
	
		if self.upNode then
			if index ~= 2 then	
				for row = 1,#self.templateNode do				
					local item = currentTree:NewItem()
					item.Text[0] = tostring(row)
					item.Text[1] = self.templateNode[row].Name
					item.Text[2] = self.templateNode[row].ID
					item.Text[3] = self.templateNodeInput[row]		
					currentTree:AddTopLevelItem(item)
				end
			else
				local num = 1
				for row = 1,#self.nodeList do 
					if self.nodeList[row].ID == "Merge3D" then
						local item = currentTree:NewItem()
						item.Text[0] = tostring(num)
						item.Text[1] = self.nodeList[row].Name
						item.Text[2] = self.nodeList[row].ID
						num = num+1
						
						currentTree:AddTopLevelItem(item)
					end
				end
			end
			
			local count = self.SingleToMultiTree:TopLevelItemCount()
			if index == 0 then
				local tool = comp:FindTool(self.SingleToMultiTree:TopLevelItem(count-1).Text[1])					
				local inputList = tool:GetInputList()	

				for _,input in pairs(inputList) do		
					local data = input:GetConnectedOutput()
					if data then	
						local node = data:GetTool()				
						if self.nameAttr[node.Name] then			
							local item = self.DownInputInfo:NewItem()						
							item.Text[0] = input.Name
							table.insert(self.inputID,input.ID)						
							self.DownInputInfo:AddTopLevelItem(item)						
						end
					end
				end				
			end
		else
			self:ShowMessage(self.UIInfo.Warning,self.UIInfo.Message6)
			return			
		end
	end
end


function FU_ConnectNode:ConnectButtonAdd()
	self.widget.On.ConnectButton.Clicked = function(ev)		
		local index = self.tab.CurrentIndex	
		local currentTree = nil

		local replaceConnect = self.replaceConnect.Checked
		if index == 0 then
			currentTree = self.SingleToMultiTree
		else
			currentTree = self.NodeInfoTree
		end
		
		local count = currentTree:TopLevelItemCount()
		
		if count == 0 then
			self:ShowMessage(self.UIInfo.Warning,self.UIInfo.Message1)
			return
		end

		comp:StartUndo("SingalConnect")
		
		if index == 0 then
			if count == 1 then
				self:ShowMessage(self.UIInfo.Warning,self.UIInfo.Message2)
				return
			end			
			
			local limitID = self.limitID.Checked
			local downTool = comp:FindTool(currentTree:TopLevelItem(count-1).Text[1])

			if not (self.upNode and downTool) then			
				self:ShowMessage(self.UIInfo.Warning,self.UIInfo.Message3)
				return
			end
			
			local selectNodes = self.SingleToMultiTree:SelectedItems()
			local upNodes = {}
			local num = #selectNodes

			if num == 1 then
				if count >= 3 then
					local item = selectNodes[1]
					self.upNode = comp:FindTool(item.Text[1])
					local inputID = {}
					inputID[1] = item.Text[3]
					self.inputID = inputID
				end
				
				upNodes[1] = self.upNode
				
			elseif num > 1 then
				local t = 0
				local isConnect = true
				for i = 1,num do
					local item = selectNodes[i]
					upNodes[i] = comp:FindTool(item.Text[1])
					self.inputID[i] = item.Text[3]
				end		
			else
				
				upNodes[1] = self.upNode
				
				local inputID = {}
				local m = 1
				for i = 1,#self.inputID do
					local input = downTool[self.inputID[i]]
					local data = input:GetConnectedOutput()
					if data then
						local tool = data:GetTool()
						if tool == self.upNode then
							inputID[m] = self.inputID[i]
							m = m+1
						end
					end	
				end
				
				self.inputID = inputID			
			end
			
			local count = #self.inputID
			
			for i = 1,#self.nodeList do
				local node = nil
				if limitID then
					if self.nodeList[i].ID == downTool.ID then
						node = self.nodeList[i]					
					end
				else
					node = self.nodeList[i]
				end
				
				if node and node ~= self.upNode and node ~= downTool then
					for m = 1,count do
						for n = 1,#upNodes do
							local input = node[self.inputID[m]]
							if replaceConnect then
								
								if input then
									local connect = true
									for _,v in pairs(self.templateNode) do
										if node == v then
											connect = false
										end
									end

									if num  < 1 then	
										if connect then
											input:ConnectTo(upNodes[1]:FindMainOutput(1))										
										end
									else
										input = node[self.inputID[n]]
										if input then
											if connect then
												input:ConnectTo(upNodes[n]:FindMainOutput(1))
											end
										end
									end
								end
							else
								if input then
									local connect = true		
									for _,v in pairs(self.templateNode) do
										if node == v then
											connect = false
										end
									end

									if num  < 1 then
										if not input:GetAttrs().INPB_Connected then
											if connect then
												input:ConnectTo(upNodes[1]:FindMainOutput(1))	
											end
										end
									else

										input = node[self.inputID[n]]
										if input then
											if not input:GetAttrs().INPB_Connected then
												if connect then
													input:ConnectTo(upNodes[n]:FindMainOutput(1))
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
			
		elseif index == 1 then
			if count == 1 then
				self:ShowMessage(self.UIInfo.Warning,self.UIInfo.Message2)
				return
			end	
			self:MultiConnectMulti()
		else

			self.activeNode = comp.ActiveTool
			local selectNodes = self.NodeInfoTree:SelectedItems()
			local count = self.NodeInfoTree:TopLevelItemCount()
			
			if (not self.activeNode or self.activeNode.ID ~= "Merge3D") and count > 1 then
				self:ShowMessage(self.UIInfo.Warning,self.UIInfo.Message4)
				return
			end

			if #self.nodeList < 2 then
				self:ShowMessage(self.UIInfo.Warning,self.UIInfo.Message7)
				return
			end

			if not self.activeNode then			
				self.activeNode = comp:FindTool(self.NodeInfoTree:TopLevelItem(0).Text[1])		
			end
			self:MultiConnectSingle(replaceConnect)
		end
		comp:EndUndo()
	end
end


function FU_ConnectNode:EventChanged()
	self.widget.On.NodeInfoTree.ItemClicked = function(ev)
		local name = ev.item.Text[1]
		local tool = comp:FindTool(name)
		comp:SetActiveTool(tool)
	end

	self.widget.On.SingleToMultiTree.ItemClicked = function(ev)
		local name = ev.item.Text[1]
		local tool = comp:FindTool(name)
		comp:SetActiveTool(tool)	
		
	end

	self.widget.On.SwitchTab.CurrentChanged = function(ev)
		self.tab:SetTabTextColor(lastIndex, {R=1, G=1, B=1, A=0.8})
		self.tab:SetTabTextColor(ev.Index, {R=0.49, G=0.58, B=0.89, A=1})
		lastIndex = ev.Index

		if ev.Index == 0 then		
			self.limitID:Show()
			self.replaceConnect:Show()
			
			self.DownInputInfo:Show()
			self.stack.CurrentIndex = 0
			self.SingleToMultiTree:Clear()
			self.DownInputInfo:Clear()

		elseif ev.Index == 1 then
			self.limitID:Hide()
			self.replaceConnect:Hide()

			self.stack.CurrentIndex = 1
			self.NodeInfoTree:Clear()	
		else
			self.limitID:Hide()
			self.replaceConnect:Show()
			
			self.stack.CurrentIndex = 1
			self.NodeInfoTree:Clear()
		end
	end

	self:AddTemplate()
	self:ConnectButtonAdd()
	
	self.widget.On.CannleButton.Clicked = function(ev)
		self.App:ExitLoop()
	end

	self.widget.On.FU_ConnectNode.Close = function(ev)
		self.App:ExitLoop()
	end

	self.widget:Show()
	self.App:RunLoop()
	self.widget:Hide()
end


function FU_ConnectNode:SetTree()
	for i = 1,2 do
		local head = self.nodeTree[i]:NewItem()
		head.Text[0] = self.UIInfo.Header1
		head.Text[1] = self.UIInfo.Header2
		head.Text[2] = self.UIInfo.Header3
		head.Text[3] = self.UIInfo.Header4
		
		self.nodeTree[i]:SetHeaderItem(head)
	
		local width = self.nodeTree[i]:Width()
		local size = (width-80) / 3
		
		self.nodeTree[i].ColumnWidth[0] = 80
		
		for m = 1,3 do
			self.nodeTree[i].ColumnWidth[m] = size
		end
	end

	local head = self.DownInputInfo:NewItem()
	head.Text[0] = self.UIInfo.Header5
	self.DownInputInfo:SetHeaderItem(head)
end


function FU_ConnectNode:ShowMessage(title, info)
    win = self.App:AddWindow({
        ID = "WinMsg",
        WindowTitle = title,Spacing = 10,
		FixedSize = {300,120},
        WindowFlags = {
            Dialog = true,
            MSWindowsFixedSizeDialogHint = true
        },
        
        self.ui:VGroup{
            ID = "root",            
            self.ui:HGroup{
				Weight = 4,
				
                self.ui:Label{
                    ID = "MessageInfo", 
                    Text = info,
                    Weight = 1,
                    Font = self.ui:Font{PixelSize = self.fontSize},
                    WordWrap = true,
                    Alignment = {
                        AlignHCenter = true,
                        AlignVCenter = true,
                    },
                 },
			},
			
            self.ui:HGroup{
                self.ui:Label{
                    Weight = 4,
					Font = self.ui:Font{PixelSize = self.fontSize},
                    ID = "Info",
                },
                self.ui:Button{ID = "ButtonOK", Font = self.ui:Font{PixelSize = self.fontSize},Text = "OK" },
            }
        }
    });

    function win.On.ButtonOK.Clicked(ev)
        self.App:ExitLoop();
    end

    function win.On.WinMsg.Close(ev)
        self.App:ExitLoop();
    end

    win:Show();
    self.App:RunLoop();
    win:Hide();
end


function FU_ConnectNode:New()
	local t = {}
	self:Init()
	self:TranslateUI()
	setmetatable(t,{__index = self})
	return t
end


local connectNode = FU_ConnectNode:New()
connectNode:ConnectSelectNodes()
