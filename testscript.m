n = 1024;
m = 10;
anyNum1 = num2cell(arrayfun(@(x) LongInt.parse_from_array(randuint64(1, x), randi([-1, 1], 1)), ...
            randi(m, 1, n)));

anyNum2 = num2cell(arrayfun(@(x) LongInt.parse_from_array(randuint64(1, x), randi([-1, 1], 1)), ...
            randi(m, 1, n)));



d1(n) = LongInt();
d2(n) = LongInt();

tic()
for i = 1:n
    if anyNum1{i}.sign ~= 0
        d1(i) = gcd(anyNum1{i}, anyNum2{i});
    end

    disp(i);
end
t1 = toc();

tic()
for i = 1:n
    if anyNum1{i}.sign ~= 0
        d1(i) = gcd_binary(anyNum1{i}, anyNum2{i});
    end

    disp(i);
end
t2 = toc();