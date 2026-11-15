-- A UE4SS widget double shared by the Lua tests: identity, children, render
-- transform, opacity and colour. Slots differ per test in kind and in what
-- they check, so each test gives its own slot factory: slotFor(parent,child)
-- returns the slot AddChild attaches, and a widget may replace w.slotFor.
-- fields, when given, are copied onto the widget.
return function(name,slotFor,fields)
    local w={name=name,children={},opacity=1,slotFor=slotFor,
        RenderTransform={Translation={X=0,Y=0},Scale={X=1,Y=1}},
        ColorAndOpacity={R=1,G=1,B=1,A=1}}
    for key,value in pairs(fields or {}) do w[key]=value end
    function w:IsValid() return self.invalid~=true end
    function w:GetFullName() return self.name end
    function w:GetAddress() return self.name..'-address' end
    function w:GetOuter() return self.outer end
    function w:GetParent() return self.parent end
    function w:GetChildrenCount() return #self.children end
    function w:GetChildAt(index) return self.children[index+1] end
    function w:GetRenderOpacity() return self.opacity end
    function w:SetRenderOpacity(value) self.opacity=value end
    function w:SetColorAndOpacity(value) self.ColorAndOpacity=value end
    function w:SetRenderTranslation(value) self.RenderTransform.Translation=value end
    function w:SetRenderScale(value) self.RenderTransform.Scale=value end
    function w:AddChild(child)
        assert(child.parent==nil)
        self.children[#self.children+1]=child
        child.parent=self
        child.Slot=self.slotFor(self,child)
        return child.Slot
    end
    function w:RemoveChild(child)
        for index,item in ipairs(self.children) do
            if item==child then
                table.remove(self.children,index)
                child.parent=nil
                return true
            end
        end
        return false
    end
    return w
end
