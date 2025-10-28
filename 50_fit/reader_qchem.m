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
  file = sprintf("%s/%s.out",edir,tag);
endfunction

## function: read the dispersion coefficients from qe output
function [c6,c8,c10,rc,c9] = readcij(file,n)

  c6 = zeros(n); c8 = zeros(n); c10 = zeros(n); rc = zeros(n); c9 = zeros(n,n,n);

  fid = fopen(file,"r");
  num = 0;
  do 
    line = fgetl(fid);
    if(regexp(line,"D2X"))
      num++;
    endif
  until (!ischar(line) && (line == -1))
  fclose(fid);

  fid = fopen(file,"r");
  num0 = 0;
  do 
    line = fgetl(fid);
    if(regexp(line,"D2X"))
      num0++;
      if (num == num0)
        for ii = 0:n-2
          for jj = ii+1:n-1
	    line = fgetl(fid);
            if(regexp(line,"VDWBR"))
	      [s1,s2,c6dum,c8dum,c10dum,rdum,rcdum] = sscanf(line,"%s %s %f %f %f %f %f %f","C");
	      c6(jj+1,ii+1) = c6(ii+1,jj+1) = c6dum; 
	      c8(jj+1,ii+1) = c8(ii+1,jj+1) = c8dum; 
	      c10(jj+1,ii+1) = c10(ii+1,jj+1) = c10dum; 
	      rc(jj+1,ii+1) = rc(ii+1,jj+1) = rcdum;
            endif
          endfor
        endfor
      endif
    endif
  until (!ischar(line) && (line == -1))
  rc = rc * 2 / 0.52917720859;
  fclose(fid);

endfunction

## function readenergy: read energy from nwchem output
function [e edisp etotal] = readenergy(file)
  [stat,out] = system(sprintf("grep 'Convergence' %s | tail -n 1 | awk '{print $2}' \n",file));
  if (length(out) == 0)
    e = 0;
  else
    e = str2num(out);
  endif
  [stat,out] = system(sprintf("grep 'VDWBR' %s | grep HO | tail -n 1 | awk '{print $3}'\n",file));
  if (length(out) == 0)
    edisp = 0;
  else
    edisp = str2num(out);
  endif
  etotal = e + edisp;
endfunction


