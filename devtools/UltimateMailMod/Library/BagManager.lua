
-- ###################
-- ##               ##
-- ##  Bag Manager  ##
-- ##               ##
-- ###################

UMMBagManager = {
  
  ItemList = {};
  
  GetItem = function(self, slotIndex)
    for i = 1, 180 do
      if (self.ItemList[i].Index == slotIndex) then
        return self.ItemList[i];
      end
    end
  end;
  
  MarkItem = function(self, slotIndex)
    if (self.ItemList[slotIndex]) then
      self.ItemList[slotIndex].Marked = true;
    end
  end;
  
  UnMarkItem = function(self, slotIndex)
    if (self.ItemList[slotIndex]) then
      self.ItemList[slotIndex].Marked = nil;
    end
  end;
  
  ClearMarks = function(self)
    for i = 1, 180 do
      self.ItemList[i].Marked = false;
    end
  end;
  
  Clear = function(self)
    self.ItemList = {};
  end;
  
  Load = function(self)
    self:Clear();
    local itemIndex = 0;
    for bagIndex = 1, 6 do
      for bagSlotIndex = 1, 30 do
        itemIndex = itemIndex + 1;
        local itemLink = "";
        local idx, texture, name, itemCount, locked, invalid = GetBagItemInfo(itemIndex);
        local tempItem = {};
        tempItem.Index = 0;
        tempItem.Empty = true;
        tempItem.Icon = nil;
        tempItem.Count = 0;
        tempItem.Link = nil;
        tempItem.Name = nil;
        tempItem.Marked = false;
        tempItem.Bound = false;
        if (texture ~= "") then
          local itemLink = GetBagItemLink(idx);
          tempItem.Index = idx;
          tempItem.Icon = texture;
          tempItem.Count = itemCount;
          tempItem.Link = itemLink;
          tempItem.Name = name;
          tempItem.Marked = false;
          tempItem.Empty = false;
        end
        table.insert(self.ItemList, tempItem);
      end
    end
  end;
  
};
