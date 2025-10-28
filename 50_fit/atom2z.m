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

function z = atom2z(symbol)

  ## atomic symbols
  atdb.symbols = ...
  {"H" , "HE", "LI", "BE", "B" , "C" , "N" , "O" , "F" , "NE", ...
   "NA", "MG", "AL", "SI", "P" , "S" , "CL", "AR", "K" , "CA", ...
   "SC", "TI", "V" , "CR", "MN", "FE", "CO", "NI", "CU", "ZN", ...
   "GA", "GE", "AS", "SE", "BR", "KR", "RB", "SR", "Y" , "ZR", ...
   "NB", "MO", "TC", "RU", "RH", "PD", "AG", "CD", "IN", "SN", ...
   "SB", "TE", "I" , "XE", "CS", "BA", "LA", "CE", "PR", "ND", ...
   "PM", "SM", "EU", "GD", "TB", "DY", "HO", "ER", "TM", "YB", ...
   "LU", "HF", "TA", "W" , "RE", "OS", "IR", "PT", "AU", "HG", ...
   "TL", "PB", "BI", "PO", "AT", "RN", "FR", "RA", "AC", "TH", ...
   "PA", "U" , "NP", "PU", "AM", "CM", "BK", "CF", "ES", "FM", ...
   "MD", "NO", "LR", "X", ...
   "N@", "B@", "R@", "C@" ...
  };

  [err,iz] = ismember(upper(symbol),atdb.symbols);
  if (err == 0)
    ssymbol = substr(upper(symbol),1,2);
    [err,iz] = ismember(ssymbol,atdb.symbols);
  endif
  if (err == 0)
    ssymbol = substr(ssymbol,1,1);
    [err,iz] = ismember(ssymbol,atdb.symbols);
  endif
  if (err == 0)
    error(strcat("mol_dbatom: atomic symbol ->", symbol, "<- not found!"));
  endif
  z = iz;

endfunction
