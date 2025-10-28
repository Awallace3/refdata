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

## Choose the file reader
source("reader_g16-simple.m");
# source("reader_g09-simple.m");
# source("reader_postg-simple.m");
# source("reader_d3-simple.m");
# source("reader_espresso-simple.m");
# source("reader_crystal-simple.m");
# source("reader_siesta-simple.m");
# source("reader_dftb+-simple.m");
# source("reader_sqm-simple.m");
# source("reader_orca-simple.m");
# source("reader_postg_psi4-simple.m");
 
## Source directory
data = {...
         "/home/alberto/calc/bsip-add/15_cbs/w4-11@blyp",...
         "/home/alberto/calc/bsip-add/15_cbs/gmtkn_bsr36@blyp",...
         "/home/alberto/calc/bsip-add/15_cbs/gmtkn_darc@blyp",...
         "/home/alberto/calc/bsip-add/15_cbs/gmtkn_bhperi@blyp",...
         "/home/alberto/calc/bsip-add/15_cbs/gmtkn_bh76@blyp",...
         "/home/alberto/calc/bsip-add/15_cbs/gmtkn_bh76@blyp",...
         "/home/alberto/calc/bsip-add/15_cbs/gmtkn_iso34@blyp",...
         "/home/alberto/calc/bsip-add/15_cbs/pa26@blyp",...
       };

## din files
din = {...
        "../10_din/w4-11.din",...
        "../10_din/gmtkn_bsr36-rev1.din",...
        "../10_din/gmtkn_darc-rev1.din",...
        "../10_din/gmtkn_bhperi-rev1.din",...
        "../10_din/gmtkn_bh76-rev1.din",...
        "../10_din/gmtkn_bh76rc-rev1.din",...
        "../10_din/gmtkn_iso34-rev1.din",...
        "../10_din/pa26.din",...
      };

#### Now DO stuff ####
warning("off");
format long;

## some checks
if (length(din) != length(data))
  error("Inconsistent lengths of the data and din cell arrays.")
endif
ndin = length(din);

for i = 1:ndin
  if (!exist(din{i},"file"))
    printf("Error! din file does not exist: %s\n",din{i})
    continue
  endif
  if (!exist(data{i},"dir"))
    printf("Error! data directory does not exist: %s\n",data{i})
    continue
  endif

  ## Process the outputs
  [n rxn opts] = load_din(din{i});
  [mad,md,rms,mapd,mpd,rmsp,maxad,maxadline,maxapd,maxapdline,elist,eref,lines,errfile] = process_din(n,rxn,data{i},0);

  ## Rewrite the din file header
  tok = strsplit(din{i},"/");
  name = tok{end};
  fidi = fopen(din{i},"r");
  fido = fopen(name,"w");
  while(!feof(fidi))
    line = strtrim(fgetl(fidi));
    if (isempty(line) || line(1:1) == "#" || strcmpi(line,"KCAL"))
      fprintf(fido,"%s\n",line);
    endif
  endwhile
  fclose(fidi);

  for j = 1:n
    for k = 1:length(rxn{j})-1
      if (mod(k,2) == 1) 
        fprintf(fido,"%d\n",rxn{j}{k});
      else
        fprintf(fido,"%s\n",rxn{j}{k});
      endif
    endfor
    fprintf(fido,"0\n");
    fprintf(fido,"%.10f\n",elist(j));
  endfor
  fclose(fido);
endfor
