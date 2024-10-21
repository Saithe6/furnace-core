---a furnace array library

---constructs a new furnace with the given input, output, and fuel inventories
---@param inputAddr string the name of an inventory that feeds into the furnace's input slot
---@param outputAddr string the name of an inventory that pulls from the furnace's output slot
---@param fuelAddr string the name of an inventory that feeds into the furnace's fuel slot
local function newFurnace(inputAddr,outputAddr,fuelAddr)
  if type(inputAddr) == "string" then inputAddr = peripheral.wrap(inputAddr) end
  if type(outputAddr) == "string" then outputAddr = peripheral.wrap(outputAddr) end
  if type(fuelAddr) == "string" then fuelAddr = peripheral.wrap(fuelAddr) end
  local furnace = {
    ---pulls items from fromAddr into the furnace input until amount is reached
    ---@param fromAddr string
    ---@param amount integer
    input = function(fromAddr,amount)
      local list = peripheral.call(fromAddr,"list")
      for i = 1,54 do
        if list[i] ~= nil and amount > 0 then
          local limit = amount
          if amount > 64 then
            limit = 64
          end
          inputAddr.pullItems(fromAddr,i,limit)
          amount = amount - list[i].count
        end
      end
    end,
    ---pushes items from the furnace output into toAddr
    ---@param toAddr string
    output = function(toAddr)
      local list = outputAddr.list()
      for i = 1,54 do
        if list[i] ~= nil then
          outputAddr.pushItems(toAddr,i)
        end
      end
    end,
    ---pulls items from fromAddr into the furnace fuel input until amount is reached
    ---@param fromAddr string
    ---@param amount integer
    refuel = function(fromAddr,amount)
      local list = peripheral.call(fromAddr,"list")
      for i = 1,54 do
        if list[i] ~= nil and amount > 0 then
          local limit = amount
          if amount > 64 then
            limit = 64
          end
          fuelAddr.pullItems(fromAddr,i,limit)
          amount = amount - list[i].count
        end
      end
    end
  }
  return furnace
end

-- for every furnace in your array, call newFurnace in this table
-- the excess furnace is a furnace used to send the remainder of items when they don't divide evenly amongst your furnaces
-- the chest table contains the names of the inventories that'll act as your input, output, and fuel chests
-- only furnaces should be in this table without a key, because the library relies on every numbered item being a furnace
local core = {
  newFurnace("minecraft:chest_0","minecraft:chest_1","minecraft:chest_2"),
  excess = newFurnace("minecraft:chest_3","minecraft:chest_4","minecraft:chest_5"),
  chest = {
    input = "minecraft:chest_6",
    fuel = "minecraft:chest_7",
    output = "minecraft:chest_8",
  }
}

---divides the items in core.chest.input and distributes them amongst the furnaces, sending the remainder to core.excess.input
function core.divItems()
  local sum = 0
  local list = peripheral.call(core.chest.input,"list")
  for _,v in pairs(list) do
    sum = sum + v.count
  end
  if sum < #core then
    core.excess.input(core.chest.input,sum)
  else
    local perFurnace = math.floor(sum/#core)
    local tail = sum%#core
    local counters = {}
    for i = 1,#core do
      counters[i] = perFurnace
    end
    for i,v in ipairs(counters) do
      core[i].input(core.chest.input,v)
    end
    if tail > 0 then
      core.excess.input(core.chest.input,tail)
    end
  end
end

---divides the items in core.chest.fuel and distributes them amongst the furnaces, sending the remainder to core.excess.fuel
function core.divFuel()
  local sum = 0
  local list = peripheral.call(core.chest.fuel,"list")
  for _,v in pairs(list) do
    sum = sum + v.count
  end
  if sum < #core then
    core.excess.refuel(core.chest.fuel,sum)
  else
    local perFurnace = math.floor(sum/#core)
    local tail = sum%#core
    local counters = {}
    for i = 1,#core do
      counters[i] = perFurnace
    end
    for i,v in ipairs(counters) do
      core[i].refuel(core.chest.fuel,v)
    end
    if tail > 0 then
      core.excess.refuel(core.chest.fuel,tail)
    end
  end
end

---pulls all the items from the various output chests into core.chest.output
function core.dump()
  for _,v in ipairs(core) do
    v.output(core.chest.output)
  end
  core.excess.output(core.chest.output)
end

return core
