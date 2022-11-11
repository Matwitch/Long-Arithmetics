classdef LongInt
    properties (Constant)
        arch_w_len = 64;
        arch_uint_t = 'uint' + string(LongInt.arch_w_len);
        arch_zero = cast(0, LongInt.arch_uint_t);
        arch_unit = cast(1, LongInt.arch_uint_t);
        arch_max_uint = intmax(LongInt.arch_uint_t);

        karatsuba_threshold = 4;
    end

    properties
        num(1, :) uint64
        sign(1, 1) int64
    end
    
    methods(Static, Access = public)
        function obj = from_hex(hex_str)
            arguments
                hex_str(1, :) char
            end

            s = 1;

            if hex_str(1) == '-'
                s = -1;
                hex_str = hex_str(2:end);
            end

            if mod(strlength(hex_str), 16) ~= 0
                q = strlength(hex_str) / 16;

                hex_str = [num2str(zeros(1, 16 * (floor(q) + 1) - strlength(hex_str)), '%d') hex_str];
            end

            num = zeros(1, strlength(hex_str) / 16, arch_uint_t);

            n = length(num);
            for i = n:-1:1
                k = arch_zero;
                hex = hex_str((i-1)*16+1:i*16);

                for j = 16:-1:1
                    k = bitor(k, bitshift(LongInt.hex2uint(hex(j)), (16 - j) * 4));
                end
                
                num(n - i + 1) = k;
            end
    
            obj = shrink_to_fit(LongInt.parse_from_array(num, s));
        end

        function res = parse_from_array(arr, a_sign)
            arguments
                arr uint64 {mustBeVector}
                a_sign(1,1) {mustBeInRange(a_sign, -1, 1)}
            end

            if a_sign == 0
                res = LongInt();
                return; 
            end

            res = LongInt();
            res.num = arr;
            res.sign = a_sign;
        end

        function h = uint2hex(n)
            arguments
                n(1, 1) uint64
            end

            h(16) = char('0');
            mask = cast(15, arch_uint_t);

            for i = 1:16
                a = bitshift(bitand(n, bitshift(mask, (i - 1) * 4)), (1 - i) * 4);
                
                if a < 10
                    h(i) = num2str(a);
                else
                    h(i) = cast(cast('A', 'uint64') + a - 10, 'char');
                end
            end

            h = flip(h);
        end
    end


    methods(Static, Access = private)
        function [A0, A1, B0, B1] = karatsuba_part(A, B)
            if A.nwords > B.nwords
                if mod(A.nwords, 2) ~= 0
                    n = A.nwords + 1;
                    A0 = LongInt.parse_from_array(A.num(1:(n/2)), 1);
                    A1 = LongInt.parse_from_array([A.num((n / 2) + 1:end) LongInt.arch_zero], 1);
                else
                    n = A.nwords;
                    A0 = LongInt.parse_from_array(A.num(1:(n / 2)), 1);
                    A1 = LongInt.parse_from_array(A.num((n / 2) + 1:end), 1);
                end
                
                temp = [B.num zeros(1, n - B.nwords, LongInt.arch_uint_t)];
                B0 = LongInt.parse_from_array(temp(1:(n/2)), 1);
                B1 = LongInt.parse_from_array(temp((n / 2) + 1:end), 1);
            else
                if mod(B.nwords, 2) ~= 0
                    n = b.nwords + 1;
                    B0 = LongInt.parse_from_array(B.num(1:(n/2)), 1);
                    B1 = LongInt.parse_from_array([B.num((n / 2) + 1:end) LongInt.arch_zero], 1);
                else
                    n = B.nwords;
                    B0 = LongInt.parse_from_array(B.num(1:(n / 2)), 1);
                    B1 = LongInt.parse_from_array(B.num((n / 2) + 1:end), 1);
                end
                
                temp = [A.num zeros(1, n - A.nwords, LongInt.arch_uint_t)];
                A0 = LongInt.parse_from_array(temp(1:(n/2)), 1);
                A1 = LongInt.parse_from_array(temp((n / 2) + 1:end), 1);
            end
        end

        function a = bits_to_uints(bits_num)
            a = ceil(double(bits_num) / LongInt.arch_w_len);
        end

        function obj = parse_from_double(num)
            arguments
                num(1, 1) double
            end

            obj = LongInt();

            if num == 0
                obj.num = LongInt.arch_zero;
                obj.sign = 0;
                return;
            end
            
            frac = bitand(bitshift(intmax(LongInt.arch_uint_t), -12), typecast(num, LongInt.arch_uint_t)) + bitshift(1, 52);
            exp = bitshift(bitand(uint64(9218868437227405312), typecast(num, LongInt.arch_uint_t)), -52) - 1023;

            if exp == 0
                 obj.num = cast(1, LongInt.arch_uint_t);
            else
                obj.num = zeros(1, LongInt.bits_to_uints(1 + uint64(exp)), LongInt.arch_uint_t);
                obj.num(1) = typecast(frac, LongInt.arch_uint_t);
                obj = bitshift(obj, -52 + int64(exp));
            end

            obj.sign = sign(num);
        end

        function n = hex2uint(c)
            arguments
                c(1, 1) char
            end
                
            a = cast(c, 'uint64');

            if  a <= cast('9', 'uint64') && a >= cast('0', 'uint64')
                n = cast(a - cast('0', 'uint64'), arch_uint_t);
            elseif a <= cast('F', 'uint64') && a >= cast('A', 'uint64')
                n = cast((a - cast('A', 'uint64')) + 10, arch_uint_t);
            else
                throw(MException('LongInt:wrongChar', ' ''%s'' is not a legit hexidecimal digit.', c));
            end
        end

        function result = digit_mult(A, B)
            A0 = bitshift(bitshift(A, LongInt.arch_w_len / 2), -(LongInt.arch_w_len / 2));
            A1 = bitshift(A, -(LongInt.arch_w_len / 2));

            B0 = bitshift(bitshift(B, LongInt.arch_w_len / 2), -(LongInt.arch_w_len / 2));
            B1 = bitshift(B, -(LongInt.arch_w_len / 2));
            
            result = LongInt();

            result.num(1) = B0 * A0;
            result.num(2) = B1 * A1;
            
            result = add_abs(result, bitshift(add_abs(LongInt(A1 * B0), LongInt(A0 * B1)), (LongInt.arch_w_len / 2)));
        end
    end

    methods(Access = public)
        function obj = LongInt(init_num)
            arguments
                init_num(1, 1) = LongInt.arch_zero
            end
            
            if isa(init_num, 'LongInt')
                obj = init_num;
            elseif isa(init_num, 'double')
                obj = LongInt.parse_from_double(init_num);
            elseif isinteger(init_num)
                obj.num = cast(abs(init_num), LongInt.arch_uint_t);
                obj.sign = sign(init_num);
            else
                throw(MException('LongInt:wrongType', 'Cannot construct LongInt from type: %s', class(init_num)));
            end
        end

        function result = bitshift(obj, k)
            arguments
                obj(1, 1) LongInt
                k(1, 1) {mustBeInteger(k)}
            end
            
            result = obj;
            carry_shift = 0;

            if k == 0
                return;
            end

            whole = floor(abs(double(k) / obj.arch_w_len));
            frac = mod(abs(k), obj.arch_w_len);

            if k > 0
                t = ceil(double(frac - (obj.nwords * obj.arch_w_len - abs(obj.msb_pos))) / ...
                    double(obj.arch_w_len));
                result.num = [zeros(1, whole, obj.arch_uint_t), result.num, zeros(1, t, obj.arch_uint_t)];
                
                if frac ~= 0
                    for i = 1:result.nwords
                        r = result.num(i);
                        result.num(i) = bitor(bitshift(r, frac), carry_shift);
                        carry_shift = bitshift(r, (frac - obj.arch_w_len));
                    end
                end
            else
                t = ceil(double(frac - (abs(obj.msb_pos) - (obj.nwords - 1) * obj.arch_w_len)) / ...
                    double(obj.arch_w_len));

                temp = result.num((whole + 1):result.nwords);
                if frac ~= 0
                    for i = length(temp):-1:1
                        r = temp(i);
                        temp(i) = bitor(bitshift(r, -frac), carry_shift);
                        carry_shift = bitshift(r, obj.arch_w_len - frac);
                    end
                end
                result.num = temp(1:end - t);
            end
        end

        function result = uminus(obj)
            result = obj;
            result.sign = -result.sign;
        end

        function result = abs(obj)
            result = obj;
            result.sign = 1;
        end

        function result = plus(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) LongInt
            end

            if obj2.sign == 0
                result = obj;
            elseif obj.sign == 0
                result = obj2;
            elseif obj.sign == obj2.sign
                result = add_abs(obj, obj2);
            elseif lt_abs(obj, obj2)
                result = sub_abs(obj2, obj);
            else
                result = sub_abs(obj, obj2);
            end
        end

        function result = minus(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) LongInt
            end
           
            if obj2.sign == 0
                result = obj;
            elseif obj.sign == 0
                result = obj2;
                result.sign = - result.sign;
            elseif obj.sign ~= obj2.sign
                result = add_abs(obj, obj2);
                result.sign = obj.sign;
            elseif lt_abs(obj, obj2)
                result = sub_abs(obj2, obj);
                result.sign = -result.sign;
            else
                result = sub_abs(obj, obj2);
            end
        end

        function result = mtimes(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) LongInt
            end
            
            if (obj.sign == 0) || (obj2.sign == 0)
                result = LongInt();
                return;
            end

            if obj.num == LongInt.arch_unit
                result = obj2;
            elseif obj2.num == LongInt.arch_unit
                result = obj;
            else
                result = mult_karatsuba_abs(obj, obj2);
                result = result.shrink_to_fit();
            end

            if obj.sign == obj2.sign
                result.sign = 1;
            else
                result.sign = -1;
            end
        end

        function [result, carry] = mrdivide(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) {mustBeArithmetic(obj2)}
            end

            result = LongInt(obj.num(1) / obj2.num(1));
            carry = false;
        end

        function [result, carry] = mpower(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) {mustBeArithmetic(obj2)}
            end

            result = LongInt(obj.num(1) / obj2.num(1));
            carry = false;
        end

        function pos = msb_pos(obj)
            arguments
                obj(1, 1) LongInt
            end

            n = obj.num(obj.nwords);
            m = bitand(n, bitcmp(bitsubtract(n, LongInt.arch_unit), LongInt.arch_uint_t));

            k = 0;
            while m ~= 0
                m = bitshift(m, -1);
                k = k + 1;
            end

            pos = (((obj.nwords - 1) * LongInt.arch_w_len) + k) * obj.sign;
        end

        function result = lt(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) LongInt
            end

            if obj.sign < obj2.sign
                result = true;
            elseif obj.sign > obj2.sign
                result = false;
            else
                if obj.sign == 1
                    result = lt_abs(obj, obj2);
                elseif obj.sign == -1
                    result = ~lt_abs(obj, obj2);
                else
                    result = false;
                end
            end

            
        end

        function result = eq(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) LongInt
            end

            result = isequal(obj.num, obj2.num) && isequal(obj.sign, obj2.sign);
        end
 
        function result = to_hex(obj)
            arguments
                obj(1, 1) LongInt
            end

            n = obj.nwords;

            result(16 * n) = char(1);

            for i = n:-1:1                
                result((i-1)*16+1:i*16) = LongInt.uint2hex(obj.num(n - i + 1));                
            end

            k = 1;
            while result(k) == '0'
                k = k + 1;
            end

            result = result(k:end);
        end
        
    end
    methods(Access = private)
        function n = nwords(obj)
            n = length(obj.num);
        end
        
        function result = mult_karatsuba_abs(obj, obj2)
            if min(obj.nwords, obj2.nwords) > LongInt.karatsuba_threshold
                [A0, A1, B0, B1] = LongInt.karatsuba_part(obj, obj2);
                
                C1 = mult_karatsuba_abs(A1, B1);
                C0 = mult_karatsuba_abs(A0, B0);
                C2 = sub_abs(sub_abs(mult_karatsuba_abs(add_abs(A0, A1), add_abs(B0, B1)), C1), C0);

                result = bitshift(C1, LongInt.arch_w_len * A0.nwords * 2)...
                    + bitshift(C2, LongInt.arch_w_len * A0.nwords) + C0;
            else
                result = mult_tbl_abs(obj, obj2);
            end
        end
        
        function result = mult_tbl_abs(obj, obj2)
            result = LongInt.parse_from_array(zeros(1, obj.nwords + obj2.nwords, LongInt.arch_uint_t), 1);

            i = 0;
            for a_i = obj.num
                j = 0;
                for b_j = obj2.num
                    result = add_abs(result, bitshift(LongInt.digit_mult(a_i, b_j), LongInt.arch_w_len * (i + j)));
                    j = j + 1;
                end
                i = i + 1;
            end
        end

        function result = add_abs(obj, obj2)
            carry_bit = LongInt.arch_zero;
            
            if obj2.nwords > obj.nwords
                result = obj2;
                n = obj.nwords;
            else
                result = obj;
                n = obj2.nwords;
            end

            for i = 1:n
                x = obj.num(i);
                y = obj2.num(i);
                result.num(i) = bitadd(bitadd(x, y), carry_bit);
                carry_bit = bitshift(bitor(bitand(x, y), bitand(bitxor(result.num(i), intmax(LongInt.arch_uint_t)), ...
                    bitor(x, y))), 1 - LongInt.arch_w_len);
            end
            i = i + 1;

            while carry_bit ~= 0 && i ~= result.nwords + 1
                result.num(i) = bitadd(result.num(i), 1);
                carry_bit = (result.num(i) == LongInt.arch_max_uint);
                i = i + 1;
            end

            if carry_bit ~= 0
                result.num = [result.num, LongInt.arch_zero];
                result.num(result.nwords) = 1;
            end
        end

        function obj = sub_abs(obj, obj2)
            borrow_bit = LongInt.arch_zero;

            for i = 1:obj2.nwords
                x = obj.num(i);
                y = obj2.num(i);
                obj.num(i) = bitsubtract(bitsubtract(x, y), borrow_bit);
                borrow_bit = bitshift(bitor(bitand(bitxor(x, LongInt.arch_max_uint), bitor(obj.num(i), y)), ...
                    bitand(y, obj.num(i))), 1 - LongInt.arch_w_len);
            end
            i = i + 1;

            while borrow_bit ~= 0 && i ~= obj.nwords + 1
                obj.num(i) = bitsubtract(obj.num(i), 1);
                borrow_bit = (obj.num(i) == 0);
                i = i + 1;
            end

            obj = shrink_to_fit(obj);
        end

        function result = bitshift_static(obj, k)
            arguments
                obj(1, 1) LongInt
                k(1, 1) {mustBeInteger(k)}
            end

            result = obj;
            carry_shift = 0;

            if k == 0
                return;
            end

            whole = floor(abs(double(k) / arch_w_len));
            frac = mod(abs(k), arch_w_len);
            n = result.nwords;

            if k > 0
                result.num = [zeros(1, whole, arch_uint_t), result.num(1:(n - whole))];

                for i = 1:n
                    r = result.num(i);
                    result.num(i) = bitor(bitshift(r, frac), carry_shift);
                    carry_shift = bitshift(r, (frac - arch_w_len));
                end
            else
                result.num = [result.num((whole + 1):n), zeros(1, whole, arch_uint_t)];

                for i = n:-1:1
                    r = result.num(i);
                    result.num(i) = bitor(bitshift(r, frac), carry_shift);
                    carry_shift = bitshift(r, arch_w_len - frac);
                end
            end
        end

        function obj = shrink_to_fit(obj)
            n = obj.nwords;
            zero = cast(0, LongInt.arch_uint_t);
            for i = n:-1:1
                if obj.num(i) ~= zero
                    obj.num = obj.num(1:i);
                    return;
                end
            end
            obj = LongInt(zero);
        end

        function r = lt_abs(obj, obj2)
            if obj.nwords < obj2.nwords
                r = true;
            elseif obj.nwords > obj2.nwords
                r = false;
            else
                for i = obj.nwords:-1:1
                    if obj.num(i) < obj2.num(i)
                        r = true;
                        return;
                    elseif obj.num(i) > obj2.num(i)
                        r = false;
                        return;
                    end
                end
                r = false;
            end
        end
    end
end

function res = bitsubtract(num1, num2)
    res = bitadd(bitadd(num1, bitcmp(num2)), 1);
end

function int1 = bitadd(int1, int2)
    while (int2 ~= 0)
        carry = bitand(int1, int2);
        int1 = bitxor(int1, int2);
        int2 = bitshift(carry, 1);
    end
end