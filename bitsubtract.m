function res = bitsubtract(num1, num2)
    res = bitadd(bitadd(num1, bitcomplement(num2)), uint64(1));
end