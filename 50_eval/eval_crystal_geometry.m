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

## name generator for reference
## name_ref = @(edir,tag) sprintf("%s/%s.cif",edir,tag);
name_ref = @(edir,tag) sprintf("%s/%s/%s.scf.out",edir,tag,tag);
## name_ref = @(edir,tag) sprintf("%s/%s/%s.STRUCT_OUT",edir,tag,tag);

## name generator for the sets to compare
## name_out = @(edir,tag) sprintf("%s/%s.cif",edir,tag);
## name_out = @(edir,tag) sprintf("%s/%s/%s.STRUCT_OUT",edir,tag,tag);
## name_out = @(edir,tag) sprintf("%s/%s/geo_end.gen",edir,tag);
name_out = @(edir,tag) sprintf("%s/%s/%s.out",edir,tag,tag);

## din file; first entry in each block is assumed to be a crystal and
## used. 
din = {...
        "../10_din/x23.din",...
        ## "../10_din/bleh.din",...
      };

## reference data
ref = {...
        ##"/home/alberto/git/refdata/20_x23/expt/",...
        "/home/alberto/calc/xdm_opt/15_x23_zerop/b86bpbe-xdm/",...
        ## "/home/alberto/calc/xdm_opt/15_x23_zerop/vdw-df2/",...
      };

## crystal data to compare
data = {...
         ## "/home/alberto/calc/xdm_opt/15_x23_zerop/siesta-vdw-df2-dzp/"
         ## "/home/alberto/calc/xdm_opt/15_x23_zerop/crystal-hfd2-minis-bsip4"
         ## "/home/alberto/calc/xdm_opt/15_x23_zerop/crystal-hfd2-minis-bsip7"
         "/home/alberto/calc/xdm_opt/50_newfit_test/fit1",...
       };
#### Now DO stuff ####
warning("off");
format long;

## some checks
if (length(din) != length(data))
  error("Inconsistent data and din lengths")
endif
if (length(din) != length(ref))
  error("Inconsistent ref and din lengths")
endif
ndin = length(din);

for i = 1:ndin
  ## the din file exists?
  if (!exist(din{i},"file"))
    error(sprintf("din file does not exist: %s",din{i}))
  endif

  ## read the din file and get the file name
  [n rxn] = load_din(din{i});
  xcomp = zeros(1,n);
  for j = 1:n
    name = rxn{j}{2};
    fileref = name_ref(ref{i},name);
    fileout = name_out(data{i},name);
    if (exist(fileref,"file") && exist(fileout,"file"))
      [s out] = system(sprintf("echo 'compare %s %s' | critic2 -q | grep '+ DIFF' | awk '{print $NF}'",...
                               fileref,fileout));
      dum = str2num(out);
      if (isempty(dum)) 
        error(sprintf("Failed command: echo 'compare %s %s' | critic2 -q | grep '+ DIFF' | awk '{print $NF}'",fileref,fileout))
      endif
      xcomp(j) = dum;
    else
      xcomp(j) = Inf;
    endif
  endfor  

  ## ## Only the average
  ## printf("| %s  | %.6f |\n",data{i},mean(xcomp));

  ## Simple output, whole list
  printf("## din file: %s\n",din{i});
  printf("## ref directory: %s\n",ref{i});
  printf("## data directory: %s\n",data{i});
  printf("| name | diff | \n");
  for j = 1:n
    printf("| %25s | %12.6f |\n",rxn{j}{2},xcomp(j));
  endfor
  printf("| Mean  | %.6f |\n",mean(xcomp));
endfor
