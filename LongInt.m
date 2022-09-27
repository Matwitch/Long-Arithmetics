classdef LongInt
    
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

        function [result, carry] = plus(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) LongInt
            end

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

            carry = carry_bit;
        end

        function [result, carry] = minus(obj, obj2)
            arguments
                obj(1, 1) LongInt
                obj2(1, 1) {mustBeArithmetic(obj2)}
            end

            if lt_abs(obj, obj2)


            end

            carry = false;
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
                obj2(1, 1) {mustBeArithmetic(obj2)}
            end

            result = obj - obj2;
            
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
                obj.num = zeros(1, 1, architecture_uint_type);
                obj.sign = 0;
            end
            
            frac = bitand(bitshift(intmax(architecture_uint_type), -12), typecast(num, architecture_uint_type)) + bitshift(1, 52);
            exp = bitshift(bitand(uint64(9218868437227405312), typecast(num, architecture_uint_type)), -52) - 1023;
            obj.n_words = bits_to_uints(architecture_word_length + double(exp));
            obj.num = zeros(1, obj.n_words, architecture_uint_type);
            obj.num(1) = typecast(frac, architecture_uint_type);
            obj.sign = sign(num);
            obj = bitshift(obj, -52 + int64(exp));
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

function a = architecture_max_uint()
    a = intmax(architecture_uint_type);
end

function int1 = bitadd(int1, int2)
    while (int2 ~= 0)
        carry = bitand(int1, int2);
        int1 = bitxor(int1, int2);
        int2 = bitshift(carry, 1);
    end
end