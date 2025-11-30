local MathUtils = {}

--- Linear interpolation: formula used to get a certain value between two specified values by using a magnitude from 0 to 1.
--- See [Lerping](https://rfcs.luau.org/function-math-lerp.html).
function MathUtils.Lerp(a: number, b: number, t: number): number
    return a + (b - a) * t
end

--- @return Returns a string containing the passed number to be 2 digits or more, filling the blank spaces with zeros.
function MathUtils.FormatInt(Int: number): string
	return string.format("%02i", Int)
end

--- Function that'll turn a seconds value to Days:Hours:Minutes:Seconds format in a string.
function MathUtils.ConvertToDHMS(Seconds: number): string
	local Minutes = (Seconds - Seconds % 60) / 60
	Seconds -= Minutes * 60
	local Hours = (Minutes - Minutes % 60) / 60
	Minutes -= Hours * 60

    local Days = 0
    if Hours > 23 then
        Days = (Hours - Hours % 24) / 24
        Hours -= Days * 24
    end

    local FinalText = MathUtils.FormatInt(Hours)..":"..MathUtils.FormatInt(Minutes)..":"..MathUtils.FormatInt(Seconds)

    if Days > 0 then
        FinalText = MathUtils.FormatInt(Days)..":"..FinalText
    end

	return FinalText
end

--- Function that works like `FormatInt` but is used to return seconds in Minutes:Seconds format.
function MathUtils.ConvertToMinSec(Seconds: number): string
	return string.format("%02i:%02i", Seconds / 60, Seconds % 60)
end

local RomanNumeralMap = {
    [1000] = 'M',
    [900] = 'CM',
    [500] = 'D',
    [400] = 'CD',
    [100] = 'C',
    [50] = 'L',
    [40] = 'XL',
    [10] = 'X',
    [9] = 'IX',
    [5] = 'V',
    [4] = 'IV',
    [1] = 'I',
}

--- Converts an `int` to roman numerals in a `string`. 
function MathUtils.IntToRoman(num: number): string
    local roman = ""

    while num > 0 do
        for int, romanChar in RomanNumeralMap do 
            while num >= int do
                roman = roman..romanChar
                num -= int
            end
        end
    end
    
    return roman
end

--- Calculates a character's level from an EXP value.
--- Will increase the requirement for the next level until level 100 and begins at 1.
function MathUtils.CalculateLevelFromEXP(EXP: number): (number, number, number)
	local Levels = 1
	local EXPForNextLevel = 100
	local EXPRemaining = EXP

	while EXPForNextLevel <= EXPRemaining do
		EXPRemaining -= EXPForNextLevel

		Levels += 1

		EXPForNextLevel = math.round(math.clamp(Levels, 1, 100) * 12 + 80)
	end

	return Levels, EXPRemaining, EXPForNextLevel
end

--- Maps a numeric range onto another and returns position `t`.
function MathUtils.MapToRange(t: number, a: number, b: number, c: number, d: number): number
	return c + ((d - c) / (b - a)) * (t - a)
end

--- Wraps a number between two values, meaning that if it's out of bounds, it turns to the contrary bound.
--- For example, if the value is less than the minimum, it'll turn into the maximum and viceversa.
function MathUtils.WrapNum(Value: number, Minimum: number, Maximum: number): number
    if Value < Minimum then
        Value = Maximum
    elseif Value > Maximum then
        Value = Minimum
    end

    return Value
end

return MathUtils
