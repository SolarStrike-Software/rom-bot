
local ResourceItemFilter = {
  
  ItemDB = {};
  
  priv_AddDB = function(self, type, itemID)
    if (not self.ItemDB[type]) then
      self.ItemDB[type] = {};
    end
    self.ItemDB[type][itemID] = true;
  end;
  
  Init = function(self)
    self.ItemDB = nil;
    self.ItemDB = {};
  end;
  
  IsItem = function(self, type, itemLink)
    if (self.ItemDB[type]) then
      local itemkind, itemData, itemName = ParseHyperlink(itemLink);
      local _, _, itemID = string.find(itemData, "^(%x+)");
      itemID = tonumber(itemID, 16);
      if (self.ItemDB[type][itemID]) then
        return true;
      else
        return nil;
      end
    else
      return nil;
    end
  end;
  
  GetTypeByID = function(self, id)
    local result = "None";
    if (id == 1) then
      result = "Runes";
    elseif (id == 2) then
      result = "FusionStones";
    elseif (id == 3) then
      result = "Jewels";
    elseif (id == 4) then
      result = "Ores";
    elseif (id == 5) then
      result = "Wood";
    elseif (id == 6) then
      result = "Herbs";
    elseif (id == 7) then
      result = "RawMaterials";
    elseif (id == 8) then
      result = "ProductionRunes";
    elseif (id == 9) then
      result = "Foods";
    elseif (id == 10) then
      result = "Desserts";
    elseif (id == 11) then
      result = "Potions";
    end
    
    return result;
  end;
  
};

-- Supplies
local function priv_AddFoods(db)
  -- Purple
  db:priv_AddDB("Foods", 203127); -- Dexterity Pumpkin Pie
  -- Blue
  db:priv_AddDB("Foods", 200359); -- Hot Stew
  db:priv_AddDB("Foods", 201533); -- Little Magic Biscuit
  db:priv_AddDB("Foods", 201532); -- Surprising Broth
  -- Green
  db:priv_AddDB("Foods", 203796); -- Baked Seafood Pie
  db:priv_AddDB("Foods", 200098); -- Caviar Sandwich
  db:priv_AddDB("Foods", 200097); -- Crisp Honey-roasted Chicken
  db:priv_AddDB("Foods", 203797); -- Cyclops Burrito
  db:priv_AddDB("Foods", 203799); -- Delicious Seafood Salad
  db:priv_AddDB("Foods", 200109); -- Delicious Swamp Mix
  db:priv_AddDB("Foods", 200103); -- Deluxe Seafood
  db:priv_AddDB("Foods", 200121); -- Doom's Banquet
  db:priv_AddDB("Foods", 203798); -- Flaming Sandwich
  db:priv_AddDB("Foods", 200086); -- Garlic Roasted Meat
  db:priv_AddDB("Foods", 200116); -- Imperial Seafood Pie
  db:priv_AddDB("Foods", 203795); -- Juicy Roasted Wing
  db:priv_AddDB("Foods", 203801); -- Miracle Salad
  db:priv_AddDB("Foods", 200115); -- Moti Blended Sausage
  db:priv_AddDB("Foods", 203794); -- Roasted Bacon
  db:priv_AddDB("Foods", 200085); -- Roasted Salty Fish
  db:priv_AddDB("Foods", 200091); -- Salted Fish with Sauce
  db:priv_AddDB("Foods", 203803); -- Scalok Sausage
  db:priv_AddDB("Foods", 200092); -- Smoked Bacon with Herbs
  db:priv_AddDB("Foods", 203802); -- Special Canyon Mix
  db:priv_AddDB("Foods", 200104); -- Spicy Meatsauce Burrito
  db:priv_AddDB("Foods", 203800); -- Superior Swamp Mix
  db:priv_AddDB("Foods", 200110); -- Unimaginable Salad
  -- White
  db:priv_AddDB("Foods", 202242); -- Aged Realgar Wine
  db:priv_AddDB("Foods", 200114); -- Cheese Fishcake
  db:priv_AddDB("Foods", 200101); -- Creamy Seafood Pie
  db:priv_AddDB("Foods", 200119); -- Dragon's Banquet
  db:priv_AddDB("Foods", 202240); -- Egg Rice Dumplings
  db:priv_AddDB("Foods", 200096); -- Fish Egg Sandwich
  db:priv_AddDB("Foods", 200113); -- General's Three-color Sausage
  db:priv_AddDB("Foods", 200095); -- Honey Roasted Chicken
  db:priv_AddDB("Foods", 200102); -- Meatsauce Burrito
  db:priv_AddDB("Foods", 202241); -- Realgar Wine
  db:priv_AddDB("Foods", 202239); -- Red Bean Rice Dumplings
  db:priv_AddDB("Foods", 200083); -- Roasted Fish
  db:priv_AddDB("Foods", 200084); -- Roasted Meat
  db:priv_AddDB("Foods", 200089); -- Salted Fish
  db:priv_AddDB("Foods", 200108); -- Seaworm Salad
  db:priv_AddDB("Foods", 200090); -- Smoked Bacon
  db:priv_AddDB("Foods", 200107); -- Swamp Mix
end

local function priv_AddDesserts(db)
  -- Blue
  db:priv_AddDB("Desserts", 200776); -- Necropolis Cake
  -- Green
  db:priv_AddDB("Desserts", 200126); -- Aromatic Fruit
  db:priv_AddDB("Desserts", 200129); -- Crisp Doughnuts
  db:priv_AddDB("Desserts", 200137); -- Delicious Mushroom Pie
  db:priv_AddDB("Desserts", 200134); -- Excellent Meat and Bread
  db:priv_AddDB("Desserts", 200146); -- Exquisite Cocoa Shortbread
  db:priv_AddDB("Desserts", 200145); -- Exquisite Tea-scented Muffins
  db:priv_AddDB("Desserts", 200142); -- Forestsong Soft Cake
  db:priv_AddDB("Desserts", 200125); -- Fruits and Cheese
  db:priv_AddDB("Desserts", 200133); -- Garlic Bread with Herbs
  db:priv_AddDB("Desserts", 200149); -- Laor Forest Tart
  db:priv_AddDB("Desserts", 200141); -- Magic Fruit Pie
  db:priv_AddDB("Desserts", 200138); -- Rainbow Crystal Candy
  db:priv_AddDB("Desserts", 200130); -- Sweet Fruit Bread
  -- White
  db:priv_AddDB("Desserts", 200128); -- Bread and Jam
  db:priv_AddDB("Desserts", 203281); -- Chocolate
  db:priv_AddDB("Desserts", 203863); -- Chocolate Crisp
  db:priv_AddDB("Desserts", 200144); -- Cocoa Shortbread with Herbs
  db:priv_AddDB("Desserts", 200136); -- Crystal Sugar
  db:priv_AddDB("Desserts", 200139); -- Exotic Fruit Pie
  db:priv_AddDB("Desserts", 200131); -- Garlic Bread
  db:priv_AddDB("Desserts", 200140); -- Green Soft Cake
  db:priv_AddDB("Desserts", 200124); -- Herbal Fruit
  db:priv_AddDB("Desserts", 203282); -- Lolllipop
  db:priv_AddDB("Desserts", 200132); -- Meat and Bread
  db:priv_AddDB("Desserts", 200135); -- Mushroom Pie
  db:priv_AddDB("Desserts", 200123); -- Sour Cheeseball
  db:priv_AddDB("Desserts", 200127); -- Sweet Deep-fried Doughnuts
  db:priv_AddDB("Desserts", 200143); -- Tea-scented Muffins
  db:priv_AddDB("Desserts", 203859); -- Wine
  db:priv_AddDB("Desserts", 200147); -- Wizard's Rations
end

local function priv_AddPotions(db)
  -- Purple
  db:priv_AddDB("Potions", 205975); -- Advanced Experience Potion (30 Days)
  db:priv_AddDB("Potions", 205977); -- Advanced Skill Potion (30 Days)
  db:priv_AddDB("Potions", 205974); -- Basic Experience Potion (30 Days)
  db:priv_AddDB("Potions", 203593); -- Basic Skill Potion
  db:priv_AddDB("Potions", 205976); -- Basic Skill Potion (30 Days)
  db:priv_AddDB("Potions", 201139); -- Big Angel's Sigh
  db:priv_AddDB("Potions", 201134); -- Experience Potion
  db:priv_AddDB("Potions", 202264); -- Experience Potion (1 Day)
  db:priv_AddDB("Potions", 205962); -- Experience Potion (30 Days)
  db:priv_AddDB("Potions", 202319); -- Experience Potion (7 Days)
  db:priv_AddDB("Potions", 201617); -- Expert Skill Potion
  db:priv_AddDB("Potions", 203574); -- High Quality Experience Potion
  db:priv_AddDB("Potions", 201608); -- Lasting Experience Potion
  db:priv_AddDB("Potions", 203592); -- Lesser Speed Mount Potion (30 Days)
  db:priv_AddDB("Potions", 203591); -- Lesser Speed Mount Potion (7 Days)
  db:priv_AddDB("Potions", 205978); -- Luck Potion (30 Days)
  db:priv_AddDB("Potions", 201618); -- Master Skill Potion
  db:priv_AddDB("Potions", 201460); -- Party Experience Potion
  db:priv_AddDB("Potions", 201141); -- Phoenix' Redemption
  db:priv_AddDB("Potions", 202322); -- Potent Luck Potion
  db:priv_AddDB("Potions", 201619); -- Potion of Luck
  db:priv_AddDB("Potions", 201609); -- Powerful Experience Potion
  db:priv_AddDB("Potions", 202670); -- Riding Medicine (30 Days)
  db:priv_AddDB("Potions", 202669); -- Riding Medicine (7 Days)
  db:priv_AddDB("Potions", 201610); -- Skill Potion
  db:priv_AddDB("Potions", 202320); -- Skill Potion (1 Day)
  db:priv_AddDB("Potions", 205963); -- Skill Potion (30 Days)
  db:priv_AddDB("Potions", 202321); -- Skill Potion (7 Days)
  db:priv_AddDB("Potions", 202540); -- St. Phoenix
  db:priv_AddDB("Potions", 203415); -- Transformation Potion - Giant Guardian
  db:priv_AddDB("Potions", 203416); -- Transformation Potion - Gingerbread Man
  db:priv_AddDB("Potions", 203417); -- Transformation Potion - Santa Claus
  db:priv_AddDB("Potions", 204533); -- Universal Potion
  -- Blue
  db:priv_AddDB("Potions", 200286); -- Shock Potion
  db:priv_AddDB("Potions", 202153); -- Universal Potion
  -- Green
  db:priv_AddDB("Potions", 200192); -- Ancient Spirit Water
  db:priv_AddDB("Potions", 200154); -- Basic Healing Potion
  db:priv_AddDB("Potions", 200155); -- Basic Mana Potion
  db:priv_AddDB("Potions", 200425); -- Elixir of the Sage
  db:priv_AddDB("Potions", 200225); -- Embrace of the Muse
  db:priv_AddDB("Potions", 203805); -- Fiery Medicine
  db:priv_AddDB("Potions", 200178); -- Healing Potion
  db:priv_AddDB("Potions", 200277); -- Hero Potion
  db:priv_AddDB("Potions", 200172); -- Invisibility Potion
  db:priv_AddDB("Potions", 200179); -- Mana Potion
  db:priv_AddDB("Potions", 203509); -- Potion of Exquisite Skill
  db:priv_AddDB("Potions", 203511); -- Potion of Focused Will
  db:priv_AddDB("Potions", 203806); -- Powder of Peace
  db:priv_AddDB("Potions", 200276); -- Purified Stimulating Scent
  db:priv_AddDB("Potions", 203807); -- Spellweaver Potion
  db:priv_AddDB("Potions", 203507); -- Strength of Battle
  db:priv_AddDB("Potions", 200274); -- Strong Healing Potion
  db:priv_AddDB("Potions", 200275); -- Strong Mana Potion
  db:priv_AddDB("Potions", 200173); -- Strong Stimulant
  db:priv_AddDB("Potions", 200199); -- Touch of the Unicorn
  db:priv_AddDB("Potions", 200427); -- Tranquility Powder
  db:priv_AddDB("Potions", 203808); -- Transparence Potion
  db:priv_AddDB("Potions", 203809); -- Unicorn's Present
  -- White
  db:priv_AddDB("Potions", 200820); -- Ancestral Spirit Herbs
  db:priv_AddDB("Potions", 200811); -- Barbarian Herbs
  db:priv_AddDB("Potions", 200664); -- Basic First Aid Potion
  db:priv_AddDB("Potions", 201043); -- Basic Magic Potion
  db:priv_AddDB("Potions", 200151); -- Basic Medicine
  db:priv_AddDB("Potions", 200152); -- Basic Spirit Potion
  db:priv_AddDB("Potions", 202906); -- Bean Paste Mooncake
  db:priv_AddDB("Potions", 203867); -- Blue Magic Potion
  db:priv_AddDB("Potions", 202907); -- Coconut Mooncake
  db:priv_AddDB("Potions", 200418); -- Collection Potion I
  db:priv_AddDB("Potions", 200420); -- Collection Potion II
  db:priv_AddDB("Potions", 200422); -- Collection Potion III
  db:priv_AddDB("Potions", 201053); -- Condensed Magic Potion
  db:priv_AddDB("Potions", 201056); -- Crystal Mana Medicine
  db:priv_AddDB("Potions", 205867); -- Dexterity Potion
  db:priv_AddDB("Potions", 201052); -- Elemental Mana Stone
  db:priv_AddDB("Potions", 201061); -- Elemental Spirit Stone
  db:priv_AddDB("Potions", 204890); -- Elemental Spirit Stone
  db:priv_AddDB("Potions", 200807); -- First Aid Potion
  db:priv_AddDB("Potions", 203510); -- Focus Potion
  db:priv_AddDB("Potions", 200812); -- Healer's First Aid Potion
  db:priv_AddDB("Potions", 205869); -- Health Potion
  db:priv_AddDB("Potions", 205863); -- Intelligence Potion
  db:priv_AddDB("Potions", 200194); -- Life Source
  db:priv_AddDB("Potions", 201046); -- Magic Potion
  db:priv_AddDB("Potions", 204130); -- Magical Wine
  db:priv_AddDB("Potions", 200808); -- Major First Aid Potion
  db:priv_AddDB("Potions", 201047); -- Major Magic Potion
  db:priv_AddDB("Potions", 200175); -- Mana Potion
  db:priv_AddDB("Potions", 200195); -- Mana Source
  db:priv_AddDB("Potions", 200819); -- Military Regeneration Formula
  db:priv_AddDB("Potions", 200018); -- Mysterious Potion
  db:priv_AddDB("Potions", 200426); -- Pacification Powder
  db:priv_AddDB("Potions", 203499); -- Phirius Elixir - Type A
  db:priv_AddDB("Potions", 203500); -- Phirius Elixir - Type B
  db:priv_AddDB("Potions", 203501); -- Phirius Elixir - Type C
  db:priv_AddDB("Potions", 203502); -- Phirius Elixir - Type D
  db:priv_AddDB("Potions", 203503); -- Phirius Elixir - Type E
  db:priv_AddDB("Potions", 203494); -- Phirius Potion - Type A
  db:priv_AddDB("Potions", 203495); -- Phirius Potion - Type B
  db:priv_AddDB("Potions", 203496); -- Phirius Potion - Type C
  db:priv_AddDB("Potions", 203497); -- Phirius Potion - Type D
  db:priv_AddDB("Potions", 203498); -- Phirius Potion - Type E
  db:priv_AddDB("Potions", 203489); -- Phirius Special Water - Type A
  db:priv_AddDB("Potions", 203490); -- Phirius Special Water - Type B
  db:priv_AddDB("Potions", 203491); -- Phirius Special Water - Type C
  db:priv_AddDB("Potions", 203492); -- Phirius Special Water - Type D
  db:priv_AddDB("Potions", 203493); -- Phirius Special Water - Type E
  db:priv_AddDB("Potions", 201057); -- Potent Crystal Mana Medicine
  db:priv_AddDB("Potions", 205868); -- Potent Dexterity Potion
  db:priv_AddDB("Potions", 205870); -- Potent Health Potion
  db:priv_AddDB("Potions", 205864); -- Potent Intelligence Potion
  db:priv_AddDB("Potions", 200816); -- Potent Regeneration Formula
  db:priv_AddDB("Potions", 205862); -- Potent Strength Potion
  db:priv_AddDB("Potions", 205866); -- Potent Wisdom Potion
  db:priv_AddDB("Potions", 203508); -- Potion of Energy
  db:priv_AddDB("Potions", 200273); -- Potion of Fire Elemental Affinity
  db:priv_AddDB("Potions", 200272); -- Potion of Holy Power
  db:priv_AddDB("Potions", 200424); -- Potion of Potential
  db:priv_AddDB("Potions", 203506); -- Potion of Rage
  db:priv_AddDB("Potions", 200159); -- Potion of Speed
  db:priv_AddDB("Potions", 200270); -- Powerful Spirit Potion
  db:priv_AddDB("Potions", 203159); -- Pumpkin Pizza
  db:priv_AddDB("Potions", 203160); -- Pumpkin Soup of Happiness
  db:priv_AddDB("Potions", 201060); -- Refined Crystal Mana Medicine
  db:priv_AddDB("Potions", 200815); -- Regeneration Mixture
  db:priv_AddDB("Potions", 200174); -- Salve
  db:priv_AddDB("Potions", 200663); -- Simple First Aid Potion
  db:priv_AddDB("Potions", 201042); -- Simple Magic Potion
  db:priv_AddDB("Potions", 204889); -- Spirit Herb
  db:priv_AddDB("Potions", 200160); -- Stimulant
  db:priv_AddDB("Potions", 200271); -- Stimulant Scent
  db:priv_AddDB("Potions", 205861); -- Strength Potion
  db:priv_AddDB("Potions", 200229); -- Strong Medicine
  db:priv_AddDB("Potions", 200196); -- Superior Collection Potion I
  db:priv_AddDB("Potions", 200197); -- Superior Collection Potion II
  db:priv_AddDB("Potions", 200198); -- Superior Collection Potion III
  db:priv_AddDB("Potions", 202886); -- Training First-aid Potion
  db:priv_AddDB("Potions", 202887); -- Training Magic Potion
  db:priv_AddDB("Potions", 205865); -- Wisdom Potion
  db:priv_AddDB("Potions", 200176); -- Witch Doctor Elixir
end

-- Materials
local function priv_AddOres(db)
  -- Brown
  db:priv_AddDB("Ores", 201747); -- Arcane Abyss-Mercury Ingot
  db:priv_AddDB("Ores", 201722); -- Arcane Copper Ingot
  db:priv_AddDB("Ores", 202590); -- Arcane Cyanide Ingot
  db:priv_AddDB("Ores", 201733); -- Arcane Dark Crystal Ingot
  db:priv_AddDB("Ores", 202589); -- Arcane Flame Dust Ingot
  db:priv_AddDB("Ores", 202594); -- Arcane Frost Crystal Ingot
  db:priv_AddDB("Ores", 201719); -- Arcane Iron Ingot
  db:priv_AddDB("Ores", 202595); -- Arcane Mica Ingot
  db:priv_AddDB("Ores", 202593); -- Arcane Mithril Ingot
  db:priv_AddDB("Ores", 201746); -- Arcane Moon Silver Ingot
  db:priv_AddDB("Ores", 202592); -- Arcane Mysticite Ingot
  db:priv_AddDB("Ores", 202591); -- Arcane Rock Crystal Ingot
  db:priv_AddDB("Ores", 201748); -- Arcane Rune Obsidian Ingot
  db:priv_AddDB("Ores", 201734); -- Arcane Silver Ingot
  db:priv_AddDB("Ores", 201712); -- Arcane Tin Ingot
  db:priv_AddDB("Ores", 201735); -- Arcane Wizard-Iron Ingot
  db:priv_AddDB("Ores", 200263); -- Arcane Zinc Ingot
  -- Orange
  db:priv_AddDB("Ores", 200261); -- Tempered Abyss-Mercury Ingot
  db:priv_AddDB("Ores", 200251); -- Tempered Copper Ingot
  db:priv_AddDB("Ores", 202583); -- Tempered Cyanide Ingot
  db:priv_AddDB("Ores", 200253); -- Tempered Dark Crystal Ingot
  db:priv_AddDB("Ores", 202582); -- Tempered Flame Dust Ingot
  db:priv_AddDB("Ores", 202587); -- Tempered Frost Crystal Ingot
  db:priv_AddDB("Ores", 200248); -- Tempered Iron Ingot
  db:priv_AddDB("Ores", 202588); -- Tempered Mica Ingot
  db:priv_AddDB("Ores", 202586); -- Tempered Mithril Ingot
  db:priv_AddDB("Ores", 200259); -- Tempered Moon Silver Ingot
  db:priv_AddDB("Ores", 202585); -- Tempered Mysticite Ingot
  db:priv_AddDB("Ores", 202584); -- Tempered Rock Crystal Ingot
  db:priv_AddDB("Ores", 200262); -- Tempered Rune Obsidian Ingot
  db:priv_AddDB("Ores", 200255); -- Tempered Silver Ingot
  db:priv_AddDB("Ores", 200240); -- Tempered Tin Ingot
  db:priv_AddDB("Ores", 200257); -- Tempered Wizard-Iron Ingot
  db:priv_AddDB("Ores", 200233); -- Tempered Zinc Ingot
  -- Purple
  db:priv_AddDB("Ores", 201744); -- Abyss-Mercury Ingot
  db:priv_AddDB("Ores", 201739); -- Copper Ingot
  db:priv_AddDB("Ores", 202576); -- Cyanide Ingot
  db:priv_AddDB("Ores", 201740); -- Dark Crystal Ingot
  db:priv_AddDB("Ores", 202575); -- Flame Dust Ingot
  db:priv_AddDB("Ores", 202580); -- Frost Crystal Ingot
  db:priv_AddDB("Ores", 201738); -- Iron Ingot
  db:priv_AddDB("Ores", 202581); -- Mica Ingot
  db:priv_AddDB("Ores", 202579); -- Mithril Ingot
  db:priv_AddDB("Ores", 201743); -- Moon Silver Ingot
  db:priv_AddDB("Ores", 202578); -- Mysticite Ingot
  db:priv_AddDB("Ores", 202577); -- Rock Crystal Ingot
  db:priv_AddDB("Ores", 201745); -- Rune Obsidian Ingot
  db:priv_AddDB("Ores", 201741); -- Silver Ingot
  db:priv_AddDB("Ores", 201737); -- Tin Ingot
  db:priv_AddDB("Ores", 201742); -- Wizard-Iron Ingot
  db:priv_AddDB("Ores", 201736); -- Zinc Ingot
  -- Blue
  db:priv_AddDB("Ores", 201731); -- Abyss-Mercury Nugget
  db:priv_AddDB("Ores", 201726); -- Copper Nugget
  db:priv_AddDB("Ores", 202569); -- Cyanide Nugget
  db:priv_AddDB("Ores", 201727); -- Dark Crystal Nugget
  db:priv_AddDB("Ores", 202568); -- Flame Dust Nugget
  db:priv_AddDB("Ores", 202573); -- Frost Crystal Nugget
  db:priv_AddDB("Ores", 201725); -- Iron Nugget
  db:priv_AddDB("Ores", 202574); -- Mica Nugget
  db:priv_AddDB("Ores", 202572); -- Mithril Nugget
  db:priv_AddDB("Ores", 201730); -- Moon Silver Nugget
  db:priv_AddDB("Ores", 202571); -- Mysticite Nugget
  db:priv_AddDB("Ores", 202570); -- Rock Crystal Nugget
  db:priv_AddDB("Ores", 201732); -- Rune Obsidian Nugget
  db:priv_AddDB("Ores", 201728); -- Silver Nugget
  db:priv_AddDB("Ores", 201724); -- Tin Nugget
  db:priv_AddDB("Ores", 201729); -- Wizard-Iron Nugget
  db:priv_AddDB("Ores", 201723); -- Zinc Nugget
  -- Green
  db:priv_AddDB("Ores", 201720); -- Abyss-Mercury Sand
  db:priv_AddDB("Ores", 201714); -- Copper Sand
  db:priv_AddDB("Ores", 202562); -- Cyanide Sand
  db:priv_AddDB("Ores", 201715); -- Dark Crystal Sand
  db:priv_AddDB("Ores", 202561); -- Flame Dust Sand
  db:priv_AddDB("Ores", 202566); -- Frost Crystal Sand
  db:priv_AddDB("Ores", 201713); -- Iron Sand
  db:priv_AddDB("Ores", 202567); -- Mica Sand
  db:priv_AddDB("Ores", 202565); -- Mithrial Sand
  db:priv_AddDB("Ores", 201718); -- Moon Silver Sand
  db:priv_AddDB("Ores", 202564); -- Mysticite Sand
  db:priv_AddDB("Ores", 202563); -- Rock Crystal Sand
  db:priv_AddDB("Ores", 201721); -- Rune Obsidian Sand
  db:priv_AddDB("Ores", 201716); -- Silver Sand
  db:priv_AddDB("Ores", 201711); -- Tin Sand
  db:priv_AddDB("Ores", 201717); -- Wizard-Iron Sand
  db:priv_AddDB("Ores", 201710); -- Zinc Sand
  -- White
  db:priv_AddDB("Ores", 200264); -- Abyss-Mercury
  db:priv_AddDB("Ores", 200236); -- Copper Ore
  db:priv_AddDB("Ores", 200506); -- Cyanide
  db:priv_AddDB("Ores", 200238); -- Dark Crystal
  db:priv_AddDB("Ores", 200507); -- Flame Dust
  db:priv_AddDB("Ores", 202315); -- Frost Crystal
  db:priv_AddDB("Ores", 200234); -- Iron Ore
  db:priv_AddDB("Ores", 202316); -- Mica
  db:priv_AddDB("Ores", 200265); -- Mithril
  db:priv_AddDB("Ores", 200244); -- Moon Silver Ore
  db:priv_AddDB("Ores", 200269); -- Mysticite
  db:priv_AddDB("Ores", 200249); -- Rock Crystal
  db:priv_AddDB("Ores", 200268); -- Rune Obsidian Ore
  db:priv_AddDB("Ores", 200239); -- Silver Ore
  db:priv_AddDB("Ores", 200232); -- Tin Ore
  db:priv_AddDB("Ores", 200242); -- Wizard-Iron Ore
  db:priv_AddDB("Ores", 200230); -- Zinc Ore
end

local function priv_AddWood(db)
  -- Brown
  db:priv_AddDB("Wood", 202630); -- Exquisite Aeontree Plank
  db:priv_AddDB("Wood", 201771); -- Exquisite Ancient Spirit Oak Wood Plank
  db:priv_AddDB("Wood", 200321); -- Exquisite Ash Plank
  db:priv_AddDB("Wood", 202624); -- Exquisite Chome Wood Plank
  db:priv_AddDB("Wood", 202627); -- Exquisite Dragon Beard Root Plank
  db:priv_AddDB("Wood", 201756); -- Exquisite Dragonlair Wood Plank
  db:priv_AddDB("Wood", 202629); -- Exquisite Fairywood Plank
  db:priv_AddDB("Wood", 200328); -- Exquisite Holly Plank
  db:priv_AddDB("Wood", 200324); -- Exquisite Maple Plank
  db:priv_AddDB("Wood", 200325); -- Exquisite Oak Plank
  db:priv_AddDB("Wood", 200327); -- Exquisite Pine Plank
  db:priv_AddDB("Wood", 202626); -- Exquisite Redwood Plank
  db:priv_AddDB("Wood", 202628); -- Exquisite Sagewood Plank
  db:priv_AddDB("Wood", 202625); -- Exquisite Stone Rotan Plank
  db:priv_AddDB("Wood", 201755); -- Exquisite Tarslin Demon Wood Plank
  db:priv_AddDB("Wood", 200323); -- Exquisite Willow Plank
  db:priv_AddDB("Wood", 200330); -- Exquisite Yew Plank
  -- Orange
  db:priv_AddDB("Wood", 202623); -- Refined Aeontree Plank
  db:priv_AddDB("Wood", 200319); -- Refined Ancient Spirit Oak Plank
  db:priv_AddDB("Wood", 200294); -- Refined Ash Plank
  db:priv_AddDB("Wood", 202617); -- Refined Chime Wood Plank
  db:priv_AddDB("Wood", 202620); -- Refined Dragon Beard Root Plank
  db:priv_AddDB("Wood", 200317); -- Refined Dragonlair Wood Plank
  db:priv_AddDB("Wood", 202622); -- Refined Fairywood Plank
  db:priv_AddDB("Wood", 200309); -- Refined Holly Plank
  db:priv_AddDB("Wood", 200303); -- Refined Maple Plank
  db:priv_AddDB("Wood", 200305); -- Refined Oak Plank
  db:priv_AddDB("Wood", 200308); -- Refined Pine Plank
  db:priv_AddDB("Wood", 202619); -- Refined Redwood Plank
  db:priv_AddDB("Wood", 202621); -- Refined Sagewood Plank
  db:priv_AddDB("Wood", 202618); -- Refined Stone Rotan Plank
  db:priv_AddDB("Wood", 200315); -- Refined Tarslin Demon Wood Plank
  db:priv_AddDB("Wood", 200301); -- Refined Willow Plank
  db:priv_AddDB("Wood", 200314); -- Refined Yew Plank
  -- Purple
  db:priv_AddDB("Wood", 202616); -- Aeontree Plank
  db:priv_AddDB("Wood", 201782); -- Ancient Spirit Oak Plank
  db:priv_AddDB("Wood", 201773); -- Ash Plank
  db:priv_AddDB("Wood", 202610); -- Chime Wood Plank
  db:priv_AddDB("Wood", 202613); -- Dragon Beard Root Plank
  db:priv_AddDB("Wood", 201781); -- Dragonlair Wood Plank
  db:priv_AddDB("Wood", 202615); -- Fairywood Plank
  db:priv_AddDB("Wood", 201778); -- Holly Plank
  db:priv_AddDB("Wood", 201775); -- Maple Plank
  db:priv_AddDB("Wood", 201776); -- Oak Plank
  db:priv_AddDB("Wood", 201777); -- Pine Plank
  db:priv_AddDB("Wood", 202612); -- Redwood Plank
  db:priv_AddDB("Wood", 202614); -- Sagewood Plank
  db:priv_AddDB("Wood", 202611); -- Stone Rotan Plank
  db:priv_AddDB("Wood", 201780); -- Tarslin Demon Wood Plank
  db:priv_AddDB("Wood", 201774); -- Willow Plank
  db:priv_AddDB("Wood", 201779); -- Yew Plank
  -- Blue
  db:priv_AddDB("Wood", 202609); -- Aeontree Lumber
  db:priv_AddDB("Wood", 201770); -- Ancient Spirit Oak Lumber
  db:priv_AddDB("Wood", 201761); -- Ash Lumber
  db:priv_AddDB("Wood", 202603); -- Chime Wood Lumber
  db:priv_AddDB("Wood", 202606); -- Dragon Beard Root Lumber
  db:priv_AddDB("Wood", 201769); -- Dragonlair Wood Lumber
  db:priv_AddDB("Wood", 202608); -- Fairywood Lumber
  db:priv_AddDB("Wood", 201766); -- Holly Lumber
  db:priv_AddDB("Wood", 201763); -- Maple Lumber
  db:priv_AddDB("Wood", 201764); -- Oak Lumber
  db:priv_AddDB("Wood", 201765); -- Pine Lumber
  db:priv_AddDB("Wood", 202605); -- Redwood Lumber
  db:priv_AddDB("Wood", 202607); -- Sagewood Lumber
  db:priv_AddDB("Wood", 202604); -- Stone Rotan Lumber
  db:priv_AddDB("Wood", 201768); -- Tarslin Demon Wood Lumber
  db:priv_AddDB("Wood", 201762); -- Willow Lumber
  db:priv_AddDB("Wood", 201767); -- Yew Lumber
  -- Green
  db:priv_AddDB("Wood", 202602); -- Aeontree Timber
  db:priv_AddDB("Wood", 201760); -- Ancient Spirit Oak Timber
  db:priv_AddDB("Wood", 201749); -- Ash Timber
  db:priv_AddDB("Wood", 202596); -- Chime Wood Timber
  db:priv_AddDB("Wood", 202599); -- Dragon Beard Root Timber
  db:priv_AddDB("Wood", 201759); -- Dragonlair Wood Timber
  db:priv_AddDB("Wood", 202601); -- Fairywood Timber
  db:priv_AddDB("Wood", 201753); -- Holly Timber
  db:priv_AddDB("Wood", 201751); -- Maple Timber
  db:priv_AddDB("Wood", 201752); -- Oak Timber
  db:priv_AddDB("Wood", 201754); -- Pine Timber
  db:priv_AddDB("Wood", 202598); -- Redwood Timber
  db:priv_AddDB("Wood", 202600); -- Sagewood Timber
  db:priv_AddDB("Wood", 202597); -- Stone Rotan Timber
  db:priv_AddDB("Wood", 201758); -- Tarslin Demon Wood Timber
  db:priv_AddDB("Wood", 201750); -- Willow Timber
  db:priv_AddDB("Wood", 201757); -- Yew Timber
  -- White
  db:priv_AddDB("Wood", 202318); -- Aeontree Wood
  db:priv_AddDB("Wood", 200312); -- Ancient Spirit Oak Wood
  db:priv_AddDB("Wood", 200293); -- Ash Wood
  db:priv_AddDB("Wood", 200508); -- Chime Wood
  db:priv_AddDB("Wood", 200332); -- Dragon Beard Root Wood
  db:priv_AddDB("Wood", 200310); -- Dragonlair Wood
  db:priv_AddDB("Wood", 202317); -- Fairywood
  db:priv_AddDB("Wood", 200298); -- Holly Wood
  db:priv_AddDB("Wood", 200297); -- Maple Wood
  db:priv_AddDB("Wood", 200300); -- Oak Wood
  db:priv_AddDB("Wood", 200304); -- Pine Wood
  db:priv_AddDB("Wood", 200326); -- Redwood
  db:priv_AddDB("Wood", 200331); -- Sagewood
  db:priv_AddDB("Wood", 200509); -- Stone Rotan Wood
  db:priv_AddDB("Wood", 200307); -- Tarslin Demon Wood
  db:priv_AddDB("Wood", 200295); -- Willow Wood
  db:priv_AddDB("Wood", 200306); -- Yew Wood
end

local function priv_AddHerbs(db)
  -- Brown
  db:priv_AddDB("Herbs", 201793); -- Barsaleaf Essence
  db:priv_AddDB("Herbs", 200367); -- Beetroot Essence
  db:priv_AddDB("Herbs", 202660); -- Bison Grass Essence
  db:priv_AddDB("Herbs", 200368); -- Bitterleaf Essence
  db:priv_AddDB("Herbs", 201810); -- Dragon Mallow Essence
  db:priv_AddDB("Herbs", 201790); -- Dusk Orchid Essence
  db:priv_AddDB("Herbs", 202661); -- Foloin Nut Essence
  db:priv_AddDB("Herbs", 202665); -- Goblin Grass Essence
  db:priv_AddDB("Herbs", 202662); -- Green Thistle Essence
  db:priv_AddDB("Herbs", 202664); -- Mirror Sedge Essence
  db:priv_AddDB("Herbs", 201795); -- Moon Orchid Essence
  db:priv_AddDB("Herbs", 200366); -- Mountain Demon Grass Essence
  db:priv_AddDB("Herbs", 201787); -- Moxa Essence
  db:priv_AddDB("Herbs", 202659); -- Rosemary Essence
  db:priv_AddDB("Herbs", 201809); -- Sinners Palm Essence
  db:priv_AddDB("Herbs", 202663); -- Straw Mushroom Essence
  db:priv_AddDB("Herbs", 201811); -- Thorn Apple Essence
  -- Orange
  db:priv_AddDB("Herbs", 200344); -- Pure Barsleaf Extract
  db:priv_AddDB("Herbs", 200337); -- Pure Beetroot Extract
  db:priv_AddDB("Herbs", 202653); -- Pure Bison Grass Extract
  db:priv_AddDB("Herbs", 200339); -- Pure Bitterleaf Extract
  db:priv_AddDB("Herbs", 200360); -- Pure Dragon Mallow Extract
  db:priv_AddDB("Herbs", 200341); -- Pure Dusk Orchid Extract
  db:priv_AddDB("Herbs", 202654); -- Pure Foloin Nut Extract
  db:priv_AddDB("Herbs", 202658); -- Pure Goblin Grass Extract
  db:priv_AddDB("Herbs", 202655); -- Pure Green Thistle Extract
  db:priv_AddDB("Herbs", 202657); -- Pure Mirror Sedge Extract
  db:priv_AddDB("Herbs", 200355); -- Pure Moon Orchid Extract
  db:priv_AddDB("Herbs", 200336); -- Pure Mountain Demon Grass Extract
  db:priv_AddDB("Herbs", 200340); -- Pure Moxa Extract
  db:priv_AddDB("Herbs", 202652); -- Pure Rosemary Extract
  db:priv_AddDB("Herbs", 200356); -- Pure Sinners Palm Extract
  db:priv_AddDB("Herbs", 202656); -- Pure Straw Mushroom Extract
  db:priv_AddDB("Herbs", 200364); -- Pure Thorn Apple Extract
  -- Purple
  db:priv_AddDB("Herbs", 201818); -- Barsleaf Extract
  db:priv_AddDB("Herbs", 201814); -- Beetroot Extract
  db:priv_AddDB("Herbs", 202646); -- Bison Grass Extract
  db:priv_AddDB("Herbs", 201815); -- Bitterleaf Extract
  db:priv_AddDB("Herbs", 201821); -- Dragon Mallow Extract
  db:priv_AddDB("Herbs", 201817); -- Dusk Orchid Extract
  db:priv_AddDB("Herbs", 202647); -- Foloin Nut Extract
  db:priv_AddDB("Herbs", 202651); -- Goblin Grass Extract
  db:priv_AddDB("Herbs", 202648); -- Green Thistle Extract
  db:priv_AddDB("Herbs", 202650); -- Mirror Sedge Extract
  db:priv_AddDB("Herbs", 201819); -- Moon Orchid Extract
  db:priv_AddDB("Herbs", 201813); -- Mountain Demon Grass Extract
  db:priv_AddDB("Herbs", 201816); -- Moxa Extract
  db:priv_AddDB("Herbs", 202645); -- Rosemary Extract
  db:priv_AddDB("Herbs", 201820); -- Sinners Palm Extract
  db:priv_AddDB("Herbs", 202649); -- Straw Mushroom Extract
  db:priv_AddDB("Herbs", 201822); -- Thorn Apple Extract
  -- Blue
  db:priv_AddDB("Herbs", 201804); -- Barsleaf Sap
  db:priv_AddDB("Herbs", 201800); -- Beetroot Sap
  db:priv_AddDB("Herbs", 202639); -- Bison Grass Sap
  db:priv_AddDB("Herbs", 201801); -- Bitterleaf Sap
  db:priv_AddDB("Herbs", 201807); -- Dragon Mallow Sap
  db:priv_AddDB("Herbs", 201803); -- Dusk Orchid Sap
  db:priv_AddDB("Herbs", 202640); -- Foloin Nut Sap
  db:priv_AddDB("Herbs", 202644); -- Goblin Grass Sap
  db:priv_AddDB("Herbs", 202641); -- Green Thistle Sap
  db:priv_AddDB("Herbs", 202643); -- Mirror Sedge Sap
  db:priv_AddDB("Herbs", 201805); -- Moon Orchid Sap
  db:priv_AddDB("Herbs", 201799); -- Mountain Demon Grass Sap
  db:priv_AddDB("Herbs", 201802); -- Moxa Sap
  db:priv_AddDB("Herbs", 202638); -- Rosemary Sap
  db:priv_AddDB("Herbs", 201806); -- Sinners Palm Sap
  db:priv_AddDB("Herbs", 202642); -- Straw Mushroom Sap
  db:priv_AddDB("Herbs", 201808); -- Thorn Apple Juice
  -- Green
  db:priv_AddDB("Herbs", 201792); -- Barsleaf Bundle
  db:priv_AddDB("Herbs", 201786); -- Beetroot Bundle
  db:priv_AddDB("Herbs", 202632); -- Bison Grass Bundle
  db:priv_AddDB("Herbs", 201789); -- Bitterleaf Bundle
  db:priv_AddDB("Herbs", 201797); -- Dragon Mallow Bundle
  db:priv_AddDB("Herbs", 201791); -- Dusk Orchid Bundle
  db:priv_AddDB("Herbs", 202633); -- Foloin Nut Bundle
  db:priv_AddDB("Herbs", 202637); -- Goblin Grass Bundle
  db:priv_AddDB("Herbs", 202634); -- Green Thistle Bundle
  db:priv_AddDB("Herbs", 202636); -- Mirror Sedge Bundle
  db:priv_AddDB("Herbs", 201794); -- Moon Orchid Bundle
  db:priv_AddDB("Herbs", 201785); -- Mountain Demon Grass Bundle
  db:priv_AddDB("Herbs", 201788); -- Moxa Bundle
  db:priv_AddDB("Herbs", 202631); -- Rosemary Bundle
  db:priv_AddDB("Herbs", 201796); -- Sinners Palm Bundle
  db:priv_AddDB("Herbs", 202635); -- Straw Mushroom Bundle
  db:priv_AddDB("Herbs", 201798); -- Thorn Apple Bundle
  -- White
  db:priv_AddDB("Herbs", 200342); -- Barsleaf
  db:priv_AddDB("Herbs", 200334); -- Beetroot
  db:priv_AddDB("Herbs", 202553); -- Bison Grass
  db:priv_AddDB("Herbs", 200333); -- Bitterleaf
  db:priv_AddDB("Herbs", 200349); -- Dragon Mallow
  db:priv_AddDB("Herbs", 200343); -- Dusk Orchid
  db:priv_AddDB("Herbs", 202554); -- Foloin Nut
  db:priv_AddDB("Herbs", 202558); -- Goblin Grass
  db:priv_AddDB("Herbs", 202555); -- Green Thistle
  db:priv_AddDB("Herbs", 202557); -- Mirror Sedge
  db:priv_AddDB("Herbs", 200345); -- Moon Orchid
  db:priv_AddDB("Herbs", 200335); -- Mountain Demon Grass
  db:priv_AddDB("Herbs", 200338); -- Moxa
  db:priv_AddDB("Herbs", 202552); -- Rosemary
  db:priv_AddDB("Herbs", 200346); -- Sinners Palm
  db:priv_AddDB("Herbs", 202556); -- Straw Mushroom
  db:priv_AddDB("Herbs", 200350); -- Thorn Apple
end

local function priv_AddRawMaterials(db)
  -- Orange
  db:priv_AddDB("RawMaterials", 205829); -- Feyenloth's Growth
  db:priv_AddDB("RawMaterials", 205831); -- Feyenloth's Rage
  db:priv_AddDB("RawMaterials", 205828); -- Feyenloth's Rest
  db:priv_AddDB("RawMaterials", 205830); -- Feyenloth's Return
  db:priv_AddDB("RawMaterials", 205827); -- Feyenloth's Tranquility
  db:priv_AddDB("RawMaterials", 205832); -- Strange Magical Leaf
  -- Purple
  db:priv_AddDB("RawMaterials", 205729); -- Feyenloth's Fear
  db:priv_AddDB("RawMaterials", 205823); -- Payer of Life
  db:priv_AddDB("RawMaterials", 205826); -- Prayer of Protection
  db:priv_AddDB("RawMaterials", 205822); -- Prayer of Repletion
  db:priv_AddDB("RawMaterials", 205811); -- Prayer of Resting
  db:priv_AddDB("RawMaterials", 205825); -- Prayer of Struggle
  db:priv_AddDB("RawMaterials", 205824); -- Prayer of Weaving
  db:priv_AddDB("RawMaterials", 203018); -- Rune Crystal
  -- Blue
  db:priv_AddDB("RawMaterials", 202125); -- Aloeswood Fiber
  db:priv_AddDB("RawMaterials", 202117); -- Alpha Metal Stone
  db:priv_AddDB("RawMaterials", 202112); -- Aluminum Nail
  db:priv_AddDB("RawMaterials", 202132); -- Amber Fiber
  db:priv_AddDB("RawMaterials", 202128); -- Balloonflower Fiber
  db:priv_AddDB("RawMaterials", 202118); -- Beta Metal Stone
  db:priv_AddDB("RawMaterials", 202126); -- Calamus Fiber
  db:priv_AddDB("RawMaterials", 202129); -- Chestnut Fiber
  db:priv_AddDB("RawMaterials", 202110); -- Copper Nail
  db:priv_AddDB("RawMaterials", 202986); -- Crushed Purple Jade
  db:priv_AddDB("RawMaterials", 202120); -- Delta Metal Stone
  db:priv_AddDB("RawMaterials", 203017); -- Elemental Crystal
  db:priv_AddDB("RawMaterials", 202121); -- Epsilon Metal Stone
  db:priv_AddDB("RawMaterials", 202123); -- Eta Metal Stone
  db:priv_AddDB("RawMaterials", 205728); -- Feyenloth's Broken Soul
  db:priv_AddDB("RawMaterials", 202988); -- Flame Crystal Sand
  db:priv_AddDB("RawMaterials", 202119); -- Gamma Metal Stone
  db:priv_AddDB("RawMaterials", 203014); -- Gem From Hammertooth Mask
  db:priv_AddDB("RawMaterials", 202987); -- Gloomy Crystal Sand
  db:priv_AddDB("RawMaterials", 202116); -- Gold Nail
  db:priv_AddDB("RawMaterials", 202111); -- Iron Nail
  db:priv_AddDB("RawMaterials", 203013); -- Kobold Crown Fragment
  db:priv_AddDB("RawMaterials", 202131); -- Lapis Lazuli Fiber
  db:priv_AddDB("RawMaterials", 202130); -- Pine Fiber
  db:priv_AddDB("RawMaterials", 202115); -- Platinum Nail
  db:priv_AddDB("RawMaterials", 202990); -- Refined Fire Essence Nugget
  db:priv_AddDB("RawMaterials", 202991); -- Refined Water Essence Nugget
  db:priv_AddDB("RawMaterials", 202989); -- Sharp Gravel
  db:priv_AddDB("RawMaterials", 202114); -- Silver Nail
  db:priv_AddDB("RawMaterials", 202984); -- Smashed Fire Essence Fragment
  db:priv_AddDB("RawMaterials", 202985); -- Smashed Water Essence Fragment
  db:priv_AddDB("RawMaterials", 202113); -- Steel Nail
  db:priv_AddDB("RawMaterials", 202104); -- Stone of Fire Planet
  db:priv_AddDB("RawMaterials", 202105); -- Stone of the Earth Planet
  db:priv_AddDB("RawMaterials", 202101); -- Stone of the Golden Planet
  db:priv_AddDB("RawMaterials", 202107); -- Stone of the Planet of the Heavnly King
  db:priv_AddDB("RawMaterials", 202108); -- Stone of the Planet of the King of Darkness
  db:priv_AddDB("RawMaterials", 202102); -- Stone of the Tree Planet
  db:priv_AddDB("RawMaterials", 202106); -- Stone of the Water King Planet
  db:priv_AddDB("RawMaterials", 202103); -- Stone of the Water Planet
  db:priv_AddDB("RawMaterials", 202992); -- Tempered Fire Essence Nugget
  db:priv_AddDB("RawMaterials", 202993); -- Tempered Water Essence Nugget
  db:priv_AddDB("RawMaterials", 202124); -- Thet Metal Stone
  db:priv_AddDB("RawMaterials", 202127); -- Tulipwood Fiber
  db:priv_AddDB("RawMaterials", 202109); -- Wooden Nail
  db:priv_AddDB("RawMaterials", 202122); -- Zeta Metal Stone
  -- Green
  db:priv_AddDB("RawMaterials", 203015); -- Assassin's Sword Hilt
  db:priv_AddDB("RawMaterials", 203011); -- Broken Goblin Staff
  db:priv_AddDB("RawMaterials", 203008); -- Crimson Hog Hide
  db:priv_AddDB("RawMaterials", 203012); -- Damaged Fine Repeating Crossbow
  db:priv_AddDB("RawMaterials", 203009); -- Damaged Kobold Battle Axe
  db:priv_AddDB("RawMaterials", 203016); -- Gomio's Rucksack
  db:priv_AddDB("RawMaterials", 203005); -- Low Magic Element
  db:priv_AddDB("RawMaterials", 203007); -- Low Rune Power
  db:priv_AddDB("RawMaterials", 203019); -- Medium Magic Element
  db:priv_AddDB("RawMaterials", 203020); -- Medium Rune Power
  db:priv_AddDB("RawMaterials", 202994); -- Very Low Magic Element
  db:priv_AddDB("RawMaterials", 203006); -- Very Low Rune Power
  db:priv_AddDB("RawMaterials", 203010); -- Worn Kobold Robe
  -- White
  db:priv_AddDB("RawMaterials", 201952); -- Alchemy Bottle
  db:priv_AddDB("RawMaterials", 203419); -- Animal Meat
  db:priv_AddDB("RawMaterials", 200473); -- Apple
  db:priv_AddDB("RawMaterials", 200534); -- Arapaima
  db:priv_AddDB("RawMaterials", 200532); -- Bass
  db:priv_AddDB("RawMaterials", 201951); -- Beaker
  db:priv_AddDB("RawMaterials", 200766); -- Bird Meat
  db:priv_AddDB("RawMaterials", 200530); -- Blue Trout
  db:priv_AddDB("RawMaterials", 200491); -- Celery
  db:priv_AddDB("RawMaterials", 203425); -- Cocoa
  db:priv_AddDB("RawMaterials", 200782); -- Cream
  db:priv_AddDB("RawMaterials", 200767); -- Delicious Worm Meat
  db:priv_AddDB("RawMaterials", 203421); -- Flour
  db:priv_AddDB("RawMaterials", 203418); -- Frog Meat
  db:priv_AddDB("RawMaterials", 203426); -- Garlic
  db:priv_AddDB("RawMaterials", 203423); -- Golden Flour
  db:priv_AddDB("RawMaterials", 200479); -- Grape
  db:priv_AddDB("RawMaterials", 201539); -- Green-spotted Fungus Bread
  db:priv_AddDB("RawMaterials", 203422); -- High Quality Flour
  db:priv_AddDB("RawMaterials", 201540); -- Highlands Demon Weed Seed
  db:priv_AddDB("RawMaterials", 200489); -- Lettuce
  db:priv_AddDB("RawMaterials", 203395); -- Magic Bottle
  db:priv_AddDB("RawMaterials", 203427); -- Mushroom
  db:priv_AddDB("RawMaterials", 201534); -- Newborn Boar Tusk
  db:priv_AddDB("RawMaterials", 203428); -- Oriental Tea Leaves
  db:priv_AddDB("RawMaterials", 201953); -- Philosopher's Egg
  db:priv_AddDB("RawMaterials", 200480); -- Pineapple
  db:priv_AddDB("RawMaterials", 203420); -- Rare Animal Meat
  db:priv_AddDB("RawMaterials", 200529); -- Salmon
  db:priv_AddDB("RawMaterials", 201950); -- Small Empty Bottle
  db:priv_AddDB("RawMaterials", 200528); -- Small Fish
  db:priv_AddDB("RawMaterials", 201537); -- Snow Frog Placenta
  db:priv_AddDB("RawMaterials", 200543); -- Spiny Lobster
  db:priv_AddDB("RawMaterials", 201536); -- Wandering Ent Bud
  db:priv_AddDB("RawMaterials", 203424); -- Witchcraft Sugar
  db:priv_AddDB("RawMaterials", 201538); -- Young Ostrich's Egg
end

local function priv_AddProductionRunes(db)
  -- Purple
  db:priv_AddDB("ProductionRunes", 201086); -- Advanced Skill Reset Stone
  db:priv_AddDB("ProductionRunes", 202088); -- Bag of Activate-Runes
  db:priv_AddDB("ProductionRunes", 202091); -- Bag of Blend-Runes
  db:priv_AddDB("ProductionRunes", 202089); -- Bag of Disenchant-Runes
  db:priv_AddDB("ProductionRunes", 202087); -- Bag of Frost-Runes
  db:priv_AddDB("ProductionRunes", 202086); -- Bag of Link-Runes
  db:priv_AddDB("ProductionRunes", 202090); -- Bag of Purify-Runes
  db:priv_AddDB("ProductionRunes", 201971); -- Basic Skill Reset Stone
  db:priv_AddDB("ProductionRunes", 203035); -- Skill Reset Rune
  -- White
  db:priv_AddDB("ProductionRunes", 200852); -- Activate Rune
  db:priv_AddDB("ProductionRunes", 200855); -- Blend Rune
  db:priv_AddDB("ProductionRunes", 200856); -- Day & Night Rune
  db:priv_AddDB("ProductionRunes", 200853); -- Disenchant Rune
  db:priv_AddDB("ProductionRunes", 200851); -- Frost Rune
  db:priv_AddDB("ProductionRunes", 200850); -- Link Rune
  db:priv_AddDB("ProductionRunes", 200854); -- Purify Rune
  db:priv_AddDB("ProductionRunes", 200857); -- Season Rune
  db:priv_AddDB("ProductionRunes", 200858); -- Years Rune
end

-- Equipment Enchancements
local function priv_AddJewels(db)
  -- Purple
  db:priv_AddDB("Jewels", 201097); -- Moon Jewel - Blessing
  db:priv_AddDB("Jewels", 201459); -- Moon Jewel - Holy Light
  db:priv_AddDB("Jewels", 201449); -- Moon Jewel - Protection
  db:priv_AddDB("Jewels", 201457); -- Moon Jewel - Wishes
  db:priv_AddDB("Jewels", 203045); -- Perfect Moon Jewel - Blessing
  db:priv_AddDB("Jewels", 203056); -- Perfect Moon Jewel - Holy Light
  db:priv_AddDB("Jewels", 203048); -- Perfect Moon Jewel - Protection
  db:priv_AddDB("Jewels", 203051); -- Perfect Moon Jewel - Wishes
  db:priv_AddDB("Jewels", 203044); -- Perfect Star Jewel - Blessing
  db:priv_AddDB("Jewels", 203055); -- Perfect Star Jewel - Holy Light
  db:priv_AddDB("Jewels", 203047); -- Perfect Star Jewel - Protection
  db:priv_AddDB("Jewels", 203050); -- Perfect Star Jewel - Wishes
  db:priv_AddDB("Jewels", 203046); -- Perfect Sun Jewel - Blessing
  db:priv_AddDB("Jewels", 203057); -- Perfect Sun Jewel - Holy Light
  db:priv_AddDB("Jewels", 203049); -- Perfect Sun Jewel - Protection
  db:priv_AddDB("Jewels", 203052); -- Perfect Sun Jewel - Wishes
  db:priv_AddDB("Jewels", 201095); -- Star Jewel - Blessing
  db:priv_AddDB("Jewels", 201458); -- Star Jewel - Holy Light
  db:priv_AddDB("Jewels", 201448); -- Star Jewel - Protection
  db:priv_AddDB("Jewels", 201450); -- Star Jewel - Wishes
  db:priv_AddDB("Jewels", 203040); -- Sun Jewel - Blessing
  db:priv_AddDB("Jewels", 203043); -- Sun Jewel - Holy Light
  db:priv_AddDB("Jewels", 203041); -- Sun Jewel - Protection
  db:priv_AddDB("Jewels", 203042); -- Sun Jewel - Wishes
  -- Green
  db:priv_AddDB("Jewels", 201201); -- Moon Jewel - Basic
  db:priv_AddDB("Jewels", 201202); -- Moon Jewel - Class I
  db:priv_AddDB("Jewels", 201203); -- Moon Jewel - Class II
  db:priv_AddDB("Jewels", 201204); -- Moon Jewel - Class III
  db:priv_AddDB("Jewels", 201442); -- Moon Jewel - Level 1
  db:priv_AddDB("Jewels", 201443); -- Moon Jewel - Level 2
  db:priv_AddDB("Jewels", 201485); -- Moon Jewel - Level 3
  db:priv_AddDB("Jewels", 200840); -- Star Jewel - Basic
  db:priv_AddDB("Jewels", 200841); -- Star Jewel - Class I
  db:priv_AddDB("Jewels", 200842); -- Star Jewel - Class II
  db:priv_AddDB("Jewels", 200843); -- Star Jewel - Class III
  db:priv_AddDB("Jewels", 200217); -- Star Jewel - Level 1
  db:priv_AddDB("Jewels", 200218); -- Star Jewel - Level 2
  db:priv_AddDB("Jewels", 200219); -- Star Jewel - Level 3
  db:priv_AddDB("Jewels", 203594); -- Sun Jewel - Basic
  db:priv_AddDB("Jewels", 203595); -- Sun Jewel - Class I
  db:priv_AddDB("Jewels", 203596); -- Sun Jewel - Class II
  db:priv_AddDB("Jewels", 203597); -- Sun Jewel - Class III
  db:priv_AddDB("Jewels", 201486); -- Sun Jewel - Level 1
  db:priv_AddDB("Jewels", 201487); -- Sun Jewel - Level 2
  db:priv_AddDB("Jewels", 201699); -- Sun Jewel - Level 3
end;

local function priv_AddRunes(db)
  -- Advance
  db:priv_AddDB("Runes", 520581); -- Advance I
  db:priv_AddDB("Runes", 520582); -- Advance II
  db:priv_AddDB("Runes", 520583); -- Advance III
  db:priv_AddDB("Runes", 520584); -- Advance IV
  db:priv_AddDB("Runes", 520585); -- Advance V
  db:priv_AddDB("Runes", 520586); -- Advance VI
  db:priv_AddDB("Runes", 520587); -- Advance VII
  db:priv_AddDB("Runes", 520588); -- Advance VIII
  db:priv_AddDB("Runes", 520589); -- Advance IX
  db:priv_AddDB("Runes", 520590); -- Advance X
  
  -- Aggression
  db:priv_AddDB("Runes", 520561); -- Aggression I
  db:priv_AddDB("Runes", 520562); -- Aggression II
  db:priv_AddDB("Runes", 520563); -- Aggression III
  db:priv_AddDB("Runes", 520564); -- Aggression IV
  db:priv_AddDB("Runes", 520565); -- Aggression V
  db:priv_AddDB("Runes", 520566); -- Aggression VI
  db:priv_AddDB("Runes", 520567); -- Aggression VII
  db:priv_AddDB("Runes", 520568); -- Aggression VIII
  db:priv_AddDB("Runes", 520569); -- Aggression IX
  db:priv_AddDB("Runes", 520570); -- Aggression X
  
  -- Agile
  db:priv_AddDB("Runes", 520521); -- Agile I
  db:priv_AddDB("Runes", 520522); -- Agile II
  db:priv_AddDB("Runes", 520523); -- Agile III
  db:priv_AddDB("Runes", 520524); -- Agile IV
  db:priv_AddDB("Runes", 520525); -- Agile V
  db:priv_AddDB("Runes", 520526); -- Agile VI
  db:priv_AddDB("Runes", 520527); -- Agile VII
  db:priv_AddDB("Runes", 520528); -- Agile VIII
  db:priv_AddDB("Runes", 520529); -- Agile IX
  db:priv_AddDB("Runes", 520530); -- Agile X
  
  -- Anger
  db:priv_AddDB("Runes", 520361); -- Anger I
  db:priv_AddDB("Runes", 520362); -- Anger II
  db:priv_AddDB("Runes", 520363); -- Anger III
  db:priv_AddDB("Runes", 520364); -- Anger IV
  db:priv_AddDB("Runes", 520365); -- Anger V
  db:priv_AddDB("Runes", 520366); -- Anger VI
  db:priv_AddDB("Runes", 520367); -- Anger VII
  db:priv_AddDB("Runes", 520368); -- Anger VIII
  db:priv_AddDB("Runes", 520369); -- Anger IX
  db:priv_AddDB("Runes", 520370); -- Anger X
  
  -- Atonement
  db:priv_AddDB("Runes", 520241); -- Atonement I
  db:priv_AddDB("Runes", 520242); -- Atonement II
  db:priv_AddDB("Runes", 520243); -- Atonement III
  db:priv_AddDB("Runes", 520244); -- Atonement IV
  db:priv_AddDB("Runes", 520245); -- Atonement V
  db:priv_AddDB("Runes", 520246); -- Atonement VI
  db:priv_AddDB("Runes", 520247); -- Atonement VII
  db:priv_AddDB("Runes", 520248); -- Atonement VIII
  db:priv_AddDB("Runes", 520249); -- Atonement IX
  db:priv_AddDB("Runes", 520250); -- Atonement X
  
  -- Barrier
  db:priv_AddDB("Runes", 520381); -- Barrier I
  db:priv_AddDB("Runes", 520382); -- Barrier II
  db:priv_AddDB("Runes", 520383); -- Barrier III
  db:priv_AddDB("Runes", 520384); -- Barrier IV
  db:priv_AddDB("Runes", 520385); -- Barrier V
  db:priv_AddDB("Runes", 520386); -- Barrier VI
  db:priv_AddDB("Runes", 520387); -- Barrier VII
  db:priv_AddDB("Runes", 520388); -- Barrier VIII
  db:priv_AddDB("Runes", 520389); -- Barrier IX
  db:priv_AddDB("Runes", 520390); -- Barrier X
  
  -- Burst
  db:priv_AddDB("Runes", 520781); -- Burst I
  db:priv_AddDB("Runes", 520782); -- Burst II
  db:priv_AddDB("Runes", 520783); -- Burst III
  db:priv_AddDB("Runes", 520784); -- Burst IV
  db:priv_AddDB("Runes", 520785); -- Burst V
  db:priv_AddDB("Runes", 520786); -- Burst VI
  db:priv_AddDB("Runes", 520787); -- Burst VII
  db:priv_AddDB("Runes", 520788); -- Burst VIII
  db:priv_AddDB("Runes", 520789); -- Burst IX
  db:priv_AddDB("Runes", 520790); -- Burst X
  
  -- Defense
  db:priv_AddDB("Runes", 520201); -- Defense I
  db:priv_AddDB("Runes", 520202); -- Defense II
  db:priv_AddDB("Runes", 520203); -- Defense III
  db:priv_AddDB("Runes", 520204); -- Defense IV
  db:priv_AddDB("Runes", 520205); -- Defense V
  db:priv_AddDB("Runes", 520206); -- Defense VI
  db:priv_AddDB("Runes", 520207); -- Defense VII
  db:priv_AddDB("Runes", 520208); -- Defense VIII
  db:priv_AddDB("Runes", 520209); -- Defense IX
  db:priv_AddDB("Runes", 520210); -- Defense X
  
  -- Endurance
  db:priv_AddDB("Runes", 520121); -- Endurance I
  db:priv_AddDB("Runes", 520122); -- Endurance II
  db:priv_AddDB("Runes", 520123); -- Endurance III
  db:priv_AddDB("Runes", 520124); -- Endurance IV
  db:priv_AddDB("Runes", 520125); -- Endurance V
  db:priv_AddDB("Runes", 520126); -- Endurance VI
  db:priv_AddDB("Runes", 520127); -- Endurance VII
  db:priv_AddDB("Runes", 520128); -- Endurance VIII
  db:priv_AddDB("Runes", 520129); -- Endurance IX
  db:priv_AddDB("Runes", 520130); -- Endurance X
  
  -- Excite
  db:priv_AddDB("Runes", 520281); -- Excite I
  db:priv_AddDB("Runes", 520282); -- Excite II
  db:priv_AddDB("Runes", 520283); -- Excite III
  db:priv_AddDB("Runes", 520284); -- Excite IV
  db:priv_AddDB("Runes", 520285); -- Excite V
  db:priv_AddDB("Runes", 520286); -- Excite VI
  db:priv_AddDB("Runes", 520287); -- Excite VII
  db:priv_AddDB("Runes", 520288); -- Excite VIII
  db:priv_AddDB("Runes", 520289); -- Excite IX
  db:priv_AddDB("Runes", 520290); -- Excite X
  
  -- Experience
  db:priv_AddDB("Runes", 520741); -- Experience I
  db:priv_AddDB("Runes", 520742); -- Experience II
  db:priv_AddDB("Runes", 520743); -- Experience III
  db:priv_AddDB("Runes", 520744); -- Experience IV
  db:priv_AddDB("Runes", 520745); -- Experience V
  db:priv_AddDB("Runes", 520746); -- Experience VI
  db:priv_AddDB("Runes", 520747); -- Experience VII
  db:priv_AddDB("Runes", 520748); -- Experience VIII
  db:priv_AddDB("Runes", 520749); -- Experience IX
  db:priv_AddDB("Runes", 520750); -- Experience X
  
  -- Fatal
  db:priv_AddDB("Runes", 520761); -- Fatal I
  db:priv_AddDB("Runes", 520762); -- Fatal II
  db:priv_AddDB("Runes", 520763); -- Fatal III
  db:priv_AddDB("Runes", 520764); -- Fatal IV
  db:priv_AddDB("Runes", 520765); -- Fatal V
  db:priv_AddDB("Runes", 520766); -- Fatal VI
  db:priv_AddDB("Runes", 520767); -- Fatal VII
  db:priv_AddDB("Runes", 520768); -- Fatal VIII
  db:priv_AddDB("Runes", 520769); -- Fatal IX
  db:priv_AddDB("Runes", 520770); -- Fatal X
  
  -- Fearless
  db:priv_AddDB("Runes", 520481); -- Fearless I
  db:priv_AddDB("Runes", 520482); -- Fearless II
  db:priv_AddDB("Runes", 520483); -- Fearless III
  db:priv_AddDB("Runes", 520484); -- Fearless IV
  db:priv_AddDB("Runes", 520485); -- Fearless V
  db:priv_AddDB("Runes", 520486); -- Fearless VI
  db:priv_AddDB("Runes", 520487); -- Fearless VII
  db:priv_AddDB("Runes", 520488); -- Fearless VIII
  db:priv_AddDB("Runes", 520489); -- Fearless IX
  db:priv_AddDB("Runes", 520490); -- Fearless X
  
  -- Fountain
  db:priv_AddDB("Runes", 520461); -- Fountain I
  db:priv_AddDB("Runes", 520462); -- Fountain II
  db:priv_AddDB("Runes", 520463); -- Fountain III
  db:priv_AddDB("Runes", 520464); -- Fountain IV
  db:priv_AddDB("Runes", 520465); -- Fountain V
  db:priv_AddDB("Runes", 520466); -- Fountain VI
  db:priv_AddDB("Runes", 520467); -- Fountain VII
  db:priv_AddDB("Runes", 520468); -- Fountain VIII
  db:priv_AddDB("Runes", 520469); -- Fountain IX
  db:priv_AddDB("Runes", 520470); -- Fountain X
  
  -- Guts
  db:priv_AddDB("Runes", 520301); -- Guts I
  db:priv_AddDB("Runes", 520302); -- Guts II
  db:priv_AddDB("Runes", 520303); -- Guts III
  db:priv_AddDB("Runes", 520304); -- Guts IV
  db:priv_AddDB("Runes", 520305); -- Guts V
  db:priv_AddDB("Runes", 520306); -- Guts VI
  db:priv_AddDB("Runes", 520307); -- Guts VII
  db:priv_AddDB("Runes", 520308); -- Guts VIII
  db:priv_AddDB("Runes", 520309); -- Guts IX
  db:priv_AddDB("Runes", 520310); -- Guts X
  
  -- Harm
  db:priv_AddDB("Runes", 520161); -- Harm I
  db:priv_AddDB("Runes", 520162); -- Harm II
  db:priv_AddDB("Runes", 520163); -- Harm III
  db:priv_AddDB("Runes", 520164); -- Harm IV
  db:priv_AddDB("Runes", 520165); -- Harm V
  db:priv_AddDB("Runes", 520166); -- Harm VI
  db:priv_AddDB("Runes", 520167); -- Harm VII
  db:priv_AddDB("Runes", 520168); -- Harm VIII
  db:priv_AddDB("Runes", 520169); -- Harm IX
  db:priv_AddDB("Runes", 520170); -- Harm X
  
  -- Hatred
  db:priv_AddDB("Runes", 520681); -- Hatred I
  db:priv_AddDB("Runes", 520682); -- Hatred II
  db:priv_AddDB("Runes", 520683); -- Hatred III
  db:priv_AddDB("Runes", 520684); -- Hatred IV
  db:priv_AddDB("Runes", 520685); -- Hatred V
  db:priv_AddDB("Runes", 520686); -- Hatred VI
  db:priv_AddDB("Runes", 520687); -- Hatred VII
  db:priv_AddDB("Runes", 520688); -- Hatred VIII
  db:priv_AddDB("Runes", 520689); -- Hatred IX
  db:priv_AddDB("Runes", 520690); -- Hatred X
  
  -- Loot
  db:priv_AddDB("Runes", 520721); -- Loot I
  db:priv_AddDB("Runes", 520722); -- Loot II
  db:priv_AddDB("Runes", 520723); -- Loot III
  db:priv_AddDB("Runes", 520724); -- Loot IV
  db:priv_AddDB("Runes", 520725); -- Loot V
  db:priv_AddDB("Runes", 520726); -- Loot VI
  db:priv_AddDB("Runes", 520727); -- Loot VII
  db:priv_AddDB("Runes", 520728); -- Loot VIII
  db:priv_AddDB("Runes", 520729); -- Loot IX
  db:priv_AddDB("Runes", 520730); -- Loot X
  
  -- Magic
  db:priv_AddDB("Runes", 520141); -- Magic I
  db:priv_AddDB("Runes", 520142); -- Magic II
  db:priv_AddDB("Runes", 520143); -- Magic III
  db:priv_AddDB("Runes", 520144); -- Magic IV
  db:priv_AddDB("Runes", 520145); -- Magic V
  db:priv_AddDB("Runes", 520146); -- Magic VI
  db:priv_AddDB("Runes", 520147); -- Magic VII
  db:priv_AddDB("Runes", 520148); -- Magic VIII
  db:priv_AddDB("Runes", 520149); -- Magic IX
  db:priv_AddDB("Runes", 520150); -- Magic X
  
  -- Mayhem
  db:priv_AddDB("Runes", 520421); -- Mayhem I
  db:priv_AddDB("Runes", 520422); -- Mayhem II
  db:priv_AddDB("Runes", 520423); -- Mayhem III
  db:priv_AddDB("Runes", 520424); -- Mayhem IV
  db:priv_AddDB("Runes", 520425); -- Mayhem V
  db:priv_AddDB("Runes", 520426); -- Mayhem VI
  db:priv_AddDB("Runes", 520427); -- Mayhem VII
  db:priv_AddDB("Runes", 520428); -- Mayhem VIII
  db:priv_AddDB("Runes", 520429); -- Mayhem IX
  db:priv_AddDB("Runes", 520430); -- Mayhem X
  
  -- Might
  db:priv_AddDB("Runes", 520501); -- Might I
  db:priv_AddDB("Runes", 520502); -- Might II
  db:priv_AddDB("Runes", 520503); -- Might III
  db:priv_AddDB("Runes", 520504); -- Might IV
  db:priv_AddDB("Runes", 520505); -- Might V
  db:priv_AddDB("Runes", 520506); -- Might VI
  db:priv_AddDB("Runes", 520507); -- Might VII
  db:priv_AddDB("Runes", 520508); -- Might VIII
  db:priv_AddDB("Runes", 520509); -- Might IX
  db:priv_AddDB("Runes", 520510); -- Might X
  
  -- Mind
  db:priv_AddDB("Runes", 520061); -- Mind I
  db:priv_AddDB("Runes", 520062); -- Mind II
  db:priv_AddDB("Runes", 520063); -- Mind III
  db:priv_AddDB("Runes", 520064); -- Mind IV
  db:priv_AddDB("Runes", 520065); -- Mind V
  db:priv_AddDB("Runes", 520066); -- Mind VI
  db:priv_AddDB("Runes", 520067); -- Mind VII
  db:priv_AddDB("Runes", 520068); -- Mind VIII
  db:priv_AddDB("Runes", 520069); -- Mind IX
  db:priv_AddDB("Runes", 520070); -- Mind X
  
  -- Miracle
  db:priv_AddDB("Runes", 520821); -- Miracle I
  db:priv_AddDB("Runes", 520822); -- Miracle II
  db:priv_AddDB("Runes", 520823); -- Miracle III
  db:priv_AddDB("Runes", 520824); -- Miracle IV
  db:priv_AddDB("Runes", 520825); -- Miracle V
  db:priv_AddDB("Runes", 520826); -- Miracle VI
  db:priv_AddDB("Runes", 520827); -- Miracle VII
  db:priv_AddDB("Runes", 520828); -- Miracle VIII
  db:priv_AddDB("Runes", 520829); -- Miracle IX
  db:priv_AddDB("Runes", 520830); -- Miracle X
  
  -- Passion
  db:priv_AddDB("Runes", 520441); -- Passion I
  db:priv_AddDB("Runes", 520442); -- Passion II
  db:priv_AddDB("Runes", 520443); -- Passion III
  db:priv_AddDB("Runes", 520444); -- Passion IV
  db:priv_AddDB("Runes", 520445); -- Passion V
  db:priv_AddDB("Runes", 520446); -- Passion VI
  db:priv_AddDB("Runes", 520447); -- Passion VII
  db:priv_AddDB("Runes", 520448); -- Passion VIII
  db:priv_AddDB("Runes", 520449); -- Passion IX
  db:priv_AddDB("Runes", 520450); -- Passion X
  
  -- Payback
  db:priv_AddDB("Runes", 520261); -- Payback I
  db:priv_AddDB("Runes", 520262); -- Payback II
  db:priv_AddDB("Runes", 520263); -- Payback III
  db:priv_AddDB("Runes", 520264); -- Payback IV
  db:priv_AddDB("Runes", 520265); -- Payback V
  db:priv_AddDB("Runes", 520266); -- Payback VI
  db:priv_AddDB("Runes", 520267); -- Payback VII
  db:priv_AddDB("Runes", 520268); -- Payback VIII
  db:priv_AddDB("Runes", 520269); -- Payback IX
  db:priv_AddDB("Runes", 520270); -- Payback X
  
  -- Potential
  db:priv_AddDB("Runes", 520661); -- Potential I
  db:priv_AddDB("Runes", 520662); -- Potential II
  db:priv_AddDB("Runes", 520663); -- Potential III
  db:priv_AddDB("Runes", 520664); -- Potential IV
  db:priv_AddDB("Runes", 520665); -- Potential V
  db:priv_AddDB("Runes", 520666); -- Potential VI
  db:priv_AddDB("Runes", 520667); -- Potential VII
  db:priv_AddDB("Runes", 520668); -- Potential VIII
  db:priv_AddDB("Runes", 520669); -- Potential IX
  db:priv_AddDB("Runes", 520670); -- Potential X
  
  -- Power
  db:priv_AddDB("Runes", 520021); -- Power I
  db:priv_AddDB("Runes", 520022); -- Power II
  db:priv_AddDB("Runes", 520023); -- Power III
  db:priv_AddDB("Runes", 520024); -- Power IV
  db:priv_AddDB("Runes", 520025); -- Power V
  db:priv_AddDB("Runes", 520026); -- Power VI
  db:priv_AddDB("Runes", 520027); -- Power VII
  db:priv_AddDB("Runes", 520028); -- Power VIII
  db:priv_AddDB("Runes", 520029); -- Power IX
  db:priv_AddDB("Runes", 520030); -- Power X
  
  -- Quickness
  db:priv_AddDB("Runes", 520101); -- Quickness I
  db:priv_AddDB("Runes", 520102); -- Quickness II
  db:priv_AddDB("Runes", 520103); -- Quickness III
  db:priv_AddDB("Runes", 520104); -- Quickness IV
  db:priv_AddDB("Runes", 520105); -- Quickness V
  db:priv_AddDB("Runes", 520106); -- Quickness VI
  db:priv_AddDB("Runes", 520107); -- Quickness VII
  db:priv_AddDB("Runes", 520108); -- Quickness VIII
  db:priv_AddDB("Runes", 520109); -- Quickness IX
  db:priv_AddDB("Runes", 520110); -- Quickness X
  
  -- Reconciliation
  db:priv_AddDB("Runes", 520701); -- Reconciliation I
  db:priv_AddDB("Runes", 520702); -- Reconciliation II
  db:priv_AddDB("Runes", 520703); -- Reconciliation III
  db:priv_AddDB("Runes", 520704); -- Reconciliation IV
  db:priv_AddDB("Runes", 520705); -- Reconciliation V
  db:priv_AddDB("Runes", 520706); -- Reconciliation VI
  db:priv_AddDB("Runes", 520707); -- Reconciliation VII
  db:priv_AddDB("Runes", 520708); -- Reconciliation VIII
  db:priv_AddDB("Runes", 520709); -- Reconciliation IX
  db:priv_AddDB("Runes", 520710); -- Reconciliation X
  
  -- Resistance
  db:priv_AddDB("Runes", 520041); -- Resistance I
  db:priv_AddDB("Runes", 520042); -- Resistance II
  db:priv_AddDB("Runes", 520043); -- Resistance III
  db:priv_AddDB("Runes", 520044); -- Resistance IV
  db:priv_AddDB("Runes", 520045); -- Resistance V
  db:priv_AddDB("Runes", 520046); -- Resistance VI
  db:priv_AddDB("Runes", 520047); -- Resistance VII
  db:priv_AddDB("Runes", 520048); -- Resistance VIII
  db:priv_AddDB("Runes", 520049); -- Resistance IX
  db:priv_AddDB("Runes", 520050); -- Resistance X
  
  -- Resistor
  db:priv_AddDB("Runes", 520401); -- Resistor I
  db:priv_AddDB("Runes", 520402); -- Resistor II
  db:priv_AddDB("Runes", 520403); -- Resistor III
  db:priv_AddDB("Runes", 520404); -- Resistor IV
  db:priv_AddDB("Runes", 520405); -- Resistor V
  db:priv_AddDB("Runes", 520406); -- Resistor VI
  db:priv_AddDB("Runes", 520407); -- Resistor VII
  db:priv_AddDB("Runes", 520408); -- Resistor VIII
  db:priv_AddDB("Runes", 520409); -- Resistor IX
  db:priv_AddDB("Runes", 520410); -- Resistor X
  
  -- Revolution
  db:priv_AddDB("Runes", 520601); -- Revolution I
  db:priv_AddDB("Runes", 520602); -- Revolution II
  db:priv_AddDB("Runes", 520603); -- Revolution III
  db:priv_AddDB("Runes", 520604); -- Revolution IV
  db:priv_AddDB("Runes", 520605); -- Revolution V
  db:priv_AddDB("Runes", 520606); -- Revolution VI
  db:priv_AddDB("Runes", 520607); -- Revolution VII
  db:priv_AddDB("Runes", 520608); -- Revolution VIII
  db:priv_AddDB("Runes", 520609); -- Revolution IX
  db:priv_AddDB("Runes", 520610); -- Revolution X
  
  -- Rouse
  db:priv_AddDB("Runes", 520321); -- Rouse I
  db:priv_AddDB("Runes", 520322); -- Rouse II
  db:priv_AddDB("Runes", 520323); -- Rouse III
  db:priv_AddDB("Runes", 520324); -- Rouse IV
  db:priv_AddDB("Runes", 520325); -- Rouse V
  db:priv_AddDB("Runes", 520326); -- Rouse VI
  db:priv_AddDB("Runes", 520327); -- Rouse VII
  db:priv_AddDB("Runes", 520328); -- Rouse VIII
  db:priv_AddDB("Runes", 520329); -- Rouse IX
  db:priv_AddDB("Runes", 520330); -- Rouse X
  
  -- Shell
  db:priv_AddDB("Runes", 520221); -- Shell I
  db:priv_AddDB("Runes", 520222); -- Shell II
  db:priv_AddDB("Runes", 520223); -- Shell III
  db:priv_AddDB("Runes", 520224); -- Shell IV
  db:priv_AddDB("Runes", 520225); -- Shell V
  db:priv_AddDB("Runes", 520226); -- Shell VI
  db:priv_AddDB("Runes", 520227); -- Shell VII
  db:priv_AddDB("Runes", 520228); -- Shell VIII
  db:priv_AddDB("Runes", 520229); -- Shell IX
  db:priv_AddDB("Runes", 520230); -- Shell X
  
  -- Shield
  db:priv_AddDB("Runes", 520641); -- Shield I
  db:priv_AddDB("Runes", 520642); -- Shield II
  db:priv_AddDB("Runes", 520643); -- Shield III
  db:priv_AddDB("Runes", 520644); -- Shield IV
  db:priv_AddDB("Runes", 520645); -- Shield V
  db:priv_AddDB("Runes", 520646); -- Shield VI
  db:priv_AddDB("Runes", 520647); -- Shield VII
  db:priv_AddDB("Runes", 520648); -- Shield VIII
  db:priv_AddDB("Runes", 520649); -- Shield IX
  db:priv_AddDB("Runes", 520650); -- Shield X
  
  -- Sorcery
  db:priv_AddDB("Runes", 520541); -- Sorcery I
  db:priv_AddDB("Runes", 520542); -- Sorcery II
  db:priv_AddDB("Runes", 520543); -- Sorcery III
  db:priv_AddDB("Runes", 520544); -- Sorcery IV
  db:priv_AddDB("Runes", 520545); -- Sorcery V
  db:priv_AddDB("Runes", 520546); -- Sorcery VI
  db:priv_AddDB("Runes", 520547); -- Sorcery VII
  db:priv_AddDB("Runes", 520548); -- Sorcery VIII
  db:priv_AddDB("Runes", 520549); -- Sorcery IX
  db:priv_AddDB("Runes", 520550); -- Sorcery X
  
  -- Strike
  db:priv_AddDB("Runes", 520181); -- Strike I
  db:priv_AddDB("Runes", 520182); -- Strike II
  db:priv_AddDB("Runes", 520183); -- Strike III
  db:priv_AddDB("Runes", 520184); -- Strike IV
  db:priv_AddDB("Runes", 520185); -- Strike V
  db:priv_AddDB("Runes", 520186); -- Strike VI
  db:priv_AddDB("Runes", 520187); -- Strike VII
  db:priv_AddDB("Runes", 520188); -- Strike VIII
  db:priv_AddDB("Runes", 520189); -- Strike IX
  db:priv_AddDB("Runes", 520190); -- Strike X
  
  -- Triumph
  db:priv_AddDB("Runes", 520341); -- Triumph I
  db:priv_AddDB("Runes", 520342); -- Triumph II
  db:priv_AddDB("Runes", 520343); -- Triumph III
  db:priv_AddDB("Runes", 520344); -- Triumph IV
  db:priv_AddDB("Runes", 520345); -- Triumph V
  db:priv_AddDB("Runes", 520346); -- Triumph VI
  db:priv_AddDB("Runes", 520347); -- Triumph VII
  db:priv_AddDB("Runes", 520348); -- Triumph VIII
  db:priv_AddDB("Runes", 520349); -- Triumph IX
  db:priv_AddDB("Runes", 520350); -- Triumph X
  
  -- Vitality
  db:priv_AddDB("Runes", 520081); -- Vitality I
  db:priv_AddDB("Runes", 520082); -- Vitality II
  db:priv_AddDB("Runes", 520083); -- Vitality III
  db:priv_AddDB("Runes", 520084); -- Vitality IV
  db:priv_AddDB("Runes", 520085); -- Vitality V
  db:priv_AddDB("Runes", 520086); -- Vitality VI
  db:priv_AddDB("Runes", 520087); -- Vitality VII
  db:priv_AddDB("Runes", 520088); -- Vitality VIII
  db:priv_AddDB("Runes", 520089); -- Vitality IX
  db:priv_AddDB("Runes", 520090); -- Vitality X
  
  -- Wall
  db:priv_AddDB("Runes", 520621); -- Wall I
  db:priv_AddDB("Runes", 520622); -- Wall II
  db:priv_AddDB("Runes", 520623); -- Wall III
  db:priv_AddDB("Runes", 520624); -- Wall IV
  db:priv_AddDB("Runes", 520625); -- Wall V
  db:priv_AddDB("Runes", 520626); -- Wall VI
  db:priv_AddDB("Runes", 520627); -- Wall VII
  db:priv_AddDB("Runes", 520628); -- Wall VIII
  db:priv_AddDB("Runes", 520629); -- Wall IX
  db:priv_AddDB("Runes", 520630); -- Wall X
  
  -- Wrath
  db:priv_AddDB("Runes", 520801); -- Wrath I
  db:priv_AddDB("Runes", 520802); -- Wrath II
  db:priv_AddDB("Runes", 520803); -- Wrath III
  db:priv_AddDB("Runes", 520804); -- Wrath IV
  db:priv_AddDB("Runes", 520805); -- Wrath V
  db:priv_AddDB("Runes", 520806); -- Wrath VI
  db:priv_AddDB("Runes", 520807); -- Wrath VII
  db:priv_AddDB("Runes", 520808); -- Wrath VIII
  db:priv_AddDB("Runes", 520809); -- Wrath IX
  db:priv_AddDB("Runes", 520810); -- Wrath X
end;

local function priv_AddFusionStones(db)
  -- Purple
  db:priv_AddDB("FusionStones", 202881); -- Purified Fusion Stone
  -- Fusion Stone
  db:priv_AddDB("FusionStones", 202882); -- Fusion Stone
  db:priv_AddDB("FusionStones", 202883); -- Fusion Stone
  db:priv_AddDB("FusionStones", 202885); -- Fusion Stone
  db:priv_AddDB("FusionStones", 202995); -- Fusion Stone
  db:priv_AddDB("FusionStones", 202996); -- Fusion Stone
  db:priv_AddDB("FusionStones", 202997); -- Fusion Stone
  db:priv_AddDB("FusionStones", 202998); -- Fusion Stone
  db:priv_AddDB("FusionStones", 203000); -- Fusion Stone
  db:priv_AddDB("FusionStones", 203001); -- Fusion Stone
  db:priv_AddDB("FusionStones", 203002); -- Fusion Stone
  db:priv_AddDB("FusionStones", 203003); -- Fusion Stone
  db:priv_AddDB("FusionStones", 203004); -- Fusion Stone
  db:priv_AddDB("FusionStones", 202880); -- Fusion Stone
  db:priv_AddDB("FusionStones", 202999); -- Random Fusion Stone
  -- Mana Stone
  db:priv_AddDB("FusionStones", 202840); -- Mana Stone Tier 1
  db:priv_AddDB("FusionStones", 202841); -- Mana Stone Tier 2
  db:priv_AddDB("FusionStones", 202842); -- Mana Stone Tier 3
  db:priv_AddDB("FusionStones", 202843); -- Mana Stone Tier 4
  db:priv_AddDB("FusionStones", 202844); -- Mana Stone Tier 5
  db:priv_AddDB("FusionStones", 202845); -- Mana Stone Tier 6
  db:priv_AddDB("FusionStones", 202846); -- Mana Stone Tier 7
  db:priv_AddDB("FusionStones", 202847); -- Mana Stone Tier 8
  db:priv_AddDB("FusionStones", 202848); -- Mana Stone Tier 9
  db:priv_AddDB("FusionStones", 202849); -- Mana Stone Tier 10
  db:priv_AddDB("FusionStones", 202850); -- Mana Stone Tier 11
  db:priv_AddDB("FusionStones", 202851); -- Mana Stone Tier 12
  db:priv_AddDB("FusionStones", 202852); -- Mana Stone Tier 13
  db:priv_AddDB("FusionStones", 202853); -- Mana Stone Tier 14
  db:priv_AddDB("FusionStones", 202854); -- Mana Stone Tier 15
  db:priv_AddDB("FusionStones", 202855); -- Mana Stone Tier 16
  db:priv_AddDB("FusionStones", 202856); -- Mana Stone Tier 17
  db:priv_AddDB("FusionStones", 202857); -- Mana Stone Tier 18
  db:priv_AddDB("FusionStones", 202858); -- Mana Stone Tier 19
  db:priv_AddDB("FusionStones", 202859); -- Mana Stone Tier 20
end;

UMMItemDB = ResourceItemFilter;
UMMItemDB:Init();

-- Supplies
priv_AddFoods(UMMItemDB);
priv_AddDesserts(UMMItemDB);
priv_AddPotions(UMMItemDB);

-- Materials
priv_AddOres(UMMItemDB);
priv_AddWood(UMMItemDB);
priv_AddHerbs(UMMItemDB);
priv_AddRawMaterials(UMMItemDB);
priv_AddProductionRunes(UMMItemDB);

-- Equipment Enchancements
priv_AddJewels(UMMItemDB);
priv_AddRunes(UMMItemDB);
priv_AddFusionStones(UMMItemDB);
