classdef LongUInt
    
    properties
        n_words(1, 1) uint64
        num(1, :) uint64
    end
    
    methods
        function obj = LongUInt(init_num, bits_num)
            arguments
                init_num(1, 1) {mustBeArithmetic(init_num)} = 0
                bits_num(1, 1) {mustBeInteger, mustBeInRange(bits_num, 1, 4096)} = architecture_word_length
            end
            
            if isa(init_num, 'LongUInt')
                obj = init_num;
            elseif isa(init_num, 'double')
                obj = obj.parse_double(init_num);
            elseif isinteger(init_num)
                obj.num = zeros(1, bits_to_uints(bits_num) , architecture_uint_type);
                obj.num(1) = cast(init_num, architecture_uint_type);
            else
                throw(MExeption('Cannot construct LongUInt from: ' + class(init_num)));
            end
            
        end


        function result = bitshift(obj, k)
            arguments
                obj(1, 1) LongUInt
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
                obj(1, 1) LongUInt
                obj2(1, 1) {mustBeArithmetic(obj2)}
            end
            
            if ~isa(obj2, 'LongUInt')
                [result, carry] = plus(obj, LongUInt(obj2, obj.n_words * architecture_word_length));
                return;
            elseif obj2.n_words == obj.n_words
                result = LongUInt(0, obj.n_words * architecture_word_length);
    
                carry_bit = 0;

                for i = 1:obj.n_words
                    x = obj.num(i);
                    y = obj2.num(i);
                    result.num(i) = bitadd(bitadd(x, y), carry_bit);
                    carry_bit = bitshift(bitor(bitand(x, y), bitand(bitxor(result.num(i), architecture_max_uint), bitor(x, y))), 1 - architecture_word_length);
                end
            else
                throw(MExeption('Cannot add numbers of different lengths'));
            end
            
            carry = carry_bit;
        end

        function [result, carry] = minus(obj, obj2)
            arguments
                obj(1, 1) LongUInt
                obj2(1, 1) {mustBeArithmetic(obj2)}
            end

            result = LongUInt(obj.num(1) - obj2.num(1));
            carry = false;
        end

        function [result, carry] = mtimes(obj, obj2)
            arguments
                obj(1, 1) LongUInt
                obj2(1, 1) {mustBeArithmetic(obj2)}
            end

            result = LongUInt(obj.num(1) * obj2.num(1));
            carry = false;
        end

        function [result, carry] = mrdivide(obj, obj2)
            arguments
                obj(1, 1) LongUInt
                obj2(1, 1) {mustBeArithmetic(obj2)}
            end

            result = LongUInt(obj.num(1) / obj2.num(1));
            carry = false;
        end

        function [result, carry] = mpower(obj, obj2)
            arguments
                obj(1, 1) LongUInt
                obj2(1, 1) {mustBeArithmetic(obj2)}
            end

            result = LongUInt(obj.num(1) / obj2.num(1));
            carry = false;
        end

        function result = lt(obj, obj2)
            arguments
                obj(1, 1) LongUInt
                obj2(1, 1) {mustBeArithmetic(obj2)}
            end

            result = LongUInt(obj.num(1) / obj2.num(1));
            
        end

        function result = eq(obj, obj2)
            arguments
                obj(1, 1) LongUInt
                obj2(1, 1) {mustBeArithmetic(obj2)}
            end

            result = obj - obj2;
            
        end
    end
    methods(Access = private)
        function obj = parse_double(obj, num)
            arguments
                obj(1, 1) LongUInt
                num(1, 1) double
            end

            if num < 0
                throw(MExeption('Cannot parse a negative number into unsigned integer'))
            end

            frac = bitand(bitshift(intmax(architecture_uint_type), -12), typecast(num, architecture_uint_type)) + bitshift(1, 52);
            exp = bitshift(bitand(bitshift(bitshift(intmax(architecture_uint_type), 11 - 64), 64 - 12), typecast(num, architecture_uint_type)), -52) - 1023;
            obj.num = zeros(1, bits_to_uints(2^ceil(log2(architecture_word_length + double(exp)))), architecture_uint_type);
            obj.num(1) = typecast(frac, architecture_uint_type);
            obj = bitshift(obj, -52 + int64(exp));
        end
    end
end

function mustBeArithmetic(a)  
    if ~(isscalar(a) && ((isnumeric(a) && a >= 0) || isa(a,'LongUInt')))
        eidType = 'Num:notUIntOrLongUInt';
        msgType = 'Values assigned to Num property must be unsigned integer or LongUInt type.';
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