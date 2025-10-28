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

function [mad,md,rms,mapd,mpd,rmsp,maxad,maxadline,maxapd,maxapdline,elist,eref,lines,errfile] = process_din(n, rxn, edir, verbose=0)

  hy2kcal=627.50947;

  errfile = struct();
  lines = cell(n,1);
  e = edisp = eref = elist = zeros(n,1);
  maxad = maxapd = -1;
  mad = md = rms = mapd = mpd = rmsp = maxadline = maxapdline = 0;
  for i = 1:n
    ncomp = floor((length(rxn{i})-1)/ 2);
    coef = emol = emold = zeros(1,ncomp);
    mol = cell(1,ncomp);
    for j = 1:ncomp
      coef(j) = rxn{i}{2 * j - 1};
      mol{j} = rxn{i}{2 * j};

      if (exist("namefile_req"))
        name = namefile_req(edir,mol{j});
      else
        name = {namefile(edir,mol{j})};
      endif

      for ifil = 1:length(name)
        if (!exist(name{ifil}))
          emold(j) = emol(j) = NaN;
          errfile = setfield(errfile,name{ifil},"Calc file/directory does not exist.");
          continue
        endif
      endfor

      name = namefile(edir,mol{j});
      [o1 o2 o3] = readenergy(name);
      if (isempty(o1) || isempty(o2) || isempty(o3) || isnan(o1) || isnan(o2) || isnan(o3))
        emold(j) = emol(j) = NaN;
        errfile = setfield(errfile,name,"Calc file/directory does not contain a valid energy.");
        continue
      endif
      emold(j) = o2;
      emol(j) = o3;
    endfor
    e(i) = (coef * emol') * hy2kcal;
    edisp(i) = coef * emold' * hy2kcal;
    eref(i) = rxn{i}{2*ncomp+1};

    ## print line
    ifirst = 0;
    line = "";
    for j = 1:ncomp
      if (coef(j) < 0)
	if (ifirst == 0)
	  ifirst = 1;
	else
	  line = sprintf("%s +",line);
	endif
	line = sprintf("%s %d %s",line,-coef(j),mol{j});
      endif
    endfor
    line = sprintf("%s ->",line);
    ifirst = 0;
    for j = 1:ncomp
      if (coef(j) > 0)
	if (ifirst == 0)
	  ifirst = 1;
	else
	  line = sprintf("%s +",line);
	endif
	line = sprintf("%s %d %s",line,coef(j),mol{j});
      endif
    endfor

    lines{i} = line;

    if (verbose)
      printf("%55s: %8.2f %8.2f (%7.2f) %8.2f (%7.2f)\n",line,eref(i),e(i),(e(i)-eref(i))/eref(i)*100,e(i)-edisp(i),(e(i)-edisp(i)-eref(i))/eref(i)*100);
    endif

    # maxad and maxapd
    if (abs(e(i)-eref(i)) > maxad) 
      maxad = max(maxad,abs(e(i)-eref(i)));
      maxadline = line;
    endif
    if (abs((e(i)-eref(i))/eref(i))*100 > maxapd) 
      maxapd = max(maxapd,abs((e(i)-eref(i))/eref(i))*100);
      maxapdline = line;
    endif

    elist(i) = e(i);
  endfor

  mad = [mean(abs(e-eref)) mean(abs(e-edisp-eref))];
  md = [mean(e-eref) mean(e-edisp-eref)];
  rms = [sqrt(mean((e-eref).^2)),sqrt(mean((e-edisp-eref).^2))];
  mapd = [mean(abs((e-eref)./eref)) * 100,mean(abs((e-edisp-eref)./eref)) * 100];
  mpd = [mean((e-eref)./eref) * 100,mean((e-edisp-eref)./eref) * 100];
  rmsp = [sqrt(mean(((e-eref)./eref).^2)) * 100,sqrt(mean(((e-edisp-eref)./eref).^2)) * 100];
endfunction
