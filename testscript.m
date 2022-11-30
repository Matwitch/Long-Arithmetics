A = [2 0 0 0; 2 3 2 0; 2 3 1 0; 2 3 1 4];
if A == tril(A)
  M = mean(A(:))
else
  v1 = A(A<3)
  d1 = v1(mod(v1, 2) == 0)
  v2 = A(A>2)
  d2 = v2(mod(v2, 2) == 1) 
end