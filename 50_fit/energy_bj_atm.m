# Copyright (c) 2015 Alberto Otero de la Roza <alberto@fluor.quimica.uniovi.es>
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

## function: calculate the vdw energy of a single molecule
function e = energy(n,z,x,c6,c8,c10,rc,coef,c9=[])

  e = 0;
  for i = 1:n
    for j = i+1:n
      d = norm(x(:,i)-x(:,j));
      a1 = coef(1);
      a2 = coef(2) / .52917720859;
      rvdw = a1 * rc(i,j) + a2;
      
      e -= c6(i,j) / (rvdw^6 + d^6) + c8(i,j) / (rvdw^8 + d^8) + c10(i,j) / (rvdw^10 + d^10);
    endfor
  endfor
  if (!isempty(c9))
    for i = 1:n
      for j = i+1:n
        for k = j+1:n
          rij = (x(:,i)-x(:,j))';
          rik = (x(:,i)-x(:,k))';
          rjk = (x(:,j)-x(:,k))';
          dij = norm(rij);
          dik = norm(rik);
          djk = norm(rjk);
          ci = (rij * rik') / dij / dik;
          cj = -(rij * rjk') / dij / djk;
          ck = (rik * rjk') / dik / djk;

          f9 = (dij^6 / (rvdw^6 + dij^6)) * (dik^6 / (rvdw^6 + dik^6)) * (djk^6 / (rvdw^6 + djk^6));
          e += c9(i,j,k) * f9 * (1+3*ci*cj*ck) / (dij^3 * dik^3 * djk^3);
        endfor
      endfor
    endfor
  endif
endfunction

