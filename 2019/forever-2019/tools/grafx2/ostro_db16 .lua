-- ostro_DB16.lua : converts a color image into a 
-- TO9 image (320x200x16 with color clashes) with
-- Dawn Bringer's palette using Ostromoukhov's error
-- diffusion algorithm.
--
-- Version: 21-apr-2018
--
-- Copyright 2016-2018 by Samuel Devulder
--
-- This program is free software; you can redistribute
-- it and/or modify it under the terms of the GNU
-- General Public License as published by the Free
-- Software Foundation; version 2 of the License.
-- See <http://www.gnu.org/licenses/>

run('lib/ostromoukhov.lua')

-- Color.NORMALIZE = .0001

OstroDither:new():dither40cols(function(w,h,getLinearPixel)
	local p=function(r,g,b) return b*256+g*16+r end
	local pal={
	p(0,0,0), p(1,0,1), p(0,1,3), p(5,1,0),
	p(1,3,0), p(7,7,2), p(15,1,1), p(2,5,15),
	p(15,5,0), p(14,10,0), p(5,7,9), p(15,10,8),
	p(3,15,15), p(15,15,2), p(1,1,1), p(15,15,15)}
	
	pal={
	p(0,0,0), p(1,0,1), p(0,1,3), p(5,1,0),
	p(1,3,0), p(7,7,2), p(15,1,1), p(2,5,15),
	p(15,5,0), p(14,10,0), p(2,3,4), p(8,4,3),
	p(1,6,7), p(8,8,1), p(1,1,1), p(9,11,8)}
	
	thomson.palette(0, pal)

	return pal
end)