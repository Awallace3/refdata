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
reader = {
          "reader_g16-simple.m",...
};

## Source directory
data = {...
         "/home/alberto/calc/chal336",...
       };

## din files
din = {...
        "../10_din/chal336.din",...
      };

## Separator character in the output
## sep="|";
sep=" ";
## sep=",";

#### Now DO stuff ####
warning("off");
format long;

## some checks
if (length(din) != length(data))
  error("Inconsistent lengths of the data and din cell arrays.")
endif
if (length(reader) != length(din))
  error("Inconsistent lengths of the reader and din cell arrays.")
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
  if (!exist(reader{i},"file"))
    printf("Error! reader script does not exist: %s\n",reader{i})
    continue
  endif
  source(reader{i});

  ## Process the outputs
  [n rxn opts] = load_din(din{i});
  [mad,md,rms,mapd,mpd,rmsp,maxad,maxadline,maxapd,maxapdline,elist,eref,lines,errfile] = process_din(n,rxn,data{i},0);

  ## First pass, reassign the lines based on the fieldasrxn option
  if (isfield(opts,"fieldasrxn") && !isempty(opts.fieldasrxn) && opts.fieldasrxn != 0)
    for j = 1:n
      ncomp = floor((length(rxn{j})-1)/ 2);
      if (opts.fieldasrxn == 999)
        str = rxn{j}{end};
      elseif (opts.fieldasrxn > 0)
        str = rxn{j}{2*opts.fieldasrxn};
      elseif (opts.fieldasrxn < 0)
        str = rxn{j}{2*ncomp+2+2*opts.fieldasrxn};
      endif
      lines{j} = str;
    endfor
  endif

  ## Second pass, calculate the maximum length
  maxlen = 12;
  for j = 1:n
    maxlen = max(maxlen,length(lines{j}));
  endfor

  #### Simple output, whole list
  printf("## din file: %s\n",din{i});
  printf("## data dir: %s\n",data{i});
  printf("## All results in kcal/mol.\n",din{i});
  printf("%s %*s %s %10s %s %10s %s \n",sep,maxlen,"Name",sep,"Ref.",sep,"Calc.",sep);
  for j = 1:n
    ncomp = floor((length(rxn{j})-1)/ 2);
    yref = rxn{j}{2*ncomp+1};
    printf("%s %*s %s %10.3f %s %10.3f %s\n",sep,maxlen,lines{j},sep,yref,sep,elist(j),sep);
  endfor
  printf("%s %*s %s      ---   %s %10.3f %s\n",sep,maxlen,"MAE",sep,sep,mad(1),sep);
  printf("%s %*s %s      ---   %s %10.3f %s\n",sep,maxlen,"ME",sep,sep,md(1),sep);
  printf("%s %*s %s      ---   %s %10.3f %s\n",sep,maxlen,"MAPE",sep,sep,mapd(1),sep);
  printf("%s %*s %s      ---   %s %10.3f %s\n",sep,maxlen,"MPE",sep,sep,mpd(1),sep);
  printf("%s %*s %s      ---   %s %10.3f %s\n",sep,maxlen,"RMS",sep,sep,rms(1),sep);
  printf("%s %*s %s      ---   %s %10.3f %s\n",sep,maxlen,"RMSP",sep,sep,rmsp(1),sep);

  ## List error files and partial MAE
  names = fieldnames(errfile);
  if (length(names) > 0)
    idx = find(!isnan(elist) & !isnan(eref));
    mad = mean(abs(elist(idx)-eref(idx)));
    md = mean(elist(idx)-eref(idx));
    rms = sqrt(mean((elist(idx)-eref(idx)).^2));
    mapd = mean(abs((elist(idx)-eref(idx))./eref(idx))) * 100;
    mpd = mean((elist(idx)-eref(idx))./eref(idx)) * 100;
    rmsp = sqrt(mean(((elist(idx)-eref(idx))./eref(idx)).^2)) * 100;

    printf("%s %*s %s      ---   %s %d %s\n",sep,maxlen,"n(part)",sep,sep,length(idx),sep);
    printf("%s %*s %s      ---   %s %10.3f %s\n",sep,maxlen,"MAE(part)",sep,sep,mad,sep);
    printf("%s %*s %s      ---   %s %10.3f %s\n",sep,maxlen,"ME(part)",sep,sep,md,sep);
    printf("%s %*s %s      ---   %s %10.3f %s\n",sep,maxlen,"MAPE(part)",sep,sep,mapd,sep);
    printf("%s %*s %s      ---   %s %10.3f %s\n",sep,maxlen,"MPE(part)",sep,sep,mpd,sep);
    printf("%s %*s %s      ---   %s %10.3f %s\n",sep,maxlen,"RMS(part)",sep,sep,rms,sep);
    printf("%s %*s %s      ---   %s %10.3f %s\n",sep,maxlen,"RMSP(part)",sep,sep,rmsp,sep);

    printf("## There were some errors:\n");
    for i = 1:length(names)
      printf("## %s : %s\n",names{i},getfield(errfile,names{i}));
    endfor
  endif
  printf("\n");
endfor
