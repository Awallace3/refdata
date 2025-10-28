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

## globals
global hy2kcal e n xc z c6 c8 c10 c9 rc dimers mol1 mol2 be_ref active usec9

## molecule components of the dimers
mol1 = cell(length(dimers),1);
mol2 = cell(length(dimers),1);
for i = 1:length(dimers)
  mol1{i} = sprintf("%s_1",dimers{i});
  mol2{i} = sprintf("%s_2",dimers{i});
endfor

## collect the energies
e = struct();
active = zeros(length(dimers),1);
for id = 1:length(dir_e)
  ddir = dir_e{id};
  for i = 1:length(dimers);
    filed = namefile(ddir,dimers{i});
    file1 = namefile(ddir,mol1{i});
    file2 = namefile(ddir,mol2{i});
    if (exist(filed,"file") && exist(file1,"file") && exist(file2,"file"))
      e = setfield(e,dimers{i},readenergy(namefile(ddir,dimers{i})));
      e = setfield(e,mol1{i},readenergy(namefile(ddir,mol1{i})));
      e = setfield(e,mol2{i},readenergy(namefile(ddir,mol2{i})));
      active(i) = 1;
    endif
  endfor
endfor

## collect the geometries
xc = struct(); z = struct(); n = struct();
active2 = zeros(size(active));
for i = 1:length(dimers);
  filed = sprintf("%s/%s.xyz",dir_s,dimers{i});
  file1 = sprintf("%s/%s.xyz",dir_s,mol1{i});
  file2 = sprintf("%s/%s.xyz",dir_s,mol2{i});

  if (exist(filed,"file") && exist(file1,"file") && exist(file2,"file"))
    s = dimers{i};
    [xx,zz,nn] = readxyz(filed);
    xc = setfield(xc,s,xx);
    z = setfield(z,s,zz);
    n = setfield(n,s,nn);
    s = mol1{i};
    [xx,zz,nn] = readxyz(file1);
    xc = setfield(xc,s,xx);
    z = setfield(z,s,zz);
    n = setfield(n,s,nn);
    s = mol2{i};
    [xx,zz,nn] = readxyz(file2);
    xc = setfield(xc,s,xx);
    z = setfield(z,s,zz);
    n = setfield(n,s,nn);
    active2(i) = 1;
  endif
endfor
active = active2 & active;

## collect the coefficients and radii
c6 = struct(); c8 = struct(); c10 = struct(); rc = struct(); c9 = struct();
for i = 1:length(dimers);
  if (active(i) == 0) 
    continue
  endif
  for id = 1:length(dir_e)
    ddir = dir_e{id};

    filed = namefile(ddir,dimers{i});
    file1 = namefile(ddir,mol1{i});
    file2 = namefile(ddir,mol2{i});

    if (exist(filed,"file") && exist(file1,"file") && exist(file2,"file"))
      s = dimers{i};
      nn = getfield(n,s);
      [cc6,cc8,cc10,rrc,cc9] = readcij(namefile(ddir,s),nn);
      c6 = setfield(c6,s,cc6);
      c8 = setfield(c8,s,cc8);
      c10 = setfield(c10,s,cc10);
      rc = setfield(rc,s,rrc);
      if (usec9)
        c9 = setfield(c9,s,cc9);
      endif
      s = mol1{i};
      nn = getfield(n,s);
      [cc6,cc8,cc10,rrc,cc9] = readcij(namefile(ddir,s),nn);
      c6 = setfield(c6,s,cc6);
      c8 = setfield(c8,s,cc8);
      c10 = setfield(c10,s,cc10);
      rc = setfield(rc,s,rrc);
      if (usec9)
        c9 = setfield(c9,s,cc9);
      endif
      s = mol2{i};
      nn = getfield(n,s);
      [cc6,cc8,cc10,rrc,cc9] = readcij(namefile(ddir,s),nn);
      c6 = setfield(c6,s,cc6);
      c8 = setfield(c8,s,cc8);
      c10 = setfield(c10,s,cc10);
      rc = setfield(rc,s,rrc);
      if (usec9)
        c9 = setfield(c9,s,cc9);
      endif
      break
    endif
  endfor
endfor

# reconstruct dimers, mol1 and mol2
nn = sum(active);
adimers = dimers; dimers = cell(nn,1);
amol1 = mol1; mol1 = cell(nn,1);
amol2 = mol2; mol2 = cell(nn,1);

kk = 0;
for i = 1:length(adimers)
  kk = kk + 1;
  if (active(i))
    dimers{kk} = adimers{i};
    mol1{kk} = amol1{i};
    mol2{kk} = amol2{i};
  else
    kk = kk - 1;
  endif
endfor
clear adimers amol1 amol2
