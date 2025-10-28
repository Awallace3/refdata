#! /usr/bin/octave -q

## define the least-squares function
function y = f_for_fit(x,p)

  global hy2kcal e n xc z c6 c8 c10 c9 rc dimers mol1 mol2 active usec9

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
    if (exist("c9","var") && usec9)
      cc9 = getfield(c9,dimers{i});
      evdwd = energy(nn,zz,xx,cc6,cc8,cc10,rrc,p,cc9);
    else
      cc9 = [];
      evdwd = energy(nn,zz,xx,cc6,cc8,cc10,rrc,p);
    endif
    nn = getfield(n,mol1{i});
    xx = getfield(xc,mol1{i});
    zz = getfield(z,mol1{i});
    cc6 = getfield(c6,mol1{i});
    cc8 = getfield(c8,mol1{i});
    cc10 = getfield(c10,mol1{i});
    rrc = getfield(rc,mol1{i});
    if (exist("c9","var") && usec9)
      cc9 = getfield(c9,mol1{i});
      evdw1 = energy(nn,zz,xx,cc6,cc8,cc10,rrc,p,cc9);
    else
      cc9 = [];
      evdw1 = energy(nn,zz,xx,cc6,cc8,cc10,rrc,p);
    endif
    nn = getfield(n,mol2{i});
    xx = getfield(xc,mol2{i});
    zz = getfield(z,mol2{i});
    cc6 = getfield(c6,mol2{i});
    cc8 = getfield(c8,mol2{i});
    cc10 = getfield(c10,mol2{i});
    rrc = getfield(rc,mol2{i});
    if (exist("c9","var") && usec9)
      cc9 = getfield(c9,mol2{i});
      evdw2 = energy(nn,zz,xx,cc6,cc8,cc10,rrc,p,cc9);
    else
      cc9 = [];
      evdw2 = energy(nn,zz,xx,cc6,cc8,cc10,rrc,p);
    endif

    y(i) = (getfield(e,mol1{i}) + evdw1 + getfield(e,mol2{i}) + evdw2 - getfield(e,dimers{i}) - evdwd) * hy2kcal;
  endfor
endfunction
