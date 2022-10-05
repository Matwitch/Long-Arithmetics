classdef LongInt
    properties
        num(1, :) uint64
        sign(1, 1) int8
    end
    
    methods(Static)
        function res = parse_from_array_test(arr, a_sign)
            arguments
                arr uint64 {mustBeVector}
                a_sign(1,1) {mustBeInRange(a_sign, -1, 1)}
            end

            if a_sign == 0
                res = LongInt();
                return; 
            end

            res = LongInt(0);
            res.num = cast(arr, architecture_uint_type);
            res.sign = a_sign;
        end

        function obj = parse_from_double(num)
            arguments
                num(1, 1) double
            end

            obj = LongInt();

            if num == 0
                obj.nwords = 1;
                obj.num = architecture_zero;
                obj.sign = 0;
                return;
            end
            
            frac = bitand(bitshift(intmax(architecture_uint_type), -12), typecast(num, architecture_uint_type)) + bitshift(1, 52);
            exp = bitshift(bitand(uint64(9218868437227405312), typecast(num, architecture_uint_type)), -52) - 1023;

            if exp == 0
                 obj.num = cast(1, architecture_uint_type);
            else
                obj.num = zeros(1, bits_to_uints(1 + uint64(exp)), architecture_uint_type);
                obj.num(1) = typecast(frac, architecture_uint_type);
                obj = bitshift(obj, -52 + int64(exp));
            end

            obj.sign = sign(num);
        end
    end

    methods(Access = public)
        function obj = LongInt(init_num)
            arguments
                init_num(1, 1) {mustBeArithmetic(init_num)} = architecture_zero
            end
            
            if isa(init_num, 'LongInt')
                obj = init_num;
            elseif isa(init_num, 'double')
                obj = LongInt.parse_from_double(init_num);
            elseif isinteger(init_num)
                obj.num = cast(abs(init_num), architecture_uint_type);
                obj.sign = sign(init_num);
            else
                throw(MExeption('Cannot construct LongInt from: ' + class(init_num)));
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

            whole = floor(abs(double(k) / architecture_word_length));
            frac = mod(abs(k), architecture_word_length);

            if k > 0
                result.num = [zeros(1, whole, architecture_uint_type), result.num, architecture_zero];
                
                for i = 1:result.nwords
                    r = result.num(i);
                    result.num(i) = bitor(bitshift(r, frac), carry_shift);
                    carry_shift = bitshift(r, (frac - architecture_word_length));
                end
            else
                result.num = result.num((whole + 1):result.nwords);

                for i = result.nwords:-1:1
                    r = result.num(i);
                    result.num(i) = bitor(bitshift(r, -frac), carry_shift);
                    carry_shift = bitshift(r, architecture_word_length - frac);
                end
            end

            result = shrink_to_fit(result);
        end

        function result = uminus(obj)
            result = obj;
            result.sign = -result.sign;
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

        function [result, carry] = mtimes(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) {mustBeArithmetic(obj2)}
            end

            result = LongInt(obj.num(1) * obj2.num(1));
            carry = false;
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

        function result = lt(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) {mustBeArithmetic(obj2)}
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
    end

    methods(Access = private)
        function n = nwords(obj)
            n = length(obj.num);
        end

        function result = add_abs(obj, obj2)
            carry_bit = architecture_zero;
            
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
                carry_bit = bitshift(bitor(bitand(x, y), bitand(bitxor(result.num(i), intmax(architecture_uint_type)), ...
                    bitor(x, y))), 1 - architecture_word_length);
            end
            i = i + 1;

            while carry_bit ~= 0 && i ~= result.nwords + 1
                result.num(i) = bitadd(result.num(i), 1);
                carry_bit = (result.num(i) == architecture_max_uint);
                i = i + 1;
            end

            if carry_bit ~= 0
                result.num = [result.num, architecture_zero];
                result.num(result.nwords) = 1;
            end
        end

        function obj = sub_abs(obj, obj2)
            borrow_bit = architecture_zero;

            for i = 1:obj2.nwords
                x = obj.num(i);
                y = obj2.num(i);
                obj.num(i) = bitsubtract(bitsubtract(x, y), borrow_bit);
                borrow_bit = bitshift(bitor(bitand(bitxor(x, architecture_max_uint), bitor(obj.num(i), y)), ...
                    bitand(y, obj.num(i))), 1 - architecture_word_length);
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

            whole = floor(abs(double(k) / architecture_word_length));
            frac = mod(abs(k), architecture_word_length);
            n = result.nwords;

            if k > 0
                result.num = [zeros(1, whole, architecture_uint_type), result.num(1:(n - whole))];

                for i = 1:n
                    r = result.num(i);
                    result.num(i) = bitor(bitshift(r, frac), carry_shift);
                    carry_shift = bitshift(r, (frac - architecture_word_length));
                end
            else
                result.num = [result.num((whole + 1):n), zeros(1, whole, architecture_uint_type)];

                for i = n:-1:1
                    r = result.num(i);
                    result.num(i) = bitor(bitshift(r, frac), carry_shift);
                    carry_shift = bitshift(r, architecture_word_length - frac);
                end
            end
        end

        function obj = shrink_to_fit(obj)
            n = obj.nwords;
            zero = cast(0, architecture_uint_type);
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

function mustBeArithmetic(a)  
    if ~(isscalar(a) && (isnumeric(a) || isa(a, 'LongInt')))
        eidType = 'Num:notIntOrLongInt';
        msgType = 'Values assigned to Num property must be an integer or a LongInt.';
        throwAsCaller(MException(eidType,msgType))
    end
end

function a = architecture_zero()
    a = cast(0, architecture_uint_type);
end

function a = architecture_uint_type()
    a = 'uint' + string(architecture_word_length);
end

function a = architecture_word_length()
    a = 64;
end

function a = architecture_max_uint()
    a = intmax(architecture_uint_type);
end

function a = bits_to_uints(bits_num)
    a = ceil(double(bits_num) / architecture_word_length);
end

function res = bitsubtract(num1, num2)
    res = bitadd(bitadd(num1, bitcomplement(num2)), 1);
end

function res = bitcomplement(num)
    res = intmax(architecture_uint_type) - num;
end

function int1 = bitadd(int1, int2)
    while (int2 ~= 0)
        carry = bitand(int1, int2);
        int1 = bitxor(int1, int2);
        int2 = bitshift(carry, 1);
    end
end