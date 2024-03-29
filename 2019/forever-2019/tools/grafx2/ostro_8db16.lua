-- ostro_8db16.lua : convert a color image to a BM16
-- (160x200x16) thomson image using the Ostromoukhov's
-- error diffusion algorithm and Dawn Bringer's palette.
--
-- Version: 22-apr-2018
--
-- Copyright 2016-2018 by Samuel Devulder
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

-- Converts thomson coordinates (0-159,0-199) into screen coordinates
local function thom2screen(x,y)
	local i,j;
	if screen_w/screen_h < 1.6 then
		i = x*screen_h/200
		j = y*screen_h/200
	else
		i = x*screen_w/320
		j = y*screen_w/320
	end
	return math.floor(i*2), math.floor(j)
end

-- return the Color @(x,y) in normalized linear space (0-1)
-- corresonding to the thomson screen (x in 0-319, y in 0-199)
local function getLinearPixel(x,y)
	local x1,y1 = thom2screen(x,y)
	local x2,y2 = thom2screen(x+1,y+1)
	if x2==x1 then x2=x1+1 end
	if y2==y1 then y2=y1+1 end

	local p = Color:new(0,0,0);
	for j=y1,y2-1 do
		for i=x1,x2-1 do
			p:add(getLinearPictureColor(i,j))
		end
	end
	p:div((y2-y1)*(x2-x1)) --:floor()
	
	return p
end

-- BM16 mode
thomson.setBM16()

-- define palette
local p=function(r,g,b) return b*256+g*16+r end
local palette =	{
	p(0,0,0), p(1,0,1), p(0,1,3), p(5,1,0),
	p(1,3,0), p(7,7,2), p(15,1,1), p(2,5,15),
	p(15,5,0), p(14,10,0), p(2,3,4), p(8,4,3),
	p(1,6,7), p(8,8,1), p(1,1,1), p(9,11,8)}
thomson.palette(0, palette)

-- convert picture
OstroDither:new(palette)
           :dither(thomson.h,thomson.w,
             function(y,x) return getLinearPixel(x,y) end,
			 function(y,x,c) thomson.pset(x,y,c) end, 
			 true,
			 function(x) thomson.info("Converting...",math.floor(x*100/160),"%") end)

-- refresh screen
setpicturesize(320,200)
thomson.updatescreen()
finalizepicture()

-- save picture
thomson.savep()
