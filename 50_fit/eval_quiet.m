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

## define the least-squares function
function y = f(x,p)

  global hy2kcal e n xc z c6 c8 c10 c9 rc dimers mol1 mol2 active

  y = zeros(size(x));
  for ii = 1:length(x)
    i = round(x(ii));
    nn = getfield(n,dimers{i});
    xx = getfield(xc,dimers{i});
    zz = getfield(z,dimers{i});
    cc6 = getfield(c6,dimers{i});
    cc8 = getfield(c8,dimers{i});
    cc10 = getfield(c10,dimers{i});
    rrc = getfield(rc,dimers{i});
    evdwd = energy(nn,zz,xx,cc6,cc8,cc10,rrc,p);
    nn = getfield(n,mol1{i});
    xx = getfield(xc,mol1{i});
    zz = getfield(z,mol1{i});
    cc6 = getfield(c6,mol1{i});
    cc8 = getfield(c8,mol1{i});
    cc10 = getfield(c10,mol1{i});
    rrc = getfield(rc,mol1{i});
    evdw1 = energy(nn,zz,xx,cc6,cc8,cc10,rrc,p);
    nn = getfield(n,mol2{i});
    xx = getfield(xc,mol2{i});
    zz = getfield(z,mol2{i});
    cc6 = getfield(c6,mol2{i});
    cc8 = getfield(c8,mol2{i});
    cc10 = getfield(c10,mol2{i});
    rrc = getfield(rc,mol2{i});
    evdw2 = energy(nn,zz,xx,cc6,cc8,cc10,rrc,p);

    y(i) = (getfield(e,mol1{i}) + evdw1 + getfield(e,mol2{i}) + evdw2 - getfield(e,dimers{i}) - evdwd) * hy2kcal;
  endfor
endfunction

xin = (1:length(dimers))';
yin = zeros(length(dimers),1);
for i = 1:length(dimers)
  yin(i) = getfield(be_ref,dimers{i});
endfor
yout = f(xin,pin);
pout = pin;
