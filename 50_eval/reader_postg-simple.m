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
  file = sprintf("%s/%s.pgout",edir,tag);
endfunction

## function readenergy: read energy from nwchem output
function [e edisp etotal] = readenergy(file)
  [stat,out] = system(sprintf("grep -a 'scf energy' %s | tail -n 1 | awk '{print $NF}' \n",file));
  if (length(out) == 0)
    e = 0;
  else
    e = str2num(out);
  endif
  [stat,out] = system(sprintf("grep -a 'dispersion energy' %s | tail -n 1 | awk '{print $NF}'\n",file));
  if (length(out) == 0)
    edisp = 0;
  else
    edisp = str2num(out);
  endif
  etotal = e + edisp;
endfunction


