classdef LongInt < handle & matlab.mixin.CustomDisplay
    properties (Constant)
        arch_w_len = 64;
        arch_uint_t = 'uint' + string(LongInt.arch_w_len);
        arch_zero = cast(0, LongInt.arch_uint_t);
        arch_unit = cast(1, LongInt.arch_uint_t);
        arch_max_uint = intmax(LongInt.arch_uint_t);

        karatsuba_threshold = 4;
        horner_window = 6;
    end

    properties
        num(1, :) uint64
        sign(1, 1) int64
    end
    
   methods (Access = protected)
       function propgrp = getPropertyGroups(obj)
          if ~isscalar(obj)
             propgrp = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
          else
             propList = struct('sign',obj.sign,...
                'num_arr',obj.num,...
                'num_hex',obj.to_hex());
             propgrp = matlab.mixin.util.PropertyGroup(propList);
          end
       end
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

            num = zeros(1, strlength(hex_str) / 16, LongInt.arch_uint_t);

            n = length(num);
            for i = n:-1:1
                k = LongInt.arch_zero;
                hex = hex_str((i-1)*16+1:i*16);

                for j = 16:-1:1
                    k = bitor(k, bitshift(LongInt.hex2uint(hex(j)), (16 - j) * 4));
                end
                
                num(n - i + 1) = k;
            end
    
            obj = LongInt.parse_from_array(num, s);
            obj.shrink_to_fit();
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
            res.shrink_to_fit();
        end

        function h = uint2hex(n)
            arguments
                n(1, 1) uint64
            end

            h(16) = char('0');
            mask = cast(15, LongInt.arch_uint_t);

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
            A0 = LongInt();
            A1 = LongInt();
            B0 = LongInt();
            B1 = LongInt();
            
            A0.sign = 1;
            A1.sign = 1;
            B0.sign = 1;
            B1.sign = 1;

            if A.nwords > B.nwords
                if mod(A.nwords, 2) ~= 0
                    n = A.nwords + 1;
                    A0.num = A.num(1:(n/2));
                    A1.num = [A.num((n / 2) + 1:end) LongInt.arch_zero];
                else
                    n = A.nwords;
                    A0.num = A.num(1:(n / 2));
                    A1.num = A.num((n / 2) + 1:end);
                end
                
                temp = [B.num zeros(1, n - B.nwords, LongInt.arch_uint_t)];
                B0.num = temp(1:(n/2));
                B1.num = temp((n / 2) + 1:end);
            else
                if mod(B.nwords, 2) ~= 0
                    n = B.nwords + 1;
                    B0.num = B.num(1:(n/2));
                    B1.num = [B.num((n / 2) + 1:end) LongInt.arch_zero];
                else
                    n = B.nwords;
                    B0.num = B.num(1:(n / 2));
                    B1.num = B.num((n / 2) + 1:end);
                end
                
                temp = [A.num zeros(1, n - A.nwords, LongInt.arch_uint_t)];
                A0.num = temp(1:(n/2));
                A1.num = temp((n / 2) + 1:end);
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
                 obj.num = LongInt.arch_unit;
            else
                obj.num = zeros(1, LongInt.bits_to_uints(1 + uint64(exp)), LongInt.arch_uint_t);
                obj.num(1) = typecast(frac, LongInt.arch_uint_t);
                obj.bitshift_inplace(-52 + int64(exp));
            end

            obj.shrink_to_fit();
            obj.sign = sign(num);
        end

        function n = hex2uint(c)
            arguments
                c(1, 1) char
            end
                
            a = cast(c, 'uint64');

            if  a <= cast('9', 'uint64') && a >= cast('0', 'uint64')
                n = cast(a - cast('0', 'uint64'), LongInt.arch_uint_t);
            elseif a <= cast('F', 'uint64') && a >= cast('A', 'uint64')
                n = cast((a - cast('A', 'uint64')) + 10, LongInt.arch_uint_t);
            else
                throw(MException('LongInt:wrongChar', ' ''%s'' is not a legit hexidecimal digit.', c));
            end
        end

        function result = digit_mult(A, B)
            arguments
                A(1,1) uint64
                B(1,1) uint64
            end

            A0 = bitshift(bitshift(A, LongInt.arch_w_len / 2), -(LongInt.arch_w_len / 2));
            A1 = bitshift(A, -(LongInt.arch_w_len / 2));

            B0 = bitshift(bitshift(B, LongInt.arch_w_len / 2), -(LongInt.arch_w_len / 2));
            B1 = bitshift(B, -(LongInt.arch_w_len / 2));
            
            result = LongInt();
            result.sign = 1;

            result.num(1) = B0 * A0;
            result.num(2) = B1 * A1;
            
            temp = LongInt();
            temp.sign = 1;
            temp.num = [A1 * B0, LongInt.arch_zero];

            x = temp.num(1);
            y = A0 * B1;
            temp.num(1) = bitadd(x, y);
            carry_bit = bitshift(bitor(bitand(x, y), bitand(bitxor(temp.num(1), intmax(LongInt.arch_uint_t)), ...
                bitor(x, y))), 1 - LongInt.arch_w_len);
            temp.num(2) = temp.num(2) + carry_bit;
            
            temp.bitshift_inplace(LongInt.arch_w_len / 2);

            x = result.num(1);
            y = temp.num(1);
            result.num(1) = bitadd(x, y);
            carry_bit = bitshift(bitor(bitand(x, y), bitand(bitxor(result.num(1), intmax(LongInt.arch_uint_t)), ...
                bitor(x, y))), 1 - LongInt.arch_w_len);
            result.num(2) = result.num(2) + temp.num(2) + carry_bit;
        end
    end

    methods(Access = public)
        function obj = LongInt(init_num)
            arguments
                init_num(1, 1) = LongInt.arch_zero
            end
            
            if isa(init_num, 'LongInt')
                obj.num = init_num.num;
                obj.sign = init_num.sign;
            elseif isa(init_num, 'double')
                obj = LongInt.parse_from_double(init_num);
            elseif isinteger(init_num)
                obj.num = cast(abs(init_num), LongInt.arch_uint_t);
                obj.sign = sign(init_num);
            else
                throw(MException('LongInt:wrongType', 'Cannot construct LongInt from type: %s', class(init_num)));
            end
        end

        function result = bitget(obj, ind)
            arguments
                obj(1, 1) LongInt
                ind {mustBeVector(ind), mustBeInteger(ind)}
            end

            result(length(ind)) = false;

            j = 1;
            for i = ind
                whole = ceil(double(i) / double(LongInt.arch_w_len));
                frac = mod(i - 1, LongInt.arch_w_len);

                m = LongInt.arch_unit;
                r = obj.num(whole);
                r = bitand(r, bitshift(m, frac));
                
                result(j) = logical(r);
                j = j + 1;
            end
        end

        function result = bitshift(obj, k)
            arguments
                obj(1, 1) LongInt
                k(1, 1) {mustBeInteger(k)}
            end

            result = LongInt();
            result.sign = obj.sign;

            if k == 0 || obj.sign == 0
                result.num = obj.num;
                return;
            elseif k > 0
                whole = floor(abs(double(k) / double(LongInt.arch_w_len)));
                result.num = [obj.num zeros(1, whole + 1, LongInt.arch_uint_t)];
            else
                result.num = obj.num;
            end
                
            result.bitshift_inplace(k);
            result.shrink_to_fit();
        end

        function result = uminus(obj)
            arguments
                obj(1, 1) LongInt
            end

            result = LongInt(obj);
            result.sign = -result.sign;
        end

        function result = abs(obj)
            arguments
                obj(1, 1) LongInt
            end

            result = LongInt(obj);
            result.sign = abs(result.sign);
        end

        function result = plus(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) LongInt
            end

            if obj2.sign == 0
                result = LongInt(obj);
            elseif obj.sign == 0
                result = LongInt(obj2);
            elseif obj.sign == obj2.sign
                result = LongInt(obj);
                add_abs(result, obj2);
            elseif lt_abs(obj, obj2)
                result = LongInt(obj2);
                sub_abs(result, obj);
            else
                result = LongInt(obj);
                sub_abs(result, obj2);
            end

            result.shrink_to_fit();
        end

        function result = minus(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) LongInt
            end
            
            if obj2.sign == 0
                result = LongInt(obj);
            elseif obj.sign == 0
                result = LongInt(obj2);
                result.sign = -(result.sign);
            elseif obj.sign ~= obj2.sign
                result = LongInt(obj);
                add_abs(result, obj2);
                result.sign = obj.sign;
            elseif lt_abs(obj, obj2)
                result = LongInt(obj2);
                sub_abs(result, obj);
                result.sign = -(result.sign);
            else
                result = LongInt(obj);
                sub_abs(result, obj2);
            end

            result.shrink_to_fit();
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
                result = LongInt(obj2);
            elseif obj2.num == LongInt.arch_unit
                result = LongInt(obj);
            else
                result = mult_karatsuba_abs(obj, obj2);
                result.shrink_to_fit();
            end

            result.sign = obj.sign * obj2.sign;
        end

        function result = mrdivide(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) LongInt
            end

            if obj2.sign == 0
                throw(MException('LongInt:zeroDivision', 'Cannot divide by zero.'));
            end
            
            if obj.sign == 0
                result = LongInt();
            else
                [result, ~] = div_abs(obj, obj2);
            end

            result.sign = obj.sign * obj2.sign;
        end

        function result = mod(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) LongInt
            end

            if obj2.sign == 0
                throw(MException('LongInt:zeroDivision', 'Cannot divide by zero.'));
            end

            if obj.sign == 0
                result = LongInt();
            else
                [~, result] = div_abs(obj, obj2);
            end
        end

        function result = mpower(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) LongInt
            end

            if obj.sign == 0
                result = LongInt(LongInt.arch_unit);
            elseif obj.sign < 0
                throw(MException('LongInt:negativePower', 'Cannot raise in negative power.'));
            else
                w = LongInt.horner_window;
                a(2^w) = LongInt();
                
                a(1) = LongInt(LongInt.arch_unit);
                for i = 2:2^w
                    a(i) = mult_karatsuba_abs(a(i - 1), obj);
                end
            
                n = abs(obj2.msb_pos);
                n = n + mod(n, w);
                
                result = a(1);

                j = n - w + 1;
                t = bitget(obj2, j:n);
                k = sum(t .* (2 .^ (0:w-1)), 'all');
                result = mult_karatsuba_abs(result, a(k + 1));
                
                j = j - w;

                for i = n-w:-w:w
                    fprintf('%d %%' , (1 - (i / n)));
                    for p = 1:w
                        result = mult_karatsuba_abs(result, result);
                    end

                    t = bitget(obj2, j:i);
                    k = sum(t .* (2 .^ (0:w-1)), 'all');
                    
                    result = mult_karatsuba_abs(result, a(k + 1));
                    j = j - w;
                end
            end

            if obj2.bitget(1)
                result.sign = abs(result.sign);
            end
        end

        function pos = msb_pos(obj)
            arguments
                obj(1, 1) LongInt
            end

            if obj.sign == 0
                pos = 0;
                return;
            end

            m = obj.num(end);

            k = LongInt.arch_w_len;
            while (bitget(m, k, LongInt.arch_uint_t) == 0)
                k = k - 1;
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

        function result = le(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) LongInt
            end
            
            result = eq(obj, obj2) || lt(obj, obj2);
        end

        function result = ne(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) LongInt
            end
            
            result = ~eq(obj, obj2);
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

            if obj.sign == 0
                result = '0';
                return;
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
    
        function [quotient, residual] = div_abs(obj, obj2)
            b = abs(obj2);
            m = abs(obj2.msb_pos);
            quotient = LongInt();
            quotient.num = zeros(1, obj.nwords - b.nwords + 1, LongInt.arch_uint_t);
            residual = abs(obj);

            while b <= residual
                k = residual.msb_pos() - m;
                t = bitshift(b, k);

                if lt_abs(residual, t)
                    t.bitshift_inplace(-1);
                    k = k - 1;
                end

                residual.sub_abs(t);
                residual.shrink_to_fit();
                quotient.add_abs(bitshift(LongInt(LongInt.arch_unit), k));
            end

            quotient = quotient.shrink_to_fit();
        end

        function result = mult_karatsuba_abs(obj, obj2)
            if min(obj.nwords, obj2.nwords) > LongInt.karatsuba_threshold
                [A0, A1, B0, B1] = LongInt.karatsuba_part(obj, obj2);

                n = A0.nwords * LongInt.arch_w_len;
                result = LongInt();
                result.sign = 1;
                result.num = zeros(1, A0.nwords * 4, LongInt.arch_uint_t);

                C1 = mult_karatsuba_abs(A1, B1);
                C0 = mult_karatsuba_abs(A0, B0);

                A0.add_abs(A1);
                B0.add_abs(B1);

                C2 = mult_karatsuba_abs(A0, B0);
                C2.sub_abs(C1);
                C2.sub_abs(C0);

                result.num(1:C1.nwords) = C1.num;
                result.bitshift_inplace(n);
                
                result.add_abs(C2);
                result.bitshift_inplace(n);

                result.add_abs(C0);

                result.shrink_to_fit();
            else
                result = mult_tbl_abs(obj, obj2);
            end
        end
        
        function result = mult_tbl_abs(obj, obj2)
            result = LongInt();
            result.num = zeros(1, obj.nwords + obj2.nwords, LongInt.arch_uint_t);
            result.sign = 1;

            temp = LongInt(result); 

            i = 0;
            for a_i = obj.num
                j = 0;
                for b_j = obj2.num
                    temp.num(1:2) = LongInt.digit_mult(a_i, b_j).num;
                    temp.bitshift_inplace(LongInt.arch_w_len * (i + j));
                    
                    result.add_abs(temp);

                    temp.num((i + j + 1):(i + j + 2)) = LongInt.arch_zero;
                    j = j + 1;
                end
                i = i + 1;
            end

            result.shrink_to_fit();
        end

        function obj = add_abs(obj, obj2)
            carry_bit = LongInt.arch_zero;
            
            n = min(obj2.nwords, obj.nwords);
            obj.num = [obj.num obj2.num(obj.nwords+1:end) LongInt.arch_zero];

            for i = 1:n
                x = obj.num(i);
                y = obj2.num(i);
                obj.num(i) = bitadd(bitadd(x, y), carry_bit);
                carry_bit = bitshift(bitor(bitand(x, y), bitand(bitxor(obj.num(i), intmax(LongInt.arch_uint_t)), ...
                    bitor(x, y))), 1 - LongInt.arch_w_len);
            end
            i = i + 1;

            if carry_bit ~= 0
                while obj.num(i) == LongInt.arch_max_uint
                    obj.num(i) = LongInt.arch_zero;
                    i = i + 1;
                end
                obj.num(i) = obj.num(i) + LongInt.arch_unit;
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

            if borrow_bit ~= 0
                while obj.num(i) == 0
                    obj.num(i) = LongInt.arch_max_uint;
                    i = i + 1;
                end

                obj.num(i) = obj.num(i) - LongInt.arch_unit;
            end
        end

        function obj = bitshift_inplace(obj, k)
            arguments
                obj(1, 1) LongInt
                k(1, 1) {mustBeInteger(k)}
            end

            carry_shift = LongInt.arch_zero;

            if k == 0
                return;
            end

            whole = floor(abs(double(k) / LongInt.arch_w_len));
            frac = mod(abs(k), LongInt.arch_w_len);

            if k > 0
                if whole ~= 0
                    obj.num = [zeros(1, whole, LongInt.arch_uint_t), obj.num(1:(obj.nwords - whole))];
                end

                if frac ~= 0
                    for i = 1:obj.nwords
                        r = obj.num(i);
                        obj.num(i) = bitor(bitshift(r, frac), carry_shift);
                        carry_shift = bitshift(r, (frac - LongInt.arch_w_len));
                    end
                end
            else
                if whole ~= 0
                    obj.num = [obj.num((whole + 1):end), zeros(1, whole, LongInt.arch_uint_t)];
                end

                if frac ~= 0
                    for i = obj.nwords:-1:1
                        r = obj.num(i);
                        obj.num(i) = bitor(bitshift(r, -frac), carry_shift);
                        carry_shift = bitshift(r, LongInt.arch_w_len - frac);
                    end
                end
            end
        end

        function obj = shrink_to_fit(obj)
            n = obj.nwords;
            for i = n:-1:1
                if obj.num(i) ~= LongInt.arch_zero
                    obj.num = obj.num(1:i);
                    return;
                end
            end
            obj.num = LongInt.arch_zero;
            obj.sign = 0;
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