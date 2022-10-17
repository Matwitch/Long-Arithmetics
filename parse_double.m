function result = parse_double(num)
    arguments
        num(1, 1) double
    end
    
    frac = bitand(bitshift(intmax('uint64'), -12), typecast(num, 'uint64')) + bitshift(1, 52);
    exp = bitshift(bitand(bitshift(bitshift(intmax('uint64'), 11 - 64), 64 - 12), typecast(num, 'uint64')), -52) - 1023;
    
    result = LongUInt()
    bitshift(frac, -52 + int64(exp))
end