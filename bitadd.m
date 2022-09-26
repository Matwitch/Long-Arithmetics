function int1 = bitadd(int1, int2)
    while (int2 ~= 0)
        carry = bitand(int1, int2);
        int1 = bitxor(int1, int2);
        int2 = bitshift(carry, 1);
    end
end