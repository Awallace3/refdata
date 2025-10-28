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

## function: calculate the vdw energy of a single molecule
function e = energy(n,z,x,c6,c8,c10,rc,coef)

  nn = 0:10;
  fnn = 1./factorial(nn);

  e = 0;
  for i = 1:n
    for j = i+1:n
      d = norm(x(:,i)-x(:,j));
      a1 = coef(1);
      a2 = coef(2) / .52917720859;
      b = a1 / rc(i,j) + a2;

      summ = (b*d).^nn .* fnn;
      ee = exp(-b*d);
      f6 = 1 - sum(summ(1:7)) * ee;
      f8 = 1 - sum(summ(1:9)) * ee;
      f10 = 1 - sum(summ(1:11)) * ee;

      e -= f6 * c6(i,j) / d^6 + f8 * c8(i,j) / d^8 + f10 * c10(i,j) / d^10;
    endfor
  endfor
endfunction

