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

## fit least squares to training data set
if (!exist("pin","var"))
  pin = [1.00, 1.46];
endif

xin = (1:length(dimers))';
yin = zeros(length(dimers),1);
for i = 1:length(dimers)
  yin(i) = getfield(be_ref,dimers{i});
endfor

ywt = 1./yin;
[yout pout cvg iter corp covp covr stdresid Z r2] = leasqr(xin,yin,pin,"f_for_fit",1e-11,2000,ywt);
