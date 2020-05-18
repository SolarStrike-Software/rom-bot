local powerOfTwoTable = {};
local scaleFactor = 65535;

--[[ Constructs a lookup table
	This is much faster than doing it dynamically
	every time a lookup is needed.
	
	The key of each item is the exponent, and the value
	will be two-to-the-power-of the given exponent.
	For example: 2 -> 4, 3 -> 8, ..., 9 -> 512, 10 -> 1024, etc.
--]]
local function createPowerOfTwoTable()
	powerOfTwoTable = {};
	for i = 0,30 do
		table.insert(powerOfTwoTable, i, 2 ^ i);
	end
end
createPowerOfTwoTable();


QWord = class();

--[[
	Simply returns a value out of the above lookup table.
	If a value does not exactly fit a power of two, this
	will return the highest power-of-two that would fit.
	For example:
	exponent = QWord:getPowerOfTwoExponent(768)
	
	'exponent' would be 9 has 512 is the highest power of
	two that fits into 768.
--]]
function QWord:getPowerOfTwoExponent(input)
	for i,v in pairs(powerOfTwoTable) do
		if( input == v ) then
			return i;
		elseif( input < v ) then
			return i - 1;
		end
	end
end


function QWord:toQWord(value)
	exponent	=	self:getPowerOfTwoExponent(value);
	expPof2		=	2 ^ exponent; -- Two to the power of exponent
	--nextPof2	=	2 ^ (exponent+1); -- The 'next' power of two
	ratio		=	(value - expPof2) / (--[[nextPof2 - ]]expPof2); -- Ratio between this power of two and next
	
	-- Hard to explain this one. Basically just popping all the info into the right bytes, and
	-- inserting the 0x40000000 over top
	result		=	bitOr(scaleFactor * (bitLShift(exponent-1, 4) + (16 * ratio)), 0x40000000)
	
	return result;
end

function QWord:fromQWord(value)
	-- Bitwise and
	function bitand(a, b)
		local result = 0
		local bitval = 1
		while a > 0 and b > 0 do
		  if a % 2 == 1 and b % 2 == 1 then -- test the rightmost bits
			  result = result + bitval      -- set the current bit
		  end
		  bitval = bitval * 2 -- shift left
		  a = math.floor(a/2) -- shift right
		  b = math.floor(b/2)
		end
		return result
	end

	value	=	bitRShift(bitLShift(value, 4), 4); -- Chop the 0x40, we don't care about that
	value	=	value / scaleFactor; -- Scale the value down
	
	exponent		=	bitRShift(value, 4) + 1; -- Our exponent is the left-most bit, + 1
	lowerPowerOfTwo	=	2 ^ exponent;
	
	-- The "remainder" is basically: (the value - (2 to the power of 'exponent'))
	-- Because it's stored in hex, ratio is always 1/16th of the remainder
	remainder		=	value - bitand(value, bitLShift(exponent - 1, 4));
	ratio			=	remainder / 16;
	result			=	lowerPowerOfTwo + (ratio*lowerPowerOfTwo);
	
	return result;
end