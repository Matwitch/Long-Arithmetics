classdef LongIntTest < matlab.unittest.TestCase
    properties (TestParameter)
        zeroNum = {LongInt(0)};

        unitNum = {LongInt(1)};

        anyNum1 = num2cell(arrayfun(@(x) LongInt.parse_from_array(randuint64(1, x), randi([-1, 1], 1)), ...
            randi(anyNum_max_length, 1, anyNum_test_n)));

        anyNum2 = num2cell(arrayfun(@(x) LongInt.parse_from_array(randuint64(1, x), randi([-1, 1], 1)), ...
            randi(anyNum_max_length, 1, anyNum_test_n)));

        anyPosNum = num2cell(arrayfun(@(x) LongInt.parse_from_array(randuint64(1, x), 1), ...
            randi(anyNum_max_length, 1, anyNum_test_n)));

        anyNegNum = num2cell(arrayfun(@(x) LongInt.parse_from_array(randuint64(1, x), -1), ...
            randi(anyNum_max_length, 1, anyNum_test_n)));

        anyPosNum64bit = num2cell(arrayfun(@(x) LongInt(x), randuint64(1, anyNum_test_n)));
        anyNegNum64bit = num2cell(arrayfun(@(x) -LongInt(x), randuint64(1, anyNum_test_n)));

        anyDouble = num2cell(arrayfun(@(x) typecast(x, 'double'), randuint64(1, anyNum_test_n)))
        anyInteger = num2cell(arrayfun(@(x) typecast(x, 'int64'), randuint64(1, anyNum_test_n)))
    end
    
    methods (Test)
        function TestPlus0(testCase, zeroNum, anyNum1)
            testCase.assertEqual(zeroNum.num, uint64(0));
            fprintf('1');
            testCase.verifyEqual(zeroNum + anyNum1, anyNum1);
        end

        function TestMinus0(testCase, zeroNum, anyNum1)
            testCase.assertEqual(zeroNum.num, uint64(0));
            
            testCase.verifyEqual(anyNum1 - 0, anyNum1);
            fprintf('2');
        end

        function TestBitShiftAndPlus(testCase, anyNum1)
            testCase.verifyEqual(bitshift(anyNum1, 1), anyNum1 + anyNum1);
            testCase.verifyEqual(bitshift(anyNum1 + anyNum1, -1), anyNum1)
            fprintf('4');
        end

        function TestUnitNum(testCase, unitNum, anyNum1)
            testCase.assertEqual(unitNum.num, uint64(1));

            testCase.verifyEqual((anyNum1 + unitNum) - unitNum, (anyNum1 - unitNum) + unitNum);
            testCase.verifyEqual((anyNum1 + unitNum) - unitNum, anyNum1);
            fprintf('4');
        end
    end

    methods (Test, ParameterCombination="sequential")
        function TestPlusCommutative(testCase, anyNum1, anyNum2)
            testCase.verifyEqual(anyNum1 + anyNum2, anyNum2 + anyNum1);
            fprintf('3');
        end
        
        function TestNegDistributive(testCase, anyNum1, anyNum2)
            testCase.verifyEqual(-(anyNum1 + anyNum2), -anyNum1 - anyNum2);
            fprintf('3');
        end

        function TestAnyNumSum(testCase, anyNum1, anyNum2)
            c = anyNum1 + anyNum2;

            testCase.verifyEqual((c - anyNum1) - anyNum2, LongInt(0));
            testCase.verifyEqual((c - anyNum2) - anyNum1, LongInt(0));
            testCase.verifyEqual(c - anyNum1, anyNum2);
            testCase.verifyEqual(c - anyNum2, anyNum1);

            fprintf('5');
        end

    end
end

function n = anyNum_test_n()
    n = 2^13;
end

function n = anyNum_max_length()
    n = 2^12 / 64;
end

function r = randuint64(dim1, dim2)
    arr = randi([0, intmax('uint32')], dim1, dim2, 'uint32');
    r = arrayfun(@(x) typecast([x randi([0, intmax('uint32')])], 'uint64'), arr);
end