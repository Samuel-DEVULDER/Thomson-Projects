#!tools/lua52.exe
-- http://files.luaforge.net/releases/luabinaries/aLua5.2-work2/Executables

-- mods:
-- http://computer.freepage.de/nofuture/
-- http://amigamusic.tripod.com/game.html
-- https://demozoo.org/productions/69357/
-- http://www.jeffgodin.ca/mods.shtml
-- http://amp.dascene.net/detail.php?detail=modules&view=2539

-- local thomson = {div=2.5, org=0x7800, period=208, tempo=17, compress=true, rms=.5^.5}
local thomson = {
	quality=128,   -- min-frequency lower-limit. This changes the quality of the sound. Value 256 is the best but takes more memory. 128 is a good value.
	org=0x6B00,    -- address of the module.
	period=200,    -- playback speed per sample (in microsec).
	tempo=100,     -- how many playbacks loops before fetching a new row.
	compress=true, -- compresses the patterns by factorizing common sequences of commands. Set to false for debug.
	norm=.5^.5,    -- sample-level adjustment.
	dither=true,   -- uses dither.
	shaper=true,   -- uses shibata noise-shaper in dithering.
	volume=15,     -- general volume.
	loop=0,        -- number of times we loop the module or repetition part.
	border=nil     -- if {} then output instructions to change the border color according to the volume.
}

local function printf(...)
    io.stderr:write(string.format(...))
    io.stderr:flush()
end

-- parses command line
for _,v in ipairs(arg) do
	if v:sub(1,2)=='-o' and not v:find('=') then
		thomson.output=v:sub(3):gsub('^/cygdrive/(%w)/','%1:/')
	elseif v:sub(1,2)=='-S'  and not v:find('=') then
		thomson.assembly=v:sub(3):gsub('^/cygdrive/(%w)/','%1:/')
	elseif v:sub(1,1)=='-' then
		local val=v:gsub(".*=","return ")
		local key=v:gsub("=.*",""):sub(2)
		thomson[key] = assert(loadstring(val))()
	elseif not thomson.input then
		thomson.input = v:gsub('^/cygdrive/(%w)/','%1:/')
		local f=io.open(thomson.input,'rb')
		if f~=nil then f:close() else error('File does not exist: ' .. thomson.input) end
	else
		error('Inputfile already set: ' .. v)
	end
end
if not thomson.output or thomson.output=='' then
	local path = thomson.input:gsub("[^/\\]*$","")
	local name = thomson.input:gsub("^.*[/\\]","")
							  :gsub("^[mM][oO][dD]\.","")
							  :gsub("\.[mM][oO][dD]$","")
	thomson.output = path .. name .. '.M0D'
end
if thomson.assembly=='' then
	thomson.assembly = thomson.output:gsub("M0D$","ASS")
end

function ModFile(mod)
    -- converted from https://github.com/gasman/jsmodplayer/blob/master/modfile.js
    local function substr(str,pos,len)
        return str:sub(pos+1,pos+len)
    end
    local function trimNulls(str)
        return str:gsub("%z.*$","")
    end
    local function cleanString(str)
        return trimNulls(str):gsub("%c",""):gsub("[^%w%p%s]","?")
    end

    local function getWord(str, pos)
        local a,b = str:byte(pos+1,pos+2)
        return a*256+b
    end
    local function getByte(str, pos)
        return str:byte(pos+1)
    end

    local this = {}
    this.data = mod
    this.samples = {}
    this.positions = {}
    this.patternCount = 0
    this.patterns = {}

    this.title = cleanString(substr(mod,0,20))

    --[[
    TODO: distinguish 15-sample and 31-sample mods. Currently assuming 31-sample.
    "Check the bytes at location 471 in the file. If there is text there (ASCII
    $20-$7E (32-126)), then you can probably assume it's a 31-instrument file.
    Otherwise, it's an older 15 instrument file." */
    --]]
    
    this.sampleCount = 31
    for i=0,21 do
        local byte = getByte(mod,20+15*30+i)
        if byte==0 then 
            this.sampleCount=-math.abs(this.sampleCount) -- locked
        elseif this.sampleCount>=0 and (byte<32 or byte>126) then
            this.sampleCount = -15
        end
    end
    this.sampleCount = math.abs(this.sampleCount)

    for i=1,this.sampleCount do
        local sampleInfo = substr(mod, 20+(i-1)*30, 30)
        local sampleName = cleanString(substr(sampleInfo, 0, 22))
        local sample = {
            no =  i,
            name = sampleName,
            length = getWord(sampleInfo, 22) * 2,
            finetune = getByte(sampleInfo, 24),
            volume = getByte(sampleInfo, 25),
            repeatOffset = getWord(sampleInfo, 26) * 2,
            repeatLength = getWord(sampleInfo, 28) * 2
        }
        sample.isRepeating = (sample.repeatOffset + sample.repeatLength)>2
        this.samples[i] = sample
        -- printf('s:%d l=%d rO=%d rL=%d\n', i,this.samples[i].length,this.samples[i].repeatOffset, this.samples[i].repeatLength)
    end

    local o950 = 20+this.sampleCount*30
    this.positionCount = getByte(mod,o950)
    this.positionLoopPoint = getByte(mod, o950+1)+1

    for i=1,this.positionCount*0+128 do
        this.positions[i] = getByte(mod, o950+1+i)+1
        this.patternCount = math.max(this.patternCount, this.positions[i])
    end

	local o1080=o950+2+128
    local identifier = substr(mod,o1080,4)
    local channelCountByIdentifier = {
         ['TDZ1'] = 1, ['1CHN'] = 1, ['TDZ2'] = 2, ['2CHN'] = 2, ['TDZ3'] = 3, ['3CHN'] = 3,
         ['M.K.'] = 4, ['FLT4'] = 4, ['M!K!'] = 4, ['4CHN'] = 4, ['TDZ4'] = 4, ['5CHN'] = 5, ['TDZ5'] = 5,
         ['6CHN'] = 6, ['TDZ6'] = 6, ['7CHN'] = 7, ['TDZ7'] = 7, ['8CHN'] = 8, ['TDZ8'] = 8, ['OCTA'] = 8, ['CD81'] = 8,
         ['9CHN'] = 9, ['TDZ9'] = 9,
         ['10CH'] = 10, ['11CH'] = 11, ['12CH'] = 12, ['13CH'] = 13, ['14CH'] = 14, ['15CH'] = 15, ['16CH'] = 16, ['17CH'] = 17,
         ['18CH'] = 18, ['19CH'] = 19, ['20CH'] = 20, ['21CH'] = 21, ['22CH'] = 22, ['23CH'] = 23, ['24CH'] = 24, ['25CH'] = 25,
         ['26CH'] = 26, ['27CH'] = 27, ['28CH'] = 28, ['29CH'] = 29, ['30CH'] = 30, ['31CH'] = 31, ['32CH'] = 32
    }
    this.channelCount = channelCountByIdentifier[identifier] or 4
    this.identifier = identifier

    local patternOffset = o1080+4
    for pat=1,this.patternCount do
        this.patterns[pat] = {no=pat};
        for row=1,64 do
            this.patterns[pat][row] = {};
            for chan=1,this.channelCount do
                local b0 = getByte(mod,patternOffset + 0)
                local b1 = getByte(mod,patternOffset + 1)
                local b2 = getByte(mod,patternOffset + 2)
                local b3 = getByte(mod,patternOffset + 3)
                this.patterns[pat][row][chan] = {
                    sample = math.floor(b0/16)*16 + math.floor(b2/16),
                    period = (b0 % 16)*256 + b1,
                    effect = b2 % 16,
                    effectParameter = b3
                }
                patternOffset = patternOffset + 4
            end
			-- printf("%d:%d %d %d %d\n",pat-1,row-1,
					-- this.patterns[pat][row][1].sample,
					-- this.patterns[pat][row][2].sample,
					-- this.patterns[pat][row][3].sample,
					-- this.patterns[pat][row][4].sample)
        end
    end

    local sampleOffset = patternOffset
	-- printf("%d %d >%s<\n", o1080,this.patternCount,identifier)
    for s=1,this.sampleCount do
		local sample = this.samples[s]
        sample.startOffset = sampleOffset;
		sample.dc_offset = 0
        sample.getSample = function(pos)
            if pos>=sample.length then pos=sample.length-1 end
            local b = getByte(mod, sample.startOffset+pos) or 0
            -- do return b end -- unsigned 
            return ((b+128)%256)-128-sample.dc_offset -- signed
        end
		
		if false then -- debug: replace sample by sine wave
			sample.getSample = function(pos)
				return 127*math.sin(math.pi*pos/8)
			end
		end

		if false then -- debug: prints the profile of samples
			printf('s:%d (%d)\n',s, sample.startOffset)
			for i=0,sample.length-1 do
				printf("%s*\n",  string.rep(" ",math.floor((128+sample.getSample(i))/4)))
			end
		end
		
		local dc = 0
		for i=math.floor(2*sample.length/3),sample.length-1 do
			dc = dc+sample.getSample(i)
		end
		if sample.length>0 then	sample.dc_offset = 3*dc/sample.length end
		-- printf("%d: %g\n", s,sample.dc_offset)
        sampleOffset = sampleOffset + sample.length
    end

    return this
end

--[[
ModPeriodTable[ft][n] = the period to use for note number n at finetune value ft.
Finetune values are in twos-complement, i.e. [0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1]
The first table is used to generate a reverse lookup table, to find out the note number
for a period given in the MOD file.
--]]
local ModPeriodTable = {
    -- C   C#    D     D#    E      F     F#    G     G#    A     A#    B
    {1712, 1616, 1524, 1440, 1356, 1280, 1208, 1140, 1076, 1016, 960 , 906,  -- 0
     856 , 808 , 762 , 720 , 678 , 640 , 604 , 570 , 538 , 508 , 480 , 453,  -- 1
     428 , 404 , 381 , 360 , 339 , 320 , 302 , 285 , 269 , 254 , 240 , 226,  -- 2
     214 , 202 , 190 , 180 , 170 , 160 , 151 , 143 , 135 , 127 , 120 , 113,  -- 3
     107 , 101 , 95  , 90  , 85  , 80  , 75  , 71  , 67  , 63  , 60  , 56 }, -- 4
    {1700, 1604, 1514, 1430, 1348, 1274, 1202, 1134, 1070, 1010, 954 , 900,
     850 , 802 , 757 , 715 , 674 , 637 , 601 , 567 , 535 , 505 , 477 , 450,
     425 , 401 , 379 , 357 , 337 , 318 , 300 , 284 , 268 , 253 , 239 , 225,
     213 , 201 , 189 , 179 , 169 , 159 , 150 , 142 , 134 , 126 , 119 , 113,
     106 , 100 , 94  , 89  , 84  , 79  , 75  , 71  , 67  , 63  , 59  , 56 },
    {1688, 1592, 1504, 1418, 1340, 1264, 1194, 1126, 1064, 1004, 948 , 894,
     844 , 796 , 752 , 709 , 670 , 632 , 597 , 563 , 532 , 502 , 474 , 447,
     422 , 398 , 376 , 355 , 335 , 316 , 298 , 282 , 266 , 251 , 237 , 224,
     211 , 199 , 188 , 177 , 167 , 158 , 149 , 141 , 133 , 125 , 118 , 112,
     105 , 99  , 94  , 88  , 83  , 79  , 74  , 70  , 66  , 62  , 59  , 56 },
    {1676, 1582, 1492, 1408, 1330, 1256, 1184, 1118, 1056, 996 , 940 , 888,
     838 , 791 , 746 , 704 , 665 , 628 , 592 , 559 , 528 , 498 , 470 , 444,
     419 , 395 , 373 , 352 , 332 , 314 , 296 , 280 , 264 , 249 , 235 , 222,
     209 , 198 , 187 , 176 , 166 , 157 , 148 , 140 , 132 , 125 , 118 , 111,
     104 , 99  , 93  , 88  , 83  , 78  , 74  , 70  , 66  , 62  , 59  , 55 },
    {1664, 1570, 1482, 1398, 1320, 1246, 1176, 1110, 1048, 990 , 934 , 882,
     832 , 785 , 741 , 699 , 660 , 623 , 588 , 555 , 524 , 495 , 467 , 441,
     416 , 392 , 370 , 350 , 330 , 312 , 294 , 278 , 262 , 247 , 233 , 220,
     208 , 196 , 185 , 175 , 165 , 156 , 147 , 139 , 131 , 124 , 117 , 110,
     104 , 98  , 92  , 87  , 82  , 78  , 73  , 69  , 65  , 62  , 58  , 55 },
    {1652, 1558, 1472, 1388, 1310, 1238, 1168, 1102, 1040, 982 , 926 , 874,
     826 , 779 , 736 , 694 , 655 , 619 , 584 , 551 , 520 , 491 , 463 , 437,
     413 , 390 , 368 , 347 , 328 , 309 , 292 , 276 , 260 , 245 , 232 , 219,
     206 , 195 , 184 , 174 , 164 , 155 , 146 , 138 , 130 , 123 , 116 , 109,
     103 , 97  , 92  , 87  , 82  , 77  , 73  , 69  , 65  , 61  , 58  , 54 },
    {1640, 1548, 1460, 1378, 1302, 1228, 1160, 1094, 1032, 974 , 920 , 868,
     820 , 774 , 730 , 689 , 651 , 614 , 580 , 547 , 516 , 487 , 460 , 434,
     410 , 387 , 365 , 345 , 325 , 307 , 290 , 274 , 258 , 244 , 230 , 217,
     205 , 193 , 183 , 172 , 163 , 154 , 145 , 137 , 129 , 122 , 115 , 109,
     102 , 96  , 91  , 86  , 81  , 77  , 72  , 68  , 64  , 61  , 57  , 54 },
    {1628, 1536, 1450, 1368, 1292, 1220, 1150, 1086, 1026, 968 , 914 , 862,
     814 , 768 , 725 , 684 , 646 , 610 , 575 , 543 , 513 , 484 , 457 , 431,
     407 , 384 , 363 , 342 , 323 , 305 , 288 , 272 , 256 , 242 , 228 , 216,
     204 , 192 , 181 , 171 , 161 , 152 , 144 , 136 , 128 , 121 , 114 , 108,
     102 , 96  , 90  , 85  , 80  , 76  , 72  , 68  , 64  , 60  , 57  , 54 },
    {1814, 1712, 1616, 1524, 1440, 1356, 1280, 1208, 1140, 1076, 1016, 960,
     907 , 856 , 808 , 762 , 720 , 678 , 640 , 604 , 570 , 538 , 508 , 480,
     453 , 428 , 404 , 381 , 360 , 339 , 320 , 302 , 285 , 269 , 254 , 240,
     226 , 214 , 202 , 190 , 180 , 170 , 160 , 151 , 143 , 135 , 127 , 120,
     113 , 107 , 101 , 95  , 90  , 85  , 80  , 75  , 71  , 67  , 63  , 60 },
    {1800, 1700, 1604, 1514, 1430, 1350, 1272, 1202, 1134, 1070, 1010, 954,
     900 , 850 , 802 , 757 , 715 , 675 , 636 , 601 , 567 , 535 , 505 , 477,
     450 , 425 , 401 , 379 , 357 , 337 , 318 , 300 , 284 , 268 , 253 , 238,
     225 , 212 , 200 , 189 , 179 , 169 , 159 , 150 , 142 , 134 , 126 , 119,
     112 , 106 , 100 , 94  , 89  , 84  , 79  , 75  , 71  , 67  , 63  , 59 },
    {1788, 1688, 1592, 1504, 1418, 1340, 1264, 1194, 1126, 1064, 1004, 948,
     894 , 844 , 796 , 752 , 709 , 670 , 632 , 597 , 563 , 532 , 502 , 474,
     447 , 422 , 398 , 376 , 355 , 335 , 316 , 298 , 282 , 266 , 251 , 237,
     223 , 211 , 199 , 188 , 177 , 167 , 158 , 149 , 141 , 133 , 125 , 118,
     111 , 105 , 99  , 94  , 88  , 83  , 79  , 74  , 70  , 66  , 62  , 59 },
    {1774, 1676, 1582, 1492, 1408, 1330, 1256, 1184, 1118, 1056, 996 , 940,
     887 , 838 , 791 , 746 , 704 , 665 , 628 , 592 , 559 , 528 , 498 , 470,
     444 , 419 , 395 , 373 , 352 , 332 , 314 , 296 , 280 , 264 , 249 , 235,
     222 , 209 , 198 , 187 , 176 , 166 , 157 , 148 , 140 , 132 , 125 , 118,
     111 , 104 , 99  , 93  , 88  , 83  , 78  , 74  , 70  , 66  , 62  , 59 },
    {1762, 1664, 1570, 1482, 1398, 1320, 1246, 1176, 1110, 1048, 988 , 934,
     881 , 832 , 785 , 741 , 699 , 660 , 623 , 588 , 555 , 524 , 494 , 467,
     441 , 416 , 392 , 370 , 350 , 330 , 312 , 294 , 278 , 262 , 247 , 233,
     220 , 208 , 196 , 185 , 175 , 165 , 156 , 147 , 139 , 131 , 123 , 117,
     110 , 104 , 98  , 92  , 87  , 82  , 78  , 73  , 69  , 65  , 61  , 58 },
    {1750, 1652, 1558, 1472, 1388, 1310, 1238, 1168, 1102, 1040, 982 , 926,
     875 , 826 , 779 , 736 , 694 , 655 , 619 , 584 , 551 , 520 , 491 , 463,
     437 , 413 , 390 , 368 , 347 , 328 , 309 , 292 , 276 , 260 , 245 , 232,
     219 , 206 , 195 , 184 , 174 , 164 , 155 , 146 , 138 , 130 , 123 , 116,
     109 , 103 , 97  , 92  , 87  , 82  , 77  , 73  , 69  , 65  , 61  , 58 },
    {1736, 1640, 1548, 1460, 1378, 1302, 1228, 1160, 1094, 1032, 974 , 920,
     868 , 820 , 774 , 730 , 689 , 651 , 614 , 580 , 547 , 516 , 487 , 460,
     434 , 410 , 387 , 365 , 345 , 325 , 307 , 290 , 274 , 258 , 244 , 230,
     217 , 205 , 193 , 183 , 172 , 163 , 154 , 145 , 137 , 129 , 122 , 115,
     108 , 102 , 96  , 91  , 86  , 81  , 77  , 72  , 68  , 64  , 61  , 57 },
    {1724, 1628, 1536, 1450, 1368, 1292, 1220, 1150, 1086, 1026, 968 , 914,
     862 , 814 , 768 , 725 , 684 , 646 , 610 , 575 , 543 , 513 , 484 , 457,
     431 , 407 , 384 , 363 , 342 , 323 , 305 , 288 , 272 , 256 , 242 , 228,
     216 , 203 , 192 , 181 , 171 , 161 , 152 , 144 , 136 , 128 , 121 , 114,
     108 , 101 , 96  , 90  , 85  , 80  , 76  , 72  , 68  , 64  , 60  , 57 }}

local ModPeriodToNoteNumber = {};
for i,v in ipairs(ModPeriodTable[1]) do
    ModPeriodToNoteNumber[v] = i
end
local function getNoteNumber(note)
    local t = ModPeriodToNoteNumber[note]
    if not t then
        local d
        for _,tbl in ipairs(ModPeriodTable) do
            for i,v in ipairs(tbl) do
                local z=math.abs(v-note)
                if d==nil or z<d then t,d=i,z end
            end
        end
        ModPeriodToNoteNumber[note]=t
    end
    return t
end

local WaveformsTable = {{},{},{},{}}
do
    local t={0,255,0,-256}
    for i=0,63 do
        WaveformsTable[1][i+1] =   math.floor(math.sin(math.pi*i/32)*255)
        WaveformsTable[2][i+1] =   math.floor(255-i*512/64)
        WaveformsTable[3][i+1] = t[math.floor(1+i/16)]
        WaveformsTable[4][i+1] =   math.floor(math.random()*512-256)
    end
end
local VibratoTable, TremoloTable

local function clamp(x,min,max)
    if x<min then x=min end
    if x>max then x=max end
    return x
end

-- read mod file
local file = io.open(thomson.input, 'rb')
local mod = ModFile(file:read('*all'))
file:close()
if mod.channelCount>4 then error('Unsupported channel count: ' .. mod.channelCount) end
if mod.title=='' then mod.title = thomson.input:gsub('.*[/\\]','') end

-- timing calculations
local rate = 1000000/thomson.period -- thomson plays @ 200µs/sample
local ticksPerSecond = 7159090 -- NTSC (to give A-3 produce 440hz) 
                       -- 7093789.2 -- PAL frequency
local ticksPerFrame = 0 -- calculated by setBpm
local ticksPerOutputSample = math.floor(.5 + ticksPerSecond / rate)
local ticksSinceStartOfFrame = 0

local function setBpm(bpm)
    -- x beats per minute => x*4 rows per minute
    ticksPerFrame = math.floor(.5 + ticksPerSecond * 2.5/bpm)
    -- printf('Seconds Per Frame=%g\n',ticksPerFrame/ticksPerSecond)
end

-- initial player state
local framesPerRow,currentFrame,currentPattern,currentPosition,currentRow,nextPosition,nextRow
local channels = {}

local function resetPlayerData()
    ticksSinceStartOfFrame = 0
    setBpm(125)
    framesPerRow = 6
    currentFrame = 0
    currentPattern = 1
    currentPosition = 1
    currentRow = 1
    nextPosition = nil
    nextRow = nil
    delayCount = nil

    VibratoTable = WaveformsTable[1]
    TremoloTable = WaveformsTable[1]

    for chan=1,mod.channelCount do
        channels[chan] = {
            no = chan,
            playing = false,
            sample = mod.samples[1],
            finetune = 0,

            effectCallback = nil,

            volume = 0,
            volumeDelta = 0,

            periodDelta = 0,
            arpeggioActive = false,
            ticksPerSample = 1000000,
			
			portamento = {
				glissando = false,
				active = false,
				target = 4096,
				delta  = 0
			},

            vibrato = {
                active = false,
                latch  = 0,
                index  = 0,
                speed  = 0,
                depth  = 0
            },

            tremolo = {
                active = false,
                latch  = 0,
                index  = 0,
                speed  = 0,
                depth  = 0
            },

            loop = {
                start = nil,
                count = 0,
            }
        }
    end
end

local function loadRow(rowNumber)
    nextRow = nil
    currentRow = rowNumber
    currentFrame = 0
    for chan=1,mod.channelCount do
        local note = currentPattern[rowNumber][chan]
        local channel = channels[chan]
        -- thomson.ptn.add('* c:'..chan ..' s:'..note.sample..' f:'..note.period..' e:'..note.effect..' p:'..note.effectParameter)
        -- NdSam: variations spans only for a row, so reset them at beggining of a row
        local prevTicksPerSample = channel.ticksPerSample
        channel.periodDelta = 0
        channel.volumeDelta = 0
        channel.effectCallback = nil
        channel.arpeggioActive = false
        channel.vibrato.active = false
        channel.tremolo.active = false
        channel.portamento.active = false
        local noteFcn = function()
            if note.period~=0 or note.sample~=0 then
                channel.playing = true
                channel.samplePosition = 0
                channel.ticksSinceStartOfSample = 0 -- that's 'sample' as in 'individual volume reading'
                if note.sample>mod.sampleCount then
                    error('Invalid detection of sample count, please fix code (smp='..note.sample..' row '..currentRow.. ' pat '..currentPattern.no)
                end
                if note.sample ~= 0 then
                    channel.sample = mod.samples[note.sample]
                    channel.volume = channel.sample.volume
                    channel.finetune = channel.sample.finetune
                    channel.tremolo.latch = channel.volume
                    thomson.vol(chan)
                end
                if note.period ~= 0 then
                    channel.noteNumber = getNoteNumber(note.period)
                    channel.ticksPerSample = ModPeriodTable[1+channel.finetune][channel.noteNumber] * 2;
                    channel.vibrato.latch = channel.ticksPerSample
                    thomson.frq(chan)
                end
				thomson.smp(chan)
            end
        end
        if delayCount or note.effect==0xE and math.floor(note.effectParameter/16)==0xD then
            -- nothing right now
        else
            noteFcn()
        end

        if note.effect ~= 0 or note.effectParameter ~= 0 then
            -- https://wiki.openmpt.org/Manual:_Effect_Reference
            local effectNotSupported = true

            local x = math.floor(note.effectParameter/16)
            local y = note.effectParameter%16

            if note.effect==0x00 then -- arpeggio: 0xy
                effectNotSupported = false
                channel.arpeggioActive = true;
                channel.arpeggioNotes = {
                    channel.noteNumber,
                    channel.noteNumber + x,
                    channel.noteNumber + y
                }
                channel.arpeggioCounter = 0;
            end
            if note.effect==0x01 then -- pitch slide up - 1xx
                effectNotSupported = false
                channel.periodDelta = -note.effectParameter
                if channel.periodDelta==0 then
                    channel.periodDelta = channel.periodDeltaMem or 0
                end
                channel.periodDeltaMem = channel.periodDelta
            end
            if note.effect==0x02 then -- pitch slide down - 2xx
                effectNotSupported = false
                channel.periodDelta = note.effectParameter
                if channel.periodDelta==0 then
                    channel.periodDelta = channel.periodDeltaMem or 0
                end
                channel.periodDeltaMem = channel.periodDelta
            end
            if note.effect==0x03 then -- tonePortamento
                effectNotSupported = false
				local porta = channel.portamento
				porta.active = true
                if note.period~=0 then
					porta.target = channel.ticksPerSample
					channel.ticksPerSample = prevTicksPerSample
					thomson.frq(chan)
				else
					-- if channel.ticksPerSample<porta.target then
						-- channel.ticksPerSample=math.min(channel.ticksPerSample + porta.delta * 2, porta.target)
					-- else
						-- channel.ticksPerSample=math.max(channel.ticksPerSample - porta.delta * 2, porta.target)
					-- end
					-- thomson.frq(chan)
				end
                if note.effectParameter~=0 then
					porta.delta = note.effectParameter
				end
            end
            if note.effect==0x04 then -- Vibrato - 4xy
                effectNotSupported = false
                channel.vibrato.active = true
                channel.vibrato.speed = x>0 and x or channel.vibrato.speed or 0 
                channel.vibrato.depth = y>0 and y or channel.vibrato.depth or 0
            end
            if note.effect==0x05 then -- Volume Slide + Tone Portamento = 0x300 + 0xAxy
                effectNotSupported = false
                channel.portamento.active = true
                if note.period~=0 then
					channel.portamento.target = channel.ticksPerSample
					channel.ticksPerSample = prevTicksPerSample
					thomson.frq(chan)
				end
            end
            if note.effect==0x06 then -- VolSlide + Vibrato = 0x400 + 0xAxy
                effectNotSupported = false
                channel.vibrato.active = true
            end
            if note.effect==0x07 then -- Tremolo - 7xy
                effectNotSupported = false
                channel.tremolo.active = true
                channel.tremolo.speed = x>0 and x or channel.tremolo.speed or 0
                channel.tremolo.depth = y>0 and y or channel.tremolo.depth or 0
            end
            if note.effect==0x08 then
                effectNotSupported = false
                thomson.ptn.printf('* Ignoring set panning effect')
            end
            if note.effect==0x09 then -- sample offset
                effectNotSupported = false
                local sample=note.sample
                if sample==0 then sample=channel.sample.no end
                if note.period~=0 then
                    thomson.smpOffset(chan, sample, note.effectParameter)
                end
            end
            if note.effect==0x0a or note.effect==0x05 or note.effect==0x06 then -- volume slide - Axy
                effectNotSupported = false
                if x>0 then  -- volume increase by x
                    channel.volumeDelta = x
                else -- volume decrease by y
                    channel.volumeDelta = -y
                end
            end
            if note.effect==0x0b then -- position jump
                effectNotSupported = false
                nextPosition = 1 + note.effectParameter
                currentRow = 64
            end
            if note.effect==0x0c then -- volume
                effectNotSupported = false
                channel.volume = math.min(64, note.effectParameter)
                thomson.vol(chan)
            end
            if note.effect==0x0d then -- pattern break
                effectNotSupported = false
                -- damned effect is to be interpreted as decimal!
                nextRow = 1 + (math.floor(note.effectParameter/16)*10+(note.effectParameter%16))%64
                currentRow = 64
            end
            if note.effect==0x0E then -- misc
                if 0x00<=note.effectParameter and note.effectParameter<=0x01 then
                    -- filter on/off
                    effectNotSupported = false
                    thomson.ptn.printf('* ignoring 0xE(%d) for channel %d',note.effectParameter,chan)
                end
                if x==0x1 then -- Fine Portamento Up
                    effectNotSupported = false
                    channel.effectCallback = function(frame)
                        channel.ticksPerSample = clamp(channel.ticksPerSample + y * 2,96,4096)
                        channel.effectCallback = nil
                    end
                end
                if x==0x2 then -- Fine Portamento Down
                    effectNotSupported = false
                    channel.effectCallback = function(frame)
                        channel.ticksPerSample = clamp(channel.ticksPerSample - y * 2,96,4096)
                        channel.effectCallback = nil
                    end
                end
                if x==0x3 then
                    effectNotSupported = false
                    channel.portamento.glissando = y~=0
                end
                if x==0x4 then
                    effectNotSupported = false
                    channel.vibrato.index = y<4 and 0 or channel.vibrato.index
                    VibratoTable = WaveformsTable[1+(y%4)]
                end
                if x==0x5 then
                    effectNotSupported = false
                    if note.period>0 then
                        channel.finetune = y
                        channel.ticksPerSample = ModPeriodTable[1+channel.finetune][channel.noteNumber] * 2;
                        channel.vibrato.latch = channel.ticksPerSample
                        thomson.frq(chan)
                    end
                end
                if x==0x6 then
                    effectNotSupported = false
                    if y==0x0 then
                        channel.loop.start = currentRow
                    else
                        if channel.loop.count==0 then
                            channel.loop.count = y
                            nextRow = channel.loop.start or 1
                        else
                            channel.loop.count=channel.loop.count-1
                            if channel.loop.count>0 then
                                nextRow = channel.loop.start or 1
                            else
                                channel.loop.start = nil
                                channel.loop.count = 0
                            end
                        end
                    end
                end
                if x==0x7 then
                    effectNotSupported = false
                    channel.tremolo.index = y<4 and 0 or channel.tremolo.index
                    TremoloTable = WaveformsTable[1+(y%4)]
                end
                if x==0x8 then -- set panning
                    effectNotSupported = false
                end
                if x==0x9 then
                    effectNotSupported = false
                    if not channel.E9xCount then channel.E9xCount = 1 end
                    channel.effectCallback = function(frame)
                        if channel.E9xCount==y then
                            channel.E9xCount = 1
                            thomson.smp(chan)
                        else
                            channel.E9xCount = channel.E9xCount + 1
                        end
                    end
                else
                    channel.E9xCount = nil
                end
                if x==0xA then
                    effectNotSupported = false
                    channel.effectCallback = function(frame)
                        channel.volume = clamp(channel.volume + y,0,64)
                        channel.effectCallback = nil
                    end
                end
                if x==0xB then
                    effectNotSupported = false
                    channel.effectCallback = function(frame)
                        channel.volume = clamp(channel.volume - y,0,64)
                        channel.effectCallback = nil
                    end
                end
                if x==0xC then
                    effectNotSupported = false
                    channel.effectCallback = function(frame)
                        if frame==y then channel.volume = 0 end
                    end
                end
                if x==0xD then
                    effectNotSupported = false
                    channel.effectCallback = function(frame)
                        if frame==y then noteFcn() end
                    end
                end
                if x==0xE then
                    effectNotSupported = false
                    if delayCount then
                        delayCount=delayCount-1
                        if delayCount==0 then delayCount=nil end
                    else
                        delayCount = y
                    end
                end
            end
            if note.effect==0x0f then -- tempo change
                effectNotSupported = false
                if note.effectParameter == 0 then
                elseif note.effectParameter <= 32 then
                    framesPerRow = note.effectParameter
                else
                    setBpm(note.effectParameter)
                end
            end
            if effectNotSupported then
                local msg = string.format('* Unsupported effect 0x%02X(%02X) for Channel %d, Row %d, Pattern %d', note.effect, note.effectParameter, chan, rowNumber-1, (mod.positions[currentPosition] or mod.positions[1])-1)
                printf("%s\n",msg)
                -- error(msg)
            end
        end
    end
end

local function loadPattern(patternNumber)
    thomson.ptn.newPattern(patternNumber)

    currentPattern = mod.patterns[patternNumber % 1000]
    loadRow(nextRow or 1)
end

local function loadPosition(positionNumber)
    currentPosition = positionNumber;
    local newPat = mod.positions[currentPosition]
    if nextRow and nextRow~=1 and newPat and newPat<=128 then
        newPat = newPat + 1000*nextRow
        -- fake a new pattern for broken patterns (0xDxx)
        mod.positions[currentPosition] = newPat
    end
    loadPattern(newPat or mod.positions[1])
end

-- loadPosition(1)

local function getNextPosition()
    if currentPosition >= mod.positionCount then
        thomson.ptn.record = true
        thomson.ptn.add({0})
        thomson.cur = nil

        loadPosition(mod.positionLoopPoint)
        thomson.playing = false
    else
        loadPosition(nextPosition or currentPosition + 1)
    end
    nextPosition = nil
end

local function getNextRow()
    if delayCount then
        loadRow(currentRow)
    else
        -- print(currentPattern.no, currentRow, nextPosition, nextRow)
        if currentRow == 64 then
            getNextPosition()
        else
            loadRow(nextRow or currentRow + 1)
        end
    end
end

local function doFrame()
    currentFrame = currentFrame+1
    if not thomson.compress then thomson.ptn.add('* frame '..currentFrame) end
    -- apply volume/pitch slide before fetching row, because the first frame of a row does NOT have the slide applied
    for chan=1,mod.channelCount do
        local channel = channels[chan]
        if channel.effectCallback then channel.effectCallback(currentFrame) end
        channel.volume = clamp(channel.volume + channel.volumeDelta,0,64)
        if channel.portamento.active then
			local porta=channel.portamento
            if porta.glissando then -- semitone slide
                local k = 2^(1/12)
                if channel.ticksPerSample<porta.target then
                    channel.ticksPerSample=math.min(math.floor(.5 + channel.ticksPerSample * k),
                                                    porta.target)
                else
                    channel.ticksPerSample=math.max(math.floor(.5 + channel.ticksPerSample / k),
                                                    porta.target)
                end
            else -- normal portamento
                if channel.ticksPerSample<porta.target then
                    channel.ticksPerSample=math.min(channel.ticksPerSample + porta.delta * 2, porta.target)
                else
                    channel.ticksPerSample=math.max(channel.ticksPerSample - porta.delta * 2, porta.target)
                end
            end
			-- printf("%g -> %g (%g)\n", channel.ticksPerSample, porta.target,  porta.delta * 2)
        else
            channel.ticksPerSample = clamp(channel.ticksPerSample + channel.periodDelta * 2,96,4096)
        end
        if channel.arpeggioActive then
            local noteNumber = channel.arpeggioNotes[1+(channel.arpeggioCounter % 3)]
            channel.ticksPerSample = ModPeriodTable[1+channel.finetune][math.min(noteNumber,#ModPeriodTable[1])] * 2;
            channel.arpeggioCounter = channel.arpeggioCounter+1
        end
        if channel.vibrato.active then
            local e = channel.vibrato
            channel.ticksPerSample = clamp(e.latch + math.floor(VibratoTable[1 + e.index]*e.depth/127),96,4096)
            e.index  = (e.index + e.speed)%64
        end
        if channel.tremolo.active then
            local e = channel.tremolo
            channel.volume = clamp(e.latch + math.floor(TremoloTable[1 + e.index]*e.depth/127),0,64)
            e.index  = (e.index + e.speed)%64
        end
        thomson.vol(chan).frq(chan)
    end

    if currentFrame == framesPerRow then
        getNextRow();
    end
end

----------------------------------------------------------------------------------------------

function asmSection()
    local asm = {}

    local function err(...)
        error(string.format(...))
    end

    function asm.clear(self)
        self.labels = {}
        self.labelsDict = {}
        self.curAddress = 0
        self.maxAddress = 0
        self.sections   = {}
        self.curSection = nil
        return self
    end

    asm:clear()

    function asm.size(self)
        local size = 0
        for _,s in ipairs(self.sections) do
            size = size + s.len
        end
        return size
    end

    function asm.org(self, addr)
        self.curSection = {org=addr, len=0}
        self.curSection.add = function(sec, size, value)
            self.maxAddress = self.curAddress>self.maxAddress
                                and self.curAddress
                                 or self.maxAddress
            table.insert(sec, value)
            sec.len = sec.len + size
            self.curAddress = self.curAddress + size
        end
        self.curSection.asm = function(sec, pr, labels)
            pr = pr or print

            local addr = sec.org
            if addr~=thomson.org then pr() end
            pr(string.format(' org $%02X', addr))
            local t,s='',''
            function prNum(size,num)
                addr=addr+size
                local FCB=size==1 and ' fcb ' or ' fdb '
                if t~='' and not t:match(FCB) then
                    pr(t)
                    t=''
                end
                if t=='' then
                    t,s = FCB,''
                end
                local a=t..s..num
                if a:len()>=40 then
                    pr(t)
                    t = FCB..num
                else
                    t=a
                end
                s=','
            end
            for _,v in ipairs(sec) do
                if type(v)=='string' then -- comment
                    if v=='' then
                        pr(t)
                    elseif t=='' then
                        pr('* '..v)
                    else
                        pr(t..' ; '..v)
                    end
                    t=''
                else
                    if labels[addr] then
                        if t~='' then pr(t); t='' end
                        for _,v in ipairs(labels[addr]) do
                            pr(v.label .. ' set *')
                            labels[addr] = nil
                        end
                    end
                    if type(v)=='number' then -- byte
                        prNum(1,string.format('$%02x',v))
                    else -- word
                        local t=''
                        for _,v in ipairs(v) do
                            if type(v)=='table' then
                                t=t..v.label
                            elseif type(v)=='string' then
                                t=t..v
                            else
                                t=t..string.format('$%04x',v)
                            end
                        end
                        prNum(2, t)
                    end
                end
            end
            if t~='' then pr(t) end
            pr(string.format('* $%02X', addr-1))
        end
        self.curSection.bin = function(sec)
            local bin=string.char(0,
                                  math.floor(sec.len/256),sec.len%256,
                                  math.floor(sec.org/256),sec.org%256)

            for _,v in ipairs(sec) do
                if type(v)=='number' then -- byte
                    bin = bin .. string.char((v+256)%256)
                elseif type(v)=='table' then -- word
                    local t,c=0,1
                    for _,v in ipairs(v) do
                        if type(v)=='table' then
                            t,c = t + c*v.value,nil
                        elseif type(v)=='number' then
                            t,c = t + c*v,nil
                        elseif v=='+' then
                            c = 1
                        elseif v=='-' then
                            c = -1
                        elseif type(v)=='string' then
                            t,c = t + c*self:lbl(v).value,nil
                        else
                            err('Unknown arithmetic op: %s', v)
                        end
                    end
                    t=(t+65536)%65536
                    bin = bin .. string.char(math.floor(t/256),t%256)
                end
            end
            return bin
        end

        table.insert(self.sections, self.curSection)
        self.curAddress = addr
        return self
    end

    function asm.lbl(self, label)
        local lab = self.labelsDict[label]
        if not lab then
            lab = {}
            lab.label = label
            lab.here = function(lab)
                if lab.value then err('Value already defined to $%04X', lab.value) end
                lab.value = self.curAddress
                return self
            end
            self.labelsDict[label] = lab
            table.insert(self.labels, lab)
        end
        return lab
    end

    function asm.rem(self, ...)
        self.curSection:add(0, string.format(...))
        return self
    end

    function asm.REM(self, ...)
        if type(self.curSection[#self.curSection])~="string" then
            self:rem('')
        end
        return self:rem(...)
    end

    function asm.fcb(self, ...)
        for _,v in ipairs({...}) do
            if type(v)=='string' then v=v:byte() end
            if v<-128 or v>255 or v~=math.floor(v) then err('Not a byte: %g', v) end
            self.curSection:add(1, v)
        end
        return self
    end

    function asm.fdb(self, ...)
        for _,v in ipairs({...}) do
            if type(v)=='number' then
                if v<-32768 or v>65535 or v~=math.floor(v) then err('Not a word: %g', v) end
                v = {v}
            elseif type(v)=='string' then
                v = self:lbl(v)
            end
            self.curSection:add(2, v)
        end
        return self
    end

    function asm.asm(self, pr)
        local labels = {}
        for _,v in pairs(self.labels) do
            if labels[v.value] then
                table.insert(labels[v.value], v)
            else
                labels[v.value] = {v}
            end
        end

        for _,s in ipairs(self.sections) do
            s:asm(pr, labels)
        end
        return self
    end

    function asm.bin(self)
        local bin=''
        for _,s in ipairs(self.sections) do
            bin = bin .. s:bin()
        end
        bin = bin .. string.char(255,0,0,0x00,0x00)
        return bin
    end

    function asm.savem(self,name)
        local out = io.open(name,"wb")
        out:write(self:bin())
        out:close()
        return self
    end
	
	function asm.merge(self)
		local tab1, tab2, bank = {},{}
		for _,s in ipairs(self.sections) do
			if s.org==0xE7E5 then bank=true end
			if bank then
				table.insert(tab2,s)
			else
				table.insert(tab1,s)
			end
		end
		table.sort(tab1, function(a,b)
			return a.org<b.org
		end)
		for i=#tab1,2,-1 do
			local a,b = tab1[i-1],tab1[i]
			if a.org+a.len < b.org and a.org + a.len + 256 > b.org then
				a:add(0,'padding')
				while a.org+a.len<b.org do
					a:fcb(0)
				end
			end
			if a.org + a.len == b.org then
				if b==self.curSection then
					self.curSection=a
				end
				for _,t in ipairs(b) do
					table.insert(a, t)
				end
				a.len = a.len + b.len
				table.remove(tab1,i)
			end
		end
		for _,s in ipairs(tab2) do
			table.insert(tab1, s)
		end
		self.sections = tab1
		
		return self
	end
		
    return asm
end

----------------------------------------------------------------------------------------------

function patternSection()
    -- optimizing pattern sections inspire by LZW
    -- https://fr.wikipedia.org/wiki/Lempel-Ziv-Welch

    local ps = {
        record=true,
        wait={},
        defined={}
    }

    function ps.printTable(tbl,format)
        local size = 0
        format=format or "$%02x"
        local t,s='',' fcb '
        for _,v in ipairs(tbl) do
            if type(v)~="number" then
                if v:match(' fdb ') then size=size+2 end
                print(t..v)
                t = ''; s=' fcb '
            else
                local a=string.format(format, v)
                local b=t..s..a; s=','
                if b:len()>=40 then
                    print(t)
                    b = ' fcb '..a
                end
                t=b
                size = size + 1
            end
        end
        if t:len()>0 then print(t) end
        return size
    end

    function ps.libName(no)
        return string.format('LIB%03d',no)
    end

    function ps.add(arg)
        if ps.record then
            table.insert(ps, arg)
        end
    end

    function ps.writeTo(asm)
        if thomson.compress and #ps>20 then
            ps.compress()
        end

        local size = 0
        for _,v in ipairs(ps) do
            if type(v)=="table" then
                if v[1]=='call' then
                    asm:fdb{v[2],'-','song'}
                else
                    for _,x in ipairs(v) do
                        if type(x)=='number' then
                            asm:fcb(x)
                        else
                            asm:rem(x)
                        end
                    end
                end
            elseif type(v)=='string' then
                if v:byte()==42 then
                    asm:REM(v:sub(3))
                else
                    asm:lbl(v):here()
                end
            else
                error('Unexpected '..type(v))
            end
        end
        return size
    end


    function ps.patternName(no)
        return string.format("PAT%02d",no-1)
    end

    function ps.newPattern(no)
		for i=1,4 do
			thomson.chl[i].prev.vol = nil
			-- thomson.chl[i].prev.frq = nil
		end
        local function closePreviousPattern()
            ps.add({0})
            thomson.cur = nil
        end
        if not ps.defined[no] then
            ps.record = true
            ps.defined[no] = true
            if #ps>0 then
                closePreviousPattern()
            end
            ps.add(ps.patternName(no))
        else
            ps.record = false
            closePreviousPattern()
        end
    end

    function ps.printf(...)
        ps.add(string.format(...))
    end

    function ps.clear()
        for i in ipairs(ps) do
            ps[i] = nil
        end
    end

    function ps.compress()
        local dict={
            get=function(self,arg)
                local k = arg
                if type(arg)=="table" then
                    k = ""
                    for _,v in ipairs(arg) do
                        if type(v)~="number" then
                            k=k..v
                        else
                            k=k..string.char(v)
                        end
                    end
                end
                local v=self[k]
                if not v then
                    v = arg
                    self[k] = arg
                end
                return v
            end
        }
        dict.ZERO = dict:get{0}

        -- get tab with unique index
        local data={}
        for i=1,#ps do data[i] = dict:get(ps[i]) end

        local function code_size(start,len)
            local z=0
            for i=start,start+len-1 do
                if type(data[i])=='table' then
                    if not data[i].size then
                        local z=0
                        if data[i][1]=='call' then
                            z=2
                        else
                            for _,v in ipairs(data[i]) do
                                if type(v)=='number' then
                                    z=z+1
                                end
                            end
                        end
                        data[i].size = z
                    end
                    z = z + data[i].size
                end
            end
            return z
        end

        local function code_hash(start,len)
            local z=''
            for i=start,start+len-1 do
                if type(data[i])=='table' then
                    if not data[i].hash then
                        local z=''
                        for _,v in ipairs(data[i]) do
                            if type(v)=='string' then
                                z=z..v
                            else
                                z=z..string.char(v)
                            end
                        end
                        data[i].hash = z
                    end
                    z = z..data[i].hash
                end
            end
            return z
        end


        local libNo=0
        local ok = true
        while ok do
            ok = false
            printf("\r                                         \rCompressing: %d", code_size(1,#data))

            local lib={}
            data.n = #data
            local alloc = {}
            for i=1,data.n do alloc[i]=0 end

            printf('.')
            local t={}
            for i=1,data.n do t[i] = i end
            t.n=data.n
            table.sort(t, function(i,j)
                while data[i] and data[i]==data[j] do
                    i=i+1; j=j+1
                end
                return (code_hash(i,1)<code_hash(j,1))
            end)

            local pfx_cache = {n=0}
            local function pfx(s,t,lim)
                -- returns the prefix length for both index
                if s==t then return data.n-s end
                if not lim then lim=data.n end -- a bit too much but no impact
                
                local k=s..'_'..t..'_'..lim
                if not pfx_cache[k] then    
                    -- printf("%s\n",k)
                    local i=0
                    while data[s+i]==data[t+i] and i<=lim do
                        i=i+1
                    end
                    pfx_cache.n = pfx_cache.n + 1
                    if pfx_cache.n>1000 then pfx_cache = {n=1} end
                    pfx_cache[k] = i
                end
                return pfx_cache[k]
            end

            local function occurs(s,l,i)
                -- returns the list of offsets where
                -- substring s[1..l] occurs
                while i<t.n and pfx(s,t[i+1],l)>=l do i=i+1 end
                local r={}
                while i>=1 and pfx(s,t[i],l)>=l do
                    table.insert(r, t[i])
                    i=i-1
                end
                table.sort(r)
                -- remove overlapping elements
                i=1
                while r[i+1] do
                    if r[i]+l-1>=r[i+1] then
                        table.remove(r,i+1)
                    else
                        i=i+1
                    end
                end
                return r
            end

            printf(".")
            local gain,last,precalc={},'',{}
            for i=1,t.n-1 do
                local deb = t[i]
                local len = pfx(deb,t[i+1])
                if data[deb+len-1]==dict.ZERO then len=len-1 end
                local k  = code_hash(deb,len)
                local cz = code_size(deb,len)
                if -- cz>2+2+2 and
                    len>1 and
                    last~=k then
                    last = k
                    local o = occurs(deb,len,i)
                    local g = cz*#o - (cz + 1 + 2*#o)
                    if g>0 then
                        ok = true
                        gain[i] = g
                        precalc[i] = {deb,len,o}
                    end
                end
            end

            if ok then
                ok = false
                printf('.')
                local ordered = {}
                for i in pairs(gain) do table.insert(ordered,i) end
                table.sort(ordered, function(a,b)
                    if gain[b]<gain[a] then
                        return true
                    elseif gain[b]==gain[a] then
                        return b<a
                    else
                        return false
                    end
                end)

                printf('.')
                for _,i in ipairs(ordered) do
                    local deb,len,o = table.unpack(precalc[i])
                    local used = 0
                    for _,k in ipairs(o) do
                        for j=0,len-1 do
                            if alloc[k+j]~=0 then used=1 end
                        end
                    end
                    if used==0 then
                        ok = true
                        libNo = libNo+1
                        for _,k in ipairs(o) do
                            for j=0,len-1 do
                                alloc[k+j]=2*libNo
                            end
                            alloc[k] = alloc[k]+1
                        end
                        table.insert(lib, ps.libName(libNo))
                        for j=0,len-1 do
                            table.insert(lib, data[deb+j])
                        end
                        table.insert(lib,dict.ZERO)
                    end
                end
            end
            for i=data.n,1,-1 do
                if (alloc[i]%2)==1 then
                    local libNo = math.floor(alloc[i]/2)
                    data[i] = dict:get{"call",ps.libName(libNo)}
                elseif alloc[i]>0 then
                    table.remove(data,i)
                end
            end
            for _,v in ipairs(lib) do table.insert(data,v) end
            printf("\r                                         \rCompressing: %d",code_size(1,#data))
        end
        printf('\r                                         \r')

        -- write compressed text
        for i=#ps,1,-1 do ps[i]=nil end
        for i=1,#data do ps[i]=data[i] end

        return ps
    end

    return ps
end

----------------------------------------------------------------------------------------------

function none(arg) end

function thomson.reset()
    thomson.chl = {}
    for i=1,4 do
        thomson.chl[i] = {prev={vol=nil,frq=nil,smp=nil},
                          curr={vol=nil,frq=nil,smp=nil}}
    end

    thomson.smp2 = thomson.smp2 or {}

    thomson.ptn = patternSection()
    thomson.cur = nil

    return thomson
end
function thomson.vol(chan)
	-- ugly
	local k=mod.title=='blur' and currentPosition>=19 and 5 or 1
    -- important: use ceil otherwisr the low intenities can't be heard
	thomson.chl[chan].curr.vol = clamp(math.ceil(k*channels[chan].volume*thomson.volume/64),0,15)
    return thomson
end
function thomson.frq(chan)
    -- if(thomson.chl[chan].curr.frq==209) then error('xx') end
    thomson.chl[chan].curr.frq = math.floor(.5 + 256*ticksPerOutputSample/(channels[chan].ticksPerSample*channels[chan].sample.thomson.div))
    return thomson
end
function thomson.smp(chan)
    thomson.chl[chan].prev.smp = nil
    thomson.chl[chan].curr.smp = channels[chan].sample.no
    return thomson
end
function thomson.smpOffset(chan,no,offset)
    thomson.chl[chan].prev.smp = nil
    local t=no*256+offset
    if not thomson.smp2[t] then
        local free
        for i=1,mod.sampleCount do
            if mod.samples[i].length==0 then
                free=i
                break;
            end
        end
        if free==nil then
            mod.sampleCount = mod.sampleCount+1
            if mod.sampleCount>256 then
                error('No more free samples for offset')
            end
            free = mod.sampleCount
        end
        thomson.smp2[t] = free
        local name = mod.samples[free] and mod.samples[free].name
        mod.samples[free] = {
            no       = free,
            source   = mod.samples[no],
            offset   = offset*256,
            volume   = mod.samples[no].volume,
            finetune = mod.samples[no].finetune,
            thomson  = mod.samples[no].thomson, -- share thomson info
			getSample = function(pos)
				return mod.samples[no].getSample(pos+offset*256)
			end
        }
        mod.samples[free].name = (name and name..' ' or '')..' s:'..no..'+'..offset
    end
    thomson.chl[chan].curr.smp = thomson.smp2[t]
    return thomson
end
function thomson.delay(dly)
    if dly<=0 then return end
    if not thomson.compress and currentFrame==0 then -- debug
        thomson.ptn.add('* Row_'..(currentRow-1).. '_'..(currentPattern.no-1))
    end
    -- thomson.debug('* delay',dly,thomson.dly)
    local allFours = {1,2,3,4}
    if false and thomson.cur then -- strangely this doesn't help
        table.remove(allFours,    thomson.cur)
        table.insert(allFours, 1, thomson.cur)
    end
    for _,chl in ipairs(allFours) do
        local vol = thomson.chl[chl].curr.vol
        local frq = thomson.chl[chl].curr.frq
        local smp = thomson.chl[chl].curr.smp
        local volChg = thomson.chl[chl].prev.vol ~= vol
        local frqChg = thomson.chl[chl].prev.frq ~= frq
        local smpChg = thomson.chl[chl].prev.smp ~= smp

        if false then -- debug
            thomson.ptn.add('* c:'..chl..' '..(volChg and "vol" or "   ")
                                       ..' '..(frqChg and "frq" or "   ")
                                       ..' '..(smpChg and "smp" or "   ")
                                       ..' '..row[1]..' '..thomson.p_delay)
        end

        if frqChg then
            thomson.chl[chl].prev.frq = frq
            thomson.cur = chl
            if frq>0x7ff then 
                -- printf('Freq is too high ($%X) for channel %d, row %d, pat %d\n', frq, chl, currentRow, currentPattern.no) 
                frq=0x7ff
            end
            thomson.ptn.add{0x80 + 0x20 + (chl-1)*0x08 + math.floor(frq/256),  frq%256, 'c:'..chl..' f:'..frq}
        end
        if volChg or (thomson.cur~=chl and smpChg and not frqChg) then
            thomson.chl[chl].prev.vol = vol
            thomson.cur = chl
            thomson.ptn.add{0x80 + 0x40 + (chl-1)*0x10 + vol, 'c:'..chl..' v:'..vol}
        end
        if smpChg then
            thomson.chl[chl].prev.smp = smp
			thomson.chl[chl].curr.cpt = 0
            if smp>=16 then
                thomson.ptn.add{0x80 + 0x10,  smp, 's:'..smp}
            else
                thomson.ptn.add{0x80 + 0x10 + smp, 's:'..smp}
            end
        end
        -- stats
        channels[chl].sample.thomson.frq = channels[chl].sample.thomson.frq or {min=frq,max=frq}
        channels[chl].sample.thomson.frq.min = math.min(frq, channels[chl].sample.thomson.frq.min)
        channels[chl].sample.thomson.frq.max = math.max(frq, channels[chl].sample.thomson.frq.max)
    end
	
	if thomson.border then -- compute volume intensity
		local v=thomson.border.v or 0
		for t=1,dly*thomson.tempo do
			local z=0
			for _,chl in ipairs(thomson.chl) do
				if chl.curr.smp then
					local s=mod.samples[chl.curr.smp]
					local cpt=chl.curr.cpt or 0
					z = z + s.getSample(math.floor(.5+cpt))*chl.curr.vol/16
					chl.curr.cpt = cpt + s.thomson.div*chl.curr.frq/256
					if s.isRepeating and chl.curr.cpt>=s.length then
						chl.curr.cpt = s.repeatOffset
					end
				end
			end
			v = math.max(v, math.abs(z))
		end
		-- http://www.embedded.com/design/configurable-systems/4007653/DSP-Tricks-DC-Removal
		-- remove DC components
		local z,a = (thomson.border.z or 0),.95
		thomson.border.z = v*(1-a)+a*z
		v = v - z
		
		-- thomson.border.n = (thomson.border.n or 0) + dly*thomson.tempo*#thomson.chl
		thomson.border.t = (thomson.border.t or 0) + dly*thomson.tempo*thomson.period
		local period = 1000000/10 -- 10fps
		if thomson.border.t>=period then
			thomson.border.t = thomson.border.t - period
			-- v = (v/thomson.border.n)^.5
			-- thomson.border.n = 0

			v=math.abs(v)
			thomson.border.m = math.max(v,thomson.border.m or 1)
			v = v/thomson.border.m
			local z=math.min(15,math.floor(.5+v*15))
			if z~=thomson.border.p then
				thomson.ptn.add{0x80,z}
				thomson.border.p = z
			end
			v = 0
		end
		thomson.border.v = v
	end

    while dly>0 do
        if thomson.ptn.record and type(thomson.ptn[#thomson.ptn])=='table' then
            -- try to merge with previous
            local cmd = thomson.ptn[#thomson.ptn][1]

            while 0x81<=cmd and cmd<=0x8E and dly>0 do
                dly = dly-1
                cmd = cmd+1
                thomson.ptn[#thomson.ptn] = {cmd, 'd:'..(cmd%16)}
            end
        end
        if dly>0 then
            local t = dly>15 and 15 or dly
            thomson.ptn.add{0x80+t, 'd:'..t}
            dly = dly - t
        end
    end

    return thomson
end

local function play()
    resetPlayerData()

    loadPosition(1)

    thomson.playing = true
    while thomson.playing do
        local delay=0
        while ticksSinceStartOfFrame<ticksPerFrame do
            ticksSinceStartOfFrame = ticksSinceStartOfFrame + ticksPerOutputSample*thomson.tempo;
            delay=delay + 1
        end
        while ticksSinceStartOfFrame >= ticksPerFrame do
            doFrame();
            ticksSinceStartOfFrame = ticksSinceStartOfFrame - ticksPerFrame;
        end
        thomson.delay(delay)        
    end
end

-- collect statistics for optimizations
thomson.reset()
for _,sample in ipairs(mod.samples) do
    -- div so that c-5 gives 5000 bytes/sec
    -- sample.thomson = {div=thomson.div}
    sample.thomson = {div = ModPeriodTable[1+sample.finetune][25]/thomson.period}
    -- if sample.finetune==0 then sample.thomson.div = 2 end
    
    -- sample.thomson.div = sample.thomson.div*4/4.28 -- this improves he sound, but I don't know why
    
    local k=2 -- ^(1/12)
    while sample.thomson.div>=2 do
        sample.thomson.div = sample.thomson.div/k
    end
    -- while sample.thomson.div<thomson.div do
        -- sample.thomson.div=sample.thomson.div*k
    -- end
    -- printf("%g %d\n",sample.thomson.div, sample.finetune)
end
play()
thomson.reset()
thomson.ptn.clear()

-- print('ticksPerFrame='..ticksPerFrame)
-- print('ticksPerOutputSample='..ticksPerOutputSample)

thomson.asm=asmSection()
:org(thomson.org)
:rem('-------------------------------------')
:rem('MODULE     : %s', mod.title)
:rem('Identifier : %s', mod.identifier)
:rem('Channels   : %s', mod.channelCount)
:rem('Samples    : %s', mod.sampleCount)
:rem('Patterns   : %s', mod.patternCount)
:rem('Positions  : %s', mod.positionCount)
:rem('-------------------------------------')
for _,sample in ipairs(mod.samples) do
    thomson.asm:rem('%3d : %s', sample.no, sample.name)
end
thomson.asm
:rem('-------------------------------------')
:lbl('song'):here()
:fcb('M','0','D',0):rem('signature')
:fcb(0, thomson.period):rem('expected playback period')
:fdb{'instru','-','song'}:rem('intrument part')

-- RESET VOICE
:REM('reset all voices')
:fcb(0x80+0x40+0*16, 0x91, 0xA0+0*8, 0,
     0x80+0x40+1*16, 0x91, 0xA0+1*8, 0,
     0x80+0x40+2*16, 0x91, 0xA0+2*8, 0,
     0x80+0x40+3*16, 0x91, 0xA0+3*8, 0,
     0x90, 0, thomson.tempo)

-- collect statistics for optimizations
thomson.reset()
for _,sample in ipairs(mod.samples) do
    sample.thomson.frq = nil
end
play()

-- do the real translation
thomson.asm:REM('patterns')
for i=1,mod.positionCount do
    thomson.asm:fdb{thomson.ptn.patternName(mod.positions[i]),'-','song'}
end
if mod.positionLoopPoint>1 and mod.positionLoopPoint<=mod.positionCount then
	thomson.asm:REM('repeat point')
	for i=mod.positionLoopPoint,mod.positionCount do
		thomson.asm:fdb{thomson.ptn.patternName(mod.positions[i]),'-','song'}
	end
end
if thomson.loop>0 then
	thomson.asm:REM('looping')
	for j=1,thomson.loop do
		local start = mod.positionLoopPoint<=mod.positionCount and mod.positionLoopPoint or 1
		for i=start,mod.positionCount do
			thomson.asm:fdb{thomson.ptn.patternName(mod.positions[i]),'-','song'}
		end
	end
end
thomson.asm:fcb(0)

-- adjust individual sample div with the given quality
printf("Module title    : %s\n", mod.title)
do
    local function adjustDiv(quality)
        local size=0
        for _,sample in ipairs(mod.samples) do
            if sample.thomson.frq and not sample.source then
                local coef = 2 --^(1/12)
                local function subSample(k)
                    sample.thomson.div = sample.thomson.div*k
                    sample.thomson.frq.min = sample.thomson.frq.min/k
                    sample.thomson.frq.max = sample.thomson.frq.max/k
                end
                local length = sample.length
                if sample.isRepeating then
                    length = sample.repeatOffset + sample.repeatLength
                end
                -- samples played at a single-rate => 5khz
                if sample.thomson.frq.min==sample.thomson.frq.max then
                    subSample(math.max(sample.thomson.frq.min/math.floor(.5+quality), 1/sample.thomson.div))
                end
                
                -- ensure min is between quality and quality*2
                while sample.thomson.div>=coef and sample.thomson.frq.min<quality do
                    subSample(1/coef)
                end
                while sample.thomson.frq.min>=quality and sample.thomson.frq.max>=2*coef*quality do
                    subSample(coef)
                end
                
                -- too big samples (5000 samples, i.e. >2sec @ 128 quality) gets even more subs-sampled
                -- to get a reasonable size
                while true and length>=3*rate*sample.thomson.div do
                    subSample(coef)
                end
                
                -- too high freq is not allowed
                while sample.thomson.frq.max>=0x800 do
                    subSample(coef)
                end

                -- printf("len=%d %g %g %g->%g \n",.5+length/sample.thomson.div, sample.thomson.div, quality, sample.thomson.frq.min, sample.thomson.frq.max)
                -- sample.thomson.div = math.floor(sample.thomson.div)
                size = size+math.ceil(length/sample.thomson.div)
            end
        end
        return size
    end
    
    local size = adjustDiv(thomson.quality)
    if size>=40000 then -- need better precision
        local asm=asmSection():org(0)
        thomson.ptn.writeTo(asm)
        local totSize = 0xE000-thomson.org + 0xE000-0xA000
        local ptnSize = asm:size()
                        + mod.positionCount*(mod.positionLoopPoint<=mod.positionCount and 2 or 1)
                        + 8*mod.sampleCount
                        + 1024
        local smpSize = (totSize - ptnSize)*2
        printf("Total space     : %5d\n", totSize)
        printf("Pattern space   : %5d\n", ptnSize)
        printf("Available space : %5g\n", smpSize/2)
        local ok = true
        while ok do
            size = adjustDiv(thomson.quality)
            printf("Sample len @%-3d : %-5g\n", thomson.quality, size/2)
            if size<=smpSize then
                ok = false
            else
                thomson.quality = thomson.quality*((1/2)^(1/16))
            end
        end
    else
        printf("Sample len @%-3d : %-5g\n", thomson.quality, size/2)
    end
    thomson.quality = math.floor(.5 + thomson.quality)
end

-- reference for later use
thomson.instru = thomson.asm.maxAddress + 1
thomson.asm:org(math.max(thomson.asm.curSection.org + 256,thomson.instru + 8*mod.sampleCount))

-- reset freq stats
thomson.reset()
thomson.ptn.clear()
for _,sample in ipairs(mod.samples) do
    sample.thomson.frq = nil
end
play()
thomson.ptn.writeTo(thomson.asm)

-- non played patterns
for i=1,mod.positionCount do
    if not thomson.ptn.defined[mod.positions[i]] then
        thomson.asm:lbl(thomson.ptn.patternName(mod.positions[i])):here()
        thomson.asm:fcb(0):rem('not used')
    end
end

-- instrument data
local norm = 1/128;
if thomson.norm>0 then -- uses RMS to get louder sound
    local v,n=0,0
    for i=1,mod.sampleCount do
        local sample = mod.samples[i]
        if not sample.source then
            for p=0,sample.length-1,4 do
                local t=(sample.getSample(p)+sample.getSample(p+1)+sample.getSample(p+2)+sample.getSample(p+3))/4
                v = v + t^2
                n = n + 1
            end
        end
    end
    local rms = (v/n)^.5
    norm = thomson.norm/rms
           -- (3/4)^.5/rms
else
    local m=1
    for i=1,mod.sampleCount do
        local sample = mod.samples[i]
        if not sample.source then
            for p=0,sample.length-1,4 do
                local t=(sample.getSample(p)+sample.getSample(p+1)+sample.getSample(p+2)+sample.getSample(p+3))/4
                m = math.max(m, math.abs(t))
            end
        end
    end
    norm = 1/m
end

-- fill data for non derived samples
local function fillSampleData(sample)
    sample.thomson.data  = {}
    sample.thomson.rept  = nil

    if not sample.thomson.frq then return end --- not played sample

    -- real length of the sample
    local length = sample.length
    if sample.isRepeating then
        length = sample.repeatOffset + sample.repeatLength
    end
    
    local function getSample(x)
        -- this function aligns the signal so that the end and the repeat-point levels aligns to zero 0
        local offset,x0,y0,x1,y1
        if sample.isRepeating then
            if x<sample.repeatOffset then
                x0,x1=0,sample.repeatOffset-1
                y0,y1=0,sample.getSample(x1)
            else
                x0,x1=sample.repeatOffset,length-1
                y0,y1=sample.getSample(x0),sample.getSample(x1)
            end
        else
            x0,x1=0,length-1
            y0,y1=0,sample.getSample(x1)
        end
        if x>x1 then x=x1 end
        return sample.getSample(x)-(y0+(y1-y0)*(x-x0)/(x1-x0))
    end

    thomson.ptn.add('* sample'..sample.no.. ' div:'..sample.thomson.div..' range:'..sample.thomson.frq.min..'->'..sample.thomson.frq.max)

    -- generate the data for that sample
    local filter={
        -- sh11 of https://sourceforge.net/p/sox/code/ci/master/tree/src/dither.c#l211
        -0.9264228343963623,-0.98695987462997437,-0.631156325340271,-0.51966935396194458,
        -0.39738872647285461,-0.35679301619529724,-0.29720726609230042,-0.26310476660728455,
        -0.21719355881214142,-0.18561814725399017,-0.15404847264289856,-0.12687471508979797,
        -0.10339745879173279,-0.083688631653785706,-0.05875682458281517,-0.046893671154975891,
        -0.027950936928391457,-0.020740609616041183,-0.009366452693939209,-0.0060260160826146603
        
        -- shi08
        -- -1.202863335609436,-0.94103097915649414,-0.67878556251525879,-0.57650017738342285,
        -- -0.50004476308822632,-0.44349345564842224,-0.37833768129348755,-0.34028723835945129,
        -- -0.29413089156150818,-0.24994957447052002,-0.21715600788593292,-0.18792112171649933,
        -- -0.15268312394618988,-0.12135542929172516,-0.099610626697540283,-0.075273610651493073,
        -- -0.048787496984004974,-0.042586319148540497,-0.028991291299462318,-0.011869125068187714
        
        -- shi22
        -- 0.056581053882837296,-0.56956905126571655,-0.40727734565734863,-0.33870288729667664,
        -- -0.29810553789138794,-0.19039161503314972,-0.16510021686553955,-0.13468159735202789,
        -- -0.096633769571781158,-0.081049129366874695,-0.064953058958053589,-0.054459091275930405,
        -- -0.043378707021474838,-0.03660014271736145,-0.026256965473294258,-0.018786206841468811,
        -- -0.013387725688517094,-0.0090983230620622635,-0.0026585909072309732,-0.00042083300650119781
    }
    local ok,p,v,d,e=true,0,0,0,{}
    for i in ipairs(filter) do e[i]=0 end
    while ok do
        local b = getSample(p)*norm
        d = d + 1
        if d<sample.thomson.div then
            v = v + b
			-- if v>=0 and b>v or v<0 and b<v then
				-- v = b*sample.thomson.div
			-- end
        elseif false then -- mathematically correct but sounds weird by moments
            d = d - sample.thomson.div
            v = (v + b*(1-d))/sample.thomson.div
            if thomson.dither then
				if thomson.shaper then
					for i,k in ipairs(filter) do v = v - e[i]*k end
				end
                v = v + (math.random()/8-1/16)/2
            end
            v = clamp(v,-1,1)
            local w = math.floor(.5+7.5*(1+v))
            table.insert(sample.thomson.data,w)
            if thomson.shaper then
                e[#e]=nil
                table.insert(e,1,(w/8-1)-v)
            end
            v = b*d
            if p>=length then ok = false end
        else -- mathematically incorrect but sounds better most of the timess
            v = (v + b)/d
            if thomson.dither then
    			if thomson.shaper then
					for i,k in ipairs(filter) do v = v - e[i]*k end
				end
            v = v + (math.random()/8-1/16)
            end
            v = clamp(v,-1,1)
            local w = math.floor(.5+7.5*(1+v))
            table.insert(sample.thomson.data,w)
            if thomson.shaper then
                e[#e]=nil
                table.insert(e,1,(w/8-1)-v)
            end
            d = d-sample.thomson.div
            v = b*d
            if p>=length then ok = false end
        end
        if sample.isRepeating and not sample.thomson.rept and p==sample.repeatOffset then
            sample.thomson.rept=#sample.thomson.data
        end
        
        p = p + 1
        if p==length and sample.isRepeating and #sample.thomson.data<256
        then -- loop until we get at lease 256 values in the data
            p=sample.repeatOffset
        end
    end

    -- optim trim tail
    if not sample.isRepeating then
        local data = sample.thomson.data
        local last = #data
        while last>1 and data[last-1]==data[last] do
            data[last] = nil
            last = last - 1
        end
    end
end
-- get sample inversely sorted by their length
local sample_by_dec_len = {}
for i=1,mod.sampleCount do
    local sample = mod.samples[i]
    if not sample.source then
        fillSampleData(sample)
        table.insert(sample_by_dec_len, sample)
    end
end
table.sort(sample_by_dec_len, function(a,b) return #a.thomson.data>#b.thomson.data end)

-- perform sample allocation.
local i0,i1,samples_data,samples_data2=1,1,{},nil
local function allocate(sample,samples_data,failedCallback)
    local nibble = i0<=i1 and 1 or 16
    local i = nibble==1 and i0 or i1

    if not failedCallback or thomson.asm.maxAddress + i + #sample.thomson.data < 0xE000 then
        sample.thomson.nibble = nibble==1 and 0 or 1
        sample.thomson.start  = i-1
        sample.thomson.stop   = sample.thomson.start + #sample.thomson.data
        sample.thomson.rept   = sample.thomson.rept
                              and (sample.thomson.start + sample.thomson.rept)
                              or   sample.thomson.stop

        for _,v in ipairs(sample.thomson.data) do
            samples_data[i]=(samples_data[i] or 0)+v*nibble
            i=i+1
        end
        if nibble==1 then i0=i else i1=i end
    else
        failedCallback()
    end
end
for _,sample in ipairs(sample_by_dec_len) do
    allocate(sample, samples_data, function() samples_data2=true end)
end
if samples_data2 then
    i0,i1,samples_data2=1,1,{}
    for _,sample in ipairs(sample_by_dec_len) do
        if not sample.thomson.nibble then
            allocate(sample, samples_data2)
            sample.thomson.relocated = true
        end
    end
    if #samples_data2>16384 then
        printf("Warning, one extra bank not sufficient! Samples are overlapping. \n")
    end
end

-- set thomson parameters for derived instruments
for i=1,mod.sampleCount do
    local sample = mod.samples[i]
    if sample.source then
        local source = sample.source
        local delta  = math.floor(sample.offset/source.thomson.div)
        sample.thomson = {
            relocated = source.thomson.relocated,
            nibble    = source.thomson.nibble,
            start     = source.thomson.start + delta,
            stop      = source.thomson.stop,
            rept      = source.thomson.rept,
            div       = source.thomson.div,
            frq       = source.thomson.frq
        }
        -- a bit of sanity
        if sample.thomson.start > sample.thomson.stop then
            sample.thomson.start = sample.thomson.rept
        end
    end
end

-- output sample data
thomson.asm
:lbl('sample'):here()
for _,v in ipairs(samples_data) do
    thomson.asm:fcb(v)
end
-- output sample info
thomson.asm
:org(thomson.instru)
:lbl('instru'):here()
for i=1,mod.sampleCount do
    local sample = mod.samples[i]
    local len = sample.thomson.stop - sample.thomson.start
    local dat = function(val)
        return sample.thomson.relocated
               and {val,'-','song'}
                or {'sample','-','song','+',val}
    end
    if sample.thomson.frq then
        thomson.asm
        :fcb(i,sample.thomson.nibble)
        :fdb(dat(sample.thomson.start)):rem('s:%-3d  len=%d',i,len)
        :fdb(dat(sample.thomson.stop)):rem('div=%g',sample.thomson.div)
        :fdb(dat(sample.thomson.rept)):rem('frq=%d-->%d',sample.thomson.frq.min,sample.thomson.frq.max)
    else
        thomson.asm:fdb(0,0,0,0)    
    end
end
-- extra data
if samples_data2 then
    local bak = thomson.asm.maxAddress
    thomson.asm
    :org(0xE7E5):fcb(15)
    thomson.asm.maxAddress = bak
    for i,v in ipairs(samples_data2) do
        if i==0x0001 then
            thomson.asm:org(0xC000)
        elseif i==0x2001 then
            thomson.asm:org(0xA000)
        end
        thomson.asm:fcb(v)
    end
end

thomson.asm
:rem('')
:rem('-------------------------------------')
:rem('Converter : %s', arg[0])
:rem('     User : %s', os.getenv('USERNAME') or 'unknown')
:rem('     Date : %s', os.date("%c"))
:rem('With parameters')
thomson.instru=nil
thomson.cur=nil
thomson.org=nil
thomson.playing=nil
for k,v in pairs(thomson) do
    if type(v)=='number' then
        thomson.asm:rem('%9s : %g',k,v)
    end
    if type(v)=='string' then
        thomson.asm:rem('%9s : %s',k,v)
    end
    if v==true then
        thomson.asm:rem('%9s : true',k)
    end
    if v==false then
        thomson.asm:rem('%9s : false',k)
    end
end

thomson.asm
:rem('-------------------------------------')
:rem('END OF MODULE: %s', mod.title)
:rem('MAX  = $%04X', thomson.asm.maxAddress)
:rem('BANK = %s', samples_data2 and 'YES' or 'NO')
:rem('SIZE = $%04X (%d)',thomson.asm:size(),thomson.asm:size())
:rem('-------------------------------------')
:merge()
:savem(thomson.output)
if thomson.assembly then
	local f=io.open(thomson.assembly,'w')
	thomson.asm:asm(function(line) f:write((line or '')..'\n') end)
	f:close()
end

printf('Final size      : %gkb\n',math.floor((thomson.asm:size()+255)/256)/4)
printf("Need extra bank : %s\n", samples_data2 and 'YES' or 'NO')

if thomson.asm.maxAddress>=0xE000 or samples_data2 and #samples_data2>16384 then
    error(string.format('Size is too big (%d->$%04X)', thomson.asm:size(), thomson.asm.maxAddress))
end

