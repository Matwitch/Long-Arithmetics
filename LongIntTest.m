classdef LongIntTest < matlab.unittest.TestCase
    properties (TestParameter)
        zeroNum = {LongInt(0)};

        unitNum = {LongInt(1)};

        anyNum = num2cell(arrayfun(@(x) LongInt.parse_from_array_test(randuint64(1, x), randi([-1, 1], 1)), ...
            randi(anyNum_max_length, 1, anyNum_test_n)));

        anyPosNum = num2cell(arrayfun(@(x) LongInt.parse_from_array_test(randuint64(1, x), 1), ...
            randi(anyNum_max_length, 1, anyNum_test_n)));

        anyNegNum = num2cell(arrayfun(@(x) LongInt.parse_from_array_test(randuint64(1, x), -1), ...
            randi(anyNum_max_length, 1, anyNum_test_n)));

        %anyNum64bit = num2cell(cellfun(@(x) LongInt.parse_from_array_test(x, randi([-1, 1], 1)), randuint64(1, anyNum_test_n)));
    end
    
    methods (Test)
        function Test1plus0(testCase, zeroNum, unitNum)
            testCase.assertEqual(zeroNum.num, 0);
            testCase.assertEqual(unitNum.num, 1);

            testCase.verifyEqual(zeroNum + unitNum, unitNum);
        end
    end
end

function n = anyNum_test_n()
    n = 10^2;
end

function n = anyNum_max_length()
    n = 2^10 / 64;
end

function r = randuint64(dim1, dim2)
    arr = randi([0, intmax('uint32')], dim1, dim2, 'uint32');
    r = arrayfun(@(x) typecast([x randi([0, intmax('uint32')])], 'uint64'), arr);
end