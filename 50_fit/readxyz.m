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

## function: read a xyz file
function [x,z,n] = readxyz(file)
  fid = fopen(file,"r");
  n = fscanf(fid,"%d","C");
  x = zeros(3,n); z = zeros(1,n);
  line = fgetl(fid);
  line = fgetl(fid);
  for i = 1:n
    [ss,x(1,i),x(2,i),x(3,i)] = fscanf(fid,"%s %f %f %f","C");
    z(i) = atom2z(ss);
  endfor
  x = x / .52917720859;
  fclose(fid);
endfunction
