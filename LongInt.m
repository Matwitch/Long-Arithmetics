classdef LongInt
    %test push
    properties
        n_words(1, 1) uint64
        num(1, :) uint64
        sign(1, 1) int8
    end
    
    methods
        function obj = LongInt(init_num)
            arguments
                init_num(1, 1) {mustBeArithmetic(init_num)} = 0
            end
            
            if isa(init_num, 'LongInt')
                obj = init_num;
            elseif isa(init_num, 'double')
                obj = obj.parse_double(init_num);
            elseif isinteger(init_num)
                obj.num = cast(abs(init_num), architecture_uint_type);
                obj.sign = sign(init_num);
                obj.n_words = 1;
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

            if k == 0
                return;
            end

            whole = floor(abs(k / architecture_word_length));
            frac = mod(abs(k), architecture_word_length);
            n = int64(result.n_words);

            if k > 0
                result.num = [zeros(1, whole, architecture_uint_type), result.num(1:(n - whole))];
            else
                result.num = [result.num((whole + 1):n), zeros(1, whole, architecture_uint_type)];
                frac = -frac;
            end

            carry_shift = 0;

            for i = 1:n
                r = result.num(i);
                result.num(i) = bitxor(bitshift(r, frac), carry_shift);
                carry_shift = bitshift(r, frac - architecture_word_length);
            end
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
                return;
            end
            
            if obj.sign == obj2.sign
                if obj2.n_words > obj.n_words
                    result = obj2;
                    n = obj.n_words;
                else
                    result = obj;
                    n = obj2.n_words;
                end
    
                carry_bit = 0;
    
                for i = 1:n
                    x = obj.num(i);
                    y = obj2.num(i);
                    result.num(i) = bitadd(bitadd(x, y), carry_bit);
                    % carry_bit = bitshift(bitor(bitand(x, y), bitand(bitxor(result.num(i), architecture_max_uint), bitor(x, y))), 1 - architecture_word_length);
                    x_n = bitget(x, architecture_word_length);
                    y_n = bitget(y, architecture_word_length);
                    carry_bit = cast((x_n && y_n) || (~bitget(result.num(i), architecture_word_length) && (x_n || y_n)), architecture_uint_type);
                end
    
                for i = (n+1):result.n_words
                    result.num(i) = bitadd(result.num(i), carry_bit);
                    carry_bit = cast(bitget(result.num(i), architecture_word_length) && carry_bit, architecture_uint_type);
                end
    
                if carry_bit ~= 0
                    result.num = [result.num cast(0, architecture_uint_type)];
                    result.n_words = result.n_words + 1;
                    result.num(result.n_words) = carry_bit;
                end
            else
                if obj2.sign == -1
                    obj2.sign = -obj2.sign;
                    result = minus(obj, obj2);
                else
                    obj.sign = -obj.sign;
                    result = minus(obj2, obj);
                end
            end
        end

        function result = minus(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) LongInt
            end
           
            if obj2.sign == 0
                result = obj;
                return;
            end

            if obj.sign == obj2.sign
                if lt_abs(obj, obj2)
                    result = obj2;
                    temp = obj;
                    result.sign = -obj2.sign;
                else
                    result = obj;
                    temp = obj2;
                end

                borrow_bit = cast(0, architecture_uint_type);

                for i = 1:temp.n_words
                    x = result.num(i);
                    y = temp.num(i);
                    result.num(i) = bitsubtract(bitsubtract(x, y), borrow_bit);
                    x_n = bitget(x, architecture_word_length);
                    y_n = bitget(y, architecture_word_length);
                    z_n = bitget(result.num(i), architecture_word_length);
                    borrow_bit = cast((~x_n && (borrow_bit || y_n)) || (y_n || z_n), architecture_uint_type);
                end

                for i = temp.n_words+1:result.n_words
                    result.num(i) = bitsubtract(result.num(i), cast(borrow_bit, architecture_uint_type));
                    borrow_bit = (~bitget(x, architecture_word_length) && borrow_bit) || bitget(result.num(i), architecture_word_length);
                end

                result = shrink_to_fit(result);
            else
                obj2.sign = - obj2.sign;
                result = plus(obj, obj2);
                result.sign = obj.sign;
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
        function obj = parse_double(obj, num)
            arguments
                obj(1, 1) LongInt
                num(1, 1) double
            end

            if num == 0
                obj.n_words = 1;
                obj.num = cast(0, architecture_uint_type);
                obj.sign = 0;
                return;
            end
            
            frac = bitand(bitshift(intmax(architecture_uint_type), -12), typecast(num, architecture_uint_type)) + bitshift(1, 52);
            exp = bitshift(bitand(uint64(9218868437227405312), typecast(num, architecture_uint_type)), -52) - 1023;
            obj.n_words = bits_to_uints(1 + uint64(exp));

            if exp == 0
                 obj.num = cast(1, architecture_uint_type);
            else
                obj.num = zeros(1, obj.n_words, architecture_uint_type);
                obj.num(1) = typecast(frac, architecture_uint_type);
                obj = bitshift(obj, -52 + int64(exp));
            end

            obj.sign = sign(num);
        end

        function r = shrink_to_fit(obj)
            n = obj.n_words;
            zero = cast(0, architecture_uint_type);
            for i = n:-1:1
                if obj.num(i) ~= zero
                    obj.num = obj.num(1:i);
                    obj.n_words = i;
                    r = obj;
                    return;
                end
            end
            r = LongInt(0);
        end

        function r = lt_abs(obj, obj2)
            if obj.n_words < obj2.n_words
                r = true;
            elseif obj.n_words > obj2.n_words
                r = false;
            else
                for i = obj.n_words:-1:1
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

function a = architecture_uint_type()
    a = 'uint64';
end

function a = architecture_word_length()
    a = 64;
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