-- ostro_40x200_mo5.lua : convert a color image to an
-- MO5 screen using only color attributes.
--
-- Version: 13-oct-2017
--
-- Copyright 2017 by Samuel Devulder
--
-- This program is free software; you can redistribute
-- it and/or modify it under the terms of the GNU
-- General Public License as published by the Free
-- Software Foundation; version 2 of the License.
-- See <http://www.gnu.org/licenses/>

run('lib/thomson.lua')
run('lib/ostromoukhov.lua')
	
-- get screen size
local screen_w, screen_h = getpicturesize()
local bk_w, bk_h = 8,1
local withPal = false
local attenuation=.95

-- Converts thomson coordinates (0-39,0-199) into screen coordinates
local function thom2screen(x,y)
	local i,j;
	if screen_w/screen_h < 1.6 then
		i = x*screen_h/200
		j = y*screen_h/200
	else
		i = x*screen_w/320
		j = y*screen_w/320
	end
	return math.floor(i*bk_w+.5), math.floor(j*bk_h+.5)
end

-- return the Color @(x,y) in normalized linear space (0-1)
-- corresonding to the thomson screen (x in 0-319, y in 0-199)
local norm=1
local function getLinearPixel(x,y)
	local x1,y1 = thom2screen(x,y)
	local x2,y2 = thom2screen(x+1,y+1)
	if x2==x1 then x2=x1+1 end
	if y2==y1 then y2=y1+1 end

	local p = Color:new(0,0,0)
	for j=y1,y2-1 do
		for i=x1,x2-1 do
			p:add(getLinearPictureColor(i,j))
		end
	end
	p:div((y2-y1)*(x2-x1)*norm) --:floor()
	
	return p
end

local max=0
for i=0,320/bk_w do
	for j=0,200/bk_h do
		local i=getLinearPixel(i,j):intensity()
		if i>max then max=i end
	end
end
norm=max/Color.ONE

local function pset(x,y,c)
	x=x*bk_w
	y=y*bk_h
	for j=y,y+bk_h-1 do
		for i=x,x+bk_w-1 do
			if bk_w==8 and i%8==0 then
				thomson.pset(i,j,-c-1)
				thomson.pset(i,j,c)
			elseif bk_w==4 then
				if i%8<4 then
					thomson.pset(i,j,c)
				elseif i%8==4 then
					thomson.pset(i,j,-c-1)
				end
			elseif bk_w==2 and i%2==0 then
				thomson.pset(i/2,j,c)
			end
		end
	end
end

-- gfx mode
if bk_w==2 then
	thomson.setBM16()
else
	thomson.setMO5()
end

if withPal then
	run('lib/color_reduction.lua')
	local palette = ColorReducer:new():analyzeWithDither(320/bk_w,200/bk_h,
		getLinearPixel,
		function(y)
			thomson.info("Collecting stats...",math.floor(100*y*bk_h/thomson.h),"%")
		end):boostBorderColors():buildPalette(16)
	thomson.palette(0, palette)
end

-- convert picture
local pal = {}
for i=0,15 do pal[i+1] = thomson.palette(i) end
OstroDither:new(pal,{bk_w,bk_h,bk_h,attenuation})
           :dither(200/bk_h,320/bk_w,
             function(y,x) return getLinearPixel(x,y) end, 
			 function(y,x,c) pset(x,y,c) end,
			 true,
			 function(x) thomson.info("Converting...",math.floor(x*100*bk_w/320),"%") end)

-- refresh screen
setpicturesize(320,200)
thomson.updatescreen()
finalizepicture()

-- save picture
thomson.savep()
