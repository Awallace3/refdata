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

function [nrx rr] = load_din(file)

  nrx = 0;
  fid = fopen(file,"r");

  rr = {};
  while(!feof(fid))
    line = strtrim(fgetl(fid));
    if (isempty(line) || line(1:1) == "#" || strcmp(line,"KCAL"))
      continue
    endif
    if (strcmp(line,"-111"))
      break
    endif

    ### Read a reaction
    nrx = nrx + 1;
    r = {};
    nm = 0;
    while (!strcmp(line,"0"))
      nm = nm + 1;
      r{nm} = str2num(line);
      line = fgetl(fid);
      nm = nm + 1;
      r{nm} = line;
      line = fgetl(fid);
    endwhile
    line = fgetl(fid);
    nm = nm + 1;
    r{nm} = str2num(line);
    rr{end+1} = r;
  endwhile
  fclose(fid);

endfunction

