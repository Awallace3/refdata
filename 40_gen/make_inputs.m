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

# x40  x40x10

din="../10_din/x40x10.din";
src="../20_x40x10/";
template="templates/g09-cp.gjf";
target="gen/";

#### End of input block. ####

keywords={"%q%","%m%","%geometry%","%geometry:cp%","%gaussian:cp%"};

## Read the din file
if (!exist(din,"file"))
  error(sprintf("Din file not found: %s",din))
endif
source("load_din.m");
[n rxn] = load_din(din);

## Check that the template exists.
if (!exist(template,"file"))
  error(sprintf("Template not found: %s",template))
endif

## Parse the extension
ext = template(index(template,".","last")+1:end);

## First collect all the names and verify that none are missing
dat = struct();
for i = 1:n
  for j = 2:2:length(rxn{i})
    if (!isfield(dat,rxn{i}{j}))
      file = strcat(src,rxn{i}{j},".xyz");
      if (!exist(file,"file"))
        error(sprintf("File not found: %s",file))
      endif

      ## Read the molecule
      mol = mol_readxyz(file);

      ## Interpret charge and multiplicity
      xx = str2num(mol.name);
      if (isempty(xx) || length(xx) != 2)
        mol.q = 0; mol.m = 1;
      else
        mol.q = xx(1); mol.m = xx(2);
      endif
      if (mol.nat == 0)
        error(sprintf("No atoms found in file: %s",file))
      endif
      smol = mol_burst(mol);
      smol = {mol smol{:}};
      dat = setfield(dat,rxn{i}{j},smol);
      printf("| %d-%d | %s | %d |\n",i,j,rxn{i}{j},length(smol)-1);
    endif
  endfor
endfor

## Process the template
fid = fopen(template,"r");
nline = 0;
line = {};
process = {};
while (!feof(fid))
  nline++;
  line0{nline} = fgetl(fid);
  process{nline} = find(index(line0{nline},keywords));
endwhile
fclose(fid);

## Generate the inputs
names = fieldnames(dat);
for i = 1:length(names)
  file = sprintf("%s%s.%s",target,names{i},ext);
  fid = fopen(file,"w");
  mol = getfield(dat,names{i});
  line = line0;
  for j = 1:nline
    if (!any(process{j}))
      ## do nothing
    else
      if (index(line{j},"%q%"))
        line{j} = strrep(line{j},"%q%",sprintf("%d",mol{1}.q));
      endif
      if (index(line{j},"%m%"))
        line{j} = strrep(line{j},"%m%",sprintf("%d",mol{1}.m));
      endif
      if (index(line{j},"%gaussian:cp%"))
        if (length(mol) > 2)
          line{j} = strrep(line{j},"%gaussian:cp%",sprintf("counterpoise=%d",length(mol)-1));
        else
          line{j} = strrep(line{j},"%gaussian:cp%","");
        endif
      endif
      if (index(line{j},"%geometry:cp%"))
        if (mol{1}.q != 0 || mol{1}.m != 1)
          warning(sprintf("Wrong charge multiplicity in input: %s",file))
        endif
        if (length(mol) > 2)
          for im = 2:length(mol)
            for k = 1:mol{im}.nat
              fprintf(fid,"%s(fragment=%d) %.10f %.10f %.10f\n",mol{im}.atname{k},im-1,mol{im}.atxyz(:,k));
            endfor
          endfor
        else
          for k = 1:mol{1}.nat
            fprintf(fid,"%s %.10f %.10f %.10f\n",mol{1}.atname{k},mol{1}.atxyz(:,k));
          endfor
        endif
        continue
      endif
      if (index(line{j},"%geometry%"))
        for k = 1:mol{1}.nat
          fprintf(fid,"%s %.10f %.10f %.10f\n",mol{1}.atname{k},mol{1}.atxyz(:,k));
        endfor
        continue
      endif
    endif
    fprintf(fid,"%s\n",line{j});
  endfor
  fclose(fid);
endfor

