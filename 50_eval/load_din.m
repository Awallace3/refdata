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

function [nrx rr opts] = load_din(file)

  nrx = 0;
  fid = fopen(file,"r");
  fieldasrxn = 999;

  rr = {};
  while(!feof(fid))
    line = strtrim(fgetl(fid));
    if (length(line) > 1 && line(1:2) == "#@")
      tok = strsplit(line);
      if (strcmpi(tok{2},"fieldasrxn"))
        fieldasrxn = str2num(tok{3});
        if (isempty(fieldasrxn))
          fieldasrxn = 0;
        endif
      endif
      continue
    elseif (isempty(line) || line(1:1) == "#" || strcmpi(line,"KCAL"))
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
      r{nm} = strtrim(line);
      line = fgetl(fid);
    endwhile
    line = fgetl(fid);
    if (fieldasrxn == 999)
      [faux saux] = sscanf(line,"%f %s","C");
      nm = nm + 1;
      r{nm} = faux;
      nm = nm + 1;
      r{nm} = saux;
    else
      nm = nm + 1;
      r{nm} = sscanf(line,"%f","C");
    endif
    rr{end+1} = r;
  endwhile
  fclose(fid);

  opts = struct();
  opts.fieldasrxn = fieldasrxn;

endfunction

