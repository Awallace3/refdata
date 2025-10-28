#! /usr/bin/octave-cli -q

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
 
## din files
din = {...
        "../10_din/kb49.din",...
      };

## Separator character in the output
## sep="|";
sep=" ";
## sep=",";

#### Now DO stuff ####
warning("off");
format long;

ndin = length(din);

for i = 1:ndin
  if (!exist(din{i},"file"))
    printf("Error! din file does not exist: %s\n",din{i})
    continue
  endif

  ## Process the outputs
  [n rxn opts] = load_din(din{i});

  ## First pass, reassign the lines based on the fieldasrxn option
  if (isfield(opts,"fieldasrxn") && !isempty(opts.fieldasrxn) && opts.fieldasrxn != 0)
    for j = 1:n
      if (opts.fieldasrxn > 0)
        str = rxn{j}{2*opts.fieldasrxn};
      elseif (opts.fieldasrxn < 0)
        str = rxn{j}{end+1+2*opts.fieldasrxn};
      endif
      lines{j} = str;
    endfor
  else
    for j = 1:n
      ncomp = (length(rxn{j})-1)/2;
      ifirst = 0;
      line = "";
      for k = 1:ncomp
        coef = rxn{j}{2 * k - 1};
        mol = rxn{j}{2 * k};
        if (coef < 0)
	  if (ifirst == 0)
	    ifirst = 1;
	  else
	    line = sprintf("%s +",line);
	  endif
	  line = sprintf("%s %d %s",line,-coef,mol);
        endif
      endfor
      line = sprintf("%s ->",line);
      ifirst = 0;
      for k = 1:ncomp
        coef = rxn{j}{2 * k - 1};
        mol = rxn{j}{2 * k};
        if (coef > 0)
	  if (ifirst == 0)
	    ifirst = 1;
	  else
	    line = sprintf("%s +",line);
	  endif
	  line = sprintf("%s %d %s",line,coef,mol);
        endif
      endfor
      lines{j} = line;
    endfor
  endif

  ## Second pass, calculate the maximum length
  maxlen = 12;
  for j = 1:n
    maxlen = max(maxlen,length(lines{j}));
  endfor

  #### Simple output, whole list
  printf("## din file: %s\n",din{i});
  printf("%s %*s %s %10s \n",sep,maxlen,"Name",sep,"Ref.");
  for j = 1:n
    yref = rxn{j}{end};
    printf("%s %*s %s %10.3f\n",sep,maxlen,lines{j},sep,yref);
  endfor

  printf("\n");
endfor
