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

function fit_report_full(pout,yin,yout)

  global hy2kcal e n xc z c6 c8 c10 c9 rc dimers mol1 mol2 be_ref active

  printf("# Parameters of the fit\n");
  printf(" a1 = %.8f || a2(ang) = %.8f\n\n",pout(1),pout(2))
  printf("\n# Statistics\n");
  printf(" Dataset size = %d\n",length(yin));
  printf(" MAD    = %.3f\n",mean(abs(yout-yin)));
  x = abs(yout-yin);
  i = find(x == max(x));
  printf(" MaxAD  = %.3f (%s)\n",max(abs(yout-yin)),dimers{i});
  printf(" RMS    = %.3f\n",sqrt(mean((yout-yin).^2)));
  printf(" MAPD   = %.3f\n",mean(abs((yout-yin)./yin))*100);
  x = abs((yout-yin)./yin);
  i = find(x == max(x));
  printf(" MaxAPD = %.3f (%s)\n",max(abs((yout-yin)./yin))*100,dimers{i});
  printf(" RMSP   = %.3f\n",sqrt(mean(((yout-yin)./yin).^2))*100);

  printf("\n# List of dimers\n");
  printf("#           dimer          Ref.      Calc.      Err.(%%) \n");
  for i = 1:length(yin)
    printf("%25s %10.3f %10.3f %10.2f\n",dimers{i},yin(i),yout(i),abs(yin(i)-yout(i))/yin(i)*100);
  endfor

  printf("\n# List of dimers (uncorrected DF)\n");
  printf("#           dimer          Ref.      Calc.      Err.(%%) \n");
  for i = 1:length(yin)
    dy = (getfield(e,mol1{i}) + getfield(e,mol2{i}) - getfield(e,dimers{i})) * hy2kcal;
    printf("%25s %10.3f %10.6f %10.2f\n",dimers{i},yin(i),dy,abs(yin(i)-dy)/yin(i)*100);
  endfor
endfunction
