-- ostro_mo5xd.lua : converts a color image into a 
-- MO5 image (16 fixed colors with color clash) 
-- using Ostromoukhov's error diffusion algorithm
-- and W_oo_D SuperColor mode.
--
-- Version: 22-mar-2018
--
-- Copyright 2016-2018 by Samuel Devulder
--
-- This program is free software; you can redistribute
-- it and/or modify it under the terms of the GNU
-- General Public License as published by the Free
-- Software Foundation; version 2 of the License.
-- See <http://www.gnu.org/licenses/>

run('lib/ostromoukhov.lua')

local dither=OstroDither:new(nil, .95)

function dither:dither40cols(serpentine) 
	-- get screen size
	local screen_w, screen_h = getpicturesize()

	-- Converts thomson coordinates (0-319,0-199) into screen coordinates
	local function thom2screen(x,y)
		local i,j;
		if screen_w/screen_h < 1.6 then
			i = x*screen_h/200
			j = y*screen_h/200
		else
			i = x*screen_w/320
			j = y*screen_w/320
		end
		return math.floor(i), math.floor(j/2)*2
	end

	-- return the Color @(x,y) in linear space (0-255)
	-- corresonding to the thomson screen (x in 0-319, 
	-- y in 0-199)
	local function getLinearPixel(x,y)
		local with_cache = true
		if not self._getLinearPixel then self._getLinearPixel = {} end
		local k=x+y*thomson.w
		local p = self._getLinearPixel[k]
		if not p then
			local x1,y1 = thom2screen(x,y)
			local x2,y2 = thom2screen(x+1,y+1)
			if x2==x1 then x2=x1+1 end
			if y2==y1 then y2=y1+1 end

			p = Color:new(0,0,0);
			for j=y1,y2-1 do
				for i=x1,x2-1 do
					p:add(getLinearPictureColor(i,j))
				end
			end
			p:div((y2-y1)*(x2-x1)) --:floor()
						
			if with_cache then self._getLinearPixel[k]=p end
		end
		
		return with_cache and p:clone() or p
	end
		
	-- MO5 mode
	thomson.setMO5()
	
	--
	function self:ccAcceptCouple(c1,c2)
		return c1==1 -- only black background accepted
	end
	
	-- convert picture
	self:ccDither(thomson.w,math.floor(thomson.h/2),
				  function(x,y)
					p = Color:new(0,0,0)
					p:add(getLinearPixel(x,y*2));
					p:add(getLinearPixel(x,y*2+1));
					return p:map(function(x)
						return 1.2	*(1-math.exp(-x/Color.ONE/2))*Color.ONE --(1+x/(2*Color.ONE))
					end)
				  end,
				  function(x,y,c)
					if x%8==0 then
						thomson.pset(x,2*y+1,7)
						thomson.pset(x,2*y+1,-1)
						thomson.pset(x,2*y+0,-1)
					end
					if c>0 then
						thomson.pset(x,2*y,c)
					else
						thomson.pset(x,2*y,-c-1)
					end
				  end,
				  serpentine or true, function(y) 
					thomson.info("Converting...",
						math.floor(y*200/thomson.h),"%") 
				  end,true)

	-- refresh screen
	setpicturesize(thomson.w,thomson.h)
	thomson.updatescreen()
	thomson.savep()
	finalizepicture()
end



dither:dither40cols()