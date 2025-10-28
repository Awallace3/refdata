#! /usr/bin/octave -q

# Copyright (c) 2015 Alberto Otero de la Roza <aoterodelaroza@gmail.com>
#
# refdata is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

[];

## function: give the name of the file
function file = namefile(edir,tag)
  file = sprintf("%s/%s.dat",edir,tag);
endfunction

## function: read the dispersion coefficients from qe output
function [c6,c8,c10,rc,c9] = readcij(file,n)

  c6 = zeros(n); c8 = zeros(n); c10 = zeros(n); rc = zeros(n); c9 = zeros(n,n,n);

  fid = fopen(file,"r");
  line = fgetl(fid);
  do 
     if(regexp(line,"coefficients and distances"));
       line = fgetl(fid); line = fgetl(fid);
       do
	 [ii,jj,ddum,c6dum,c8dum,c10dum,rcdum,rvdw] = sscanf(line,"%d %d %f %f %f %f %f %f","C");
	 c6(jj,ii) = c6(ii,jj) = c6dum; 
	 c8(jj,ii) = c8(ii,jj) = c8dum; 
	 c10(jj,ii) = c10(ii,jj) = c10dum; 
	 rc(jj,ii) = rc(ii,jj) = rcdum;
	 line = fgetl(fid);
       until (strcmp(deblank(line),"#"));
     elseif(regexp(line,"three-body dispersion coefficients"));
       line = fgetl(fid); line = fgetl(fid);
       do
	 [ii,jj,kk,c9dum] = sscanf(line,"%d %d %d %f","C");
	 c9(ii,jj,kk) = c9(kk,ii,jj) = c9(jj,kk,ii) = ...
         c9(jj,ii,kk) = c9(kk,jj,ii) = c9(ii,kk,jj) = c9dum; 
	 line = fgetl(fid);
       until (strcmp(deblank(line),"#"));
     endif
     line = fgetl(fid);
  until (!ischar(line) && (line == -1))
  fclose(fid);
endfunction

## function readenergy: read energy from nwchem output
function [e edisp etotal] = readenergy(file)
  [stat,out] = system(sprintf("grep '^ *Total Energy *=' %s | tail -n 1 | awk '{print $NF}' \n",file));
  if (length(out) == 0)
    e = 0;
  else
    e = str2num(out);
  endif
  [stat,out] = system(sprintf("grep 'dispersion energy' %s | tail -n 1 | awk '{print $NF}'\n",file));
  if (length(out) == 0)
    edisp = 0;
  else
    edisp = str2num(out);
  endif
  etotal = e;
  e = etotal - edisp;
endfunction


