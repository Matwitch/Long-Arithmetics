classdef LongIntTest < matlab.unittest.TestCase
    properties (TestParameter)
        zeroNum = {LongInt(0)};

        unitNum = {LongInt(1)};

        anyNum1 = num2cell(arrayfun(@(x) LongInt.parse_from_array(randuint64(1, x), randi([-1, 1], 1)), ...
            randi(anyNum_max_length, 1, anyNum_test_n)));

        anyNum2 = num2cell(arrayfun(@(x) LongInt.parse_from_array(randuint64(1, x), randi([-1, 1], 1)), ...
            randi(anyNum_max_length, 1, anyNum_test_n)));
        
        anyNum3 = num2cell(arrayfun(@(x) LongInt.parse_from_array(randuint64(1, x), randi([-1, 1], 1)), ...
            randi(anyNum_max_length, 1, anyNum_test_n)));

        anyNum4 = num2cell(arrayfun(@(x) LongInt.parse_from_array(randuint64(1, x), 1), ...
            randi(anyNum_max_length, 1, anyNum_test_n)));

        %anyPosNum = num2cell(arrayfun(@(x) LongInt.parse_from_array(randuint64(1, x), 1), ...
        %    randi(anyNum_max_length, 1, anyNum_test_n)));

        %anyNegNum = num2cell(arrayfun(@(x) LongInt.parse_from_array(randuint64(1, x), -1), ...
        %    randi(anyNum_max_length, 1, anyNum_test_n)));

        %anyPosNum64bit = num2cell(arrayfun(@(x) LongInt(x), randuint64(1, anyNum_test_n)));
        %anyNegNum64bit = num2cell(arrayfun(@(x) -LongInt(x), randuint64(1, anyNum_test_n)));

        %anyDouble = num2cell(arrayfun(@(x) typecast(x, 'double'), randuint64(1, anyNum_test_n)))
        anyInteger = num2cell(arrayfun(@(x) typecast(x, 'int64'), randuint64(1, anyNum_test_n)))
    end
    
    methods (Test)
        function SpecificTests(testCase)
            A1 = LongInt.from_hex('D4D2110984907B5625309D956521BAB4157B8B1ECE04043249A3D379AC112E5B9AF44E721E148D88A942744CF56A06B92D28A0DB950FE4CED2B41A0BD38BCE7D0BE1055CF5DE38F2A588C2C9A79A75011058C320A7B661C6CE1C36C7D870758307E5D2CF07D9B6E8D529779B6B2910DD17B6766A7EFEE215A98CAC300F2827DB');
            B1 = LongInt.from_hex('3A7EF2554E8940FA9B93B2A5E822CC7BB262F4A14159E4318CAE3ABF5AEB1022EC6D01DEFAB48B528868679D649B445A753684C13F6C3ADBAB059D635A2882090FC166EA9F0AAACD16A062149E4A0952F7FAAB14A0E9D3CB0BE9200DBD3B0342496421826919148E617AF1DB66978B1FCD28F8408506B79979CCBCC7F7E5FDE7');
            C1 = LongInt.from_hex('10F51035ED319BC50C0C4503B4D44872FC7DE7FC00F5DE863D6520E3906FC3E7E8761505118C918DB31AADBEA5A054B13A25F259CD47C1FAA7DB9B76F2DB450861BA26C4794E8E3BFBC2924DE45E47E5408536E3548A03591DA0556D595AB78C55149F45170F2CB7736A46976D1C09BFCE4DF6EAB040599AF235968F8070E25C2');
            CC1 = LongInt.from_hex('9A531EB436073A5B899CEAEF7CFEEE386318967D8CAA2000BCF598BA51261E38AE874C932360023620DA0CAF90CEC25EB7F21C1A55A3A9F327AE7CA879634C73FC1F9E7256D38E258EE860B509506BAE185E180C06CC8DFBC23316BA1B357240BE81B14C9EC0A25A73AE85C0049185BD4A8D7E29F9F82A7C2FBFEF68174229F4');
            A1B1 = LongInt.from_hex('30A120B609DCBE28B09CA92E12DD29D77AE6400DC22B026AFB5FB945AAF62B57F4E48BD299261F02BBB35DD2495B5CD2713BF0E30192DAE1B334659160C8552423F0AD7FB82870920DF4E9B57980EAD2ADA9F3EF4B5D0718AB7F1053700395278998CB9AD48498D65150E3E837B0BB169D432B441424557061F838A17C65F90A31105F599BF69B87485BF9C70F51D37A417E476E372558C26782AC8C8F35C3D1227E851D8A72CD708700FD90C5E17F22C4EA15730345E56BD76F04B54580813CBE306B4404C6F34BCD9840D2911E6B3CF6DE3EE428C274EDF0A97335D8256DA26FCD67BA5450593A15F6B527ECE76FBBE20F7A882347614AF4B7FAF55086659D');
            
            testCase.verifyEqual(A1 + B1, C1);
            testCase.verifyEqual(A1 - B1, CC1);
            testCase.verifyEqual(A1 * B1, A1B1);

            A2 = LongInt.from_hex('87D6D58D3991D536544389CEFA72FD0EBED75B2EBDC2C79BC3717793108F0952011E7E2D7040FFFB32F10BEB8ED0A485026B6860020B230128A8222B0525A6888942FB01C537800BF25D6F021D4B99D3CBD6DF9055FA22F91A6CFC4FDFC408AEF78F6418D3CE4E20EC7888B61BAE3D73C27C257CCA905DE0353C3A7CFFD9FE15');
            B2 = LongInt.from_hex('791EDB102DA183759979CEF70E1405AF14B98CD44357EADF6A8E35E49F99BB56CBD3F68897D6E05502ED1DE14EC46D04F96992C2D129737987E84E62371648B37633794016852A8CBFFCFDE06B17EC216AE8914D59E677A15A90361A594F0D1524A41AE63C59D343D4E522646722B0292DD7C85571AC9A84FDA6CD2D8DE307F6');
            C2 = LongInt.from_hex('100F5B09D673358ABEDBD58C6088702BDD390E803011AB27B2DFFAD77B028C4A8CCF274B60817E05035DE29CCDD951189FBD4FB22D334967AB090708D3C3BEF3BFF767441DBBCAA98B25A6CE2886385F536BF70DDAFE09A9A74FD326A391315C41C337EFF10282164C15DAB1A82D0ED9CF053EDD23C3CF86532E307AA8DBD060B');
            CC2 = LongInt.from_hex('EB7FA7D0BF051C0BAC9BAD7EC5EF75FAA1DCE5A7A6ADCBC58E341AE70F54DFB354A87A4D86A1FA63003EE0A400C37800901D59D30E1AF87A0BFD3C8CE0F5DD5130F81C1AEB2557F32607121B233ADB260EE4E42FC13AB57BFDCC6358674FB99D2EB493297747ADD17936651B48B8D4A94A45D2758E3C35B37956D4F71F6F61F');
            A2B2 = LongInt.from_hex('4044EA5A25164D587B8B56B8E83AEA576AB448F5C6C2B8B94BE32DEAEE0205CB4EE7F38B011731DF3AB60DCD67B0F9A4F1321230E38C5E62214F6369BE12A3C730150C1E0A54BE2820E61B35F0184ED6667EF0CB132220C6CD75A02CDD45B310BC73398279BB3A3AAB14C1FDE28E7025AB2295B18B17F3EA87D18BB309EA04305E2C0A4F949A560C4F2AD3BC9C2F18564D173D2DD01673ACE42A9E0B157003469C835657AEBE14D382E88736B276C720A439D68897BAEF046878C0CB3595B42A337EB00EA1F3A7A5294F26AE99E700756C4EB7E2EA365A2EF7580A4955FDEBE0660CEDF5A4E56A01CB3B0C920BE8A03A69C4E6066B1D14AA8FA2090BAF0BBB2E');

            testCase.verifyEqual(A2 + B2, C2);
            testCase.verifyEqual(A2 - B2, CC2);
            testCase.verifyEqual(A2 * B2, A2B2);

            A3 = LongInt.from_hex('4D3C91C579C2C6216567A5241614B561ADDF76C4BB659E6FE7F65FF76A918C843F0458B3EF457BCD9022D78798A29462EC99C74E6674690267D3E9844251B39D');
            B3 = LongInt.from_hex('DAF1ABDA4AD4D9FE3E36A529210C2AE99B905922FC0519798A26E351FE23AF375AD6BA288EE030B70DF0CE1CDF1E8B75BA56494DC6ED36B181814CD5783E6C81');
            C3 = LongInt.from_hex('1282E3D9FC497A01FA39E4A4D3720E04B496FCFE7B76AB7E9721D434968B53BBB99DB12DC7E25AC849E13A5A477C11FD8A6F0109C2D619FB3E9553659BA90201E');
            CC3 = LongInt(0);
            A3B3 = LongInt.from_hex('420E7E00B61E41A4992910FF7147F0D7DA534119BBD5BEE7EED2228604052A727147B4F01045272387643BC83E8AA54DD691149A58B77C0F3A39F7106AE22235D913D365494B7CC17BFE8294FAB72F34FA3230E1C9E8B145CCFEB672C73C922FF09ADFECFFCEB236A23A55C66904584EAC31CFA3B6A4DBC253D4E13BFAF7BE1D');

            testCase.verifyEqual(A3 + B3, C3);
            testCase.verifyTrue((A3 - B3) < CC3);
            testCase.verifyEqual(A3 * B3, A3B3);

            A4 = LongInt.from_hex('A664199B424E606126A31B875E3D5E9E9C2E13D6995CC801E60C30247808A6EE01E78895E16EAD95354FE50A9396DA3D5BDB6327FBF7DE11871BF3D0143055EC');
            B4 = LongInt.from_hex('D4DA433DBC99DE3D9F192F4B84000A628F00F01D10532B8299BE4987E001E2F23137039D7106217C58800406778F64750E949A6D229AC61FCD424632593C4735');
            C4 = LongInt.from_hex('17B3E5CD8FEE83E9EC5BC4AD2E23D69012B2F03F3A9AFF3847FCA79AC580A89E0331E8C335274CF118DCFE9110B263EB26A6FFD951E92A431545E3A026D6C9D21');
            CC4 = LongInt(0);
            A4B4 = LongInt.from_hex('8A58C226B4429FFC0493D57D8B3EF3048C3C82269D5C2CC9E4F40A078C09107AD50C637D281E740790C76BC0D9DC9243D90DCE7BB8FA9FDA799D0C80BC2913E8B6B2E24CE7FCFD72F6D14F2539E68E80AB31B0265E16DAED3B4FA75091FC11E27C69FD3FAFEC5CB66CE5796E01D3F091D140CE0E6D33956B80F908F8C5263DDC');

            testCase.verifyEqual(A4 + B4, C4);
            testCase.verifyTrue((A4 - B4) < CC4);
            testCase.verifyEqual(A4 * B4, A4B4);

        end

        function TestMultUnit(testCase, unitNum ,anyNum1)
            testCase.verifyEqual(anyNum1 * unitNum, anyNum1);
        end

        function TestMultZero(testCase, zeroNum ,anyNum1)
            testCase.verifyEqual(anyNum1 * zeroNum, zeroNum);
        end

        function TestPlus0(testCase, zeroNum, anyNum1)
            testCase.assertEqual(zeroNum.num, uint64(0));
            testCase.verifyEqual(zeroNum + anyNum1, anyNum1);
        end

        function TestMinus0(testCase, zeroNum, anyNum1)
            testCase.assertEqual(zeroNum.num, uint64(0));
            
            testCase.verifyEqual(anyNum1 - 0, anyNum1);
        end

        function TestBitShiftAndPlus(testCase, anyNum1)
            testCase.verifyEqual(bitshift(anyNum1, 1), anyNum1 + anyNum1);
            testCase.verifyEqual(bitshift(anyNum1 + anyNum1, -1), anyNum1)
        end

        function TestUnitNum(testCase, unitNum, anyNum1)
            testCase.assertEqual(unitNum.num, uint64(1));

            testCase.verifyEqual((anyNum1 + unitNum) - unitNum, (anyNum1 - unitNum) + unitNum);
            testCase.verifyEqual((anyNum1 + unitNum) - unitNum, anyNum1);
        end
    end

    methods (Test, ParameterCombination="sequential")
        function TestPlusCommutative(testCase, anyNum1, anyNum2)
            testCase.verifyEqual(anyNum1 + anyNum2, anyNum2 + anyNum1);
        end
        
        function TestDistributiveness(testCase, anyNum1, anyNum2, anyNum3)
            testCase.verifyEqual(anyNum3 * (anyNum1 + anyNum2), (anyNum3 * anyNum2) + (anyNum3 * anyNum1));
        end

        function TestDivision1(testCase, anyNum1, anyNum2)
            temp = (anyNum1 * anyNum2);
            zero = LongInt(LongInt.arch_zero);
            
            if ~isequal(anyNum1, zero)
                testCase.verifyEqual(temp / anyNum1, anyNum2);
            end

            if ~isequal(anyNum2, zero)
                testCase.verifyEqual(temp / anyNum2, anyNum1);
            end
            
            if ~isequal(anyNum1, zero) && ~isequal(anyNum2, zero)
                testCase.verifyEqual(temp / (anyNum1 * anyNum2), LongInt(1));
                testCase.verifyEqual((temp / anyNum1) / anyNum2, LongInt(1));
                testCase.verifyEqual((temp / anyNum2) / anyNum1, LongInt(1));
            end
        end

        function TestModAndDiv(testCase, anyNum1, anyNum2)
            if anyNum2.sign ~= 0
                x = abs(anyNum1);
                y = abs(anyNum2);
                q = x / y;
                r = mod(x, y);
    
                testCase.verifyEqual((q * y) + r, x);
            end
        end

        function TestGCD_Euclid(testCase, anyNum1, anyNum2)
            if anyNum2.sign ~= 0 && anyNum1.sign ~= 0
                d = gcd(anyNum1, anyNum2);
    
                testCase.verifyEqual(mod(anyNum1, d), LongInt(0));
                testCase.verifyEqual(mod(anyNum2, d), LongInt(0));
            end
        end

        function TestGCD_Stein(testCase, anyNum1, anyNum2)
            if anyNum2.sign ~= 0 && anyNum1.sign ~= 0
                d = gcd_binary(anyNum1, anyNum2);
    
                testCase.verifyEqual(mod(anyNum1, d), LongInt(0));
                testCase.verifyEqual(mod(anyNum2, d), LongInt(0));
            end
        end

        function TestGCD_Both(testCase, anyNum1, anyNum2)
            if anyNum2.sign ~= 0 && anyNum1.sign ~= 0
                d1 = gcd(anyNum1, anyNum2);
                d2 = gcd_binary(anyNum1, anyNum2);

                testCase.verifyEqual(d1, d2);
            end
        end

        function TestModuloStuff1(testCase, anyNum1, anyNum2, anyNum3, anyNum4)
            testCase.verifyEqual(mult_mod(mod(anyNum1 + anyNum2, anyNum4), anyNum3, anyNum4), ...
                                mod(mult_mod(anyNum1, anyNum3, anyNum4) + mult_mod(anyNum2, anyNum3, anyNum4), anyNum4))
        end

        function TestModuloStuff2(testCase, anyNum1, anyNum2)
            if anyNum2.sign > 0
                a = mult_mod(LongInt(133), anyNum1, anyNum2);
                b = anyNum1;
    
                for i = 1:132
                    b = mod(b + anyNum1, anyNum2);
                end
    
                testCase.verifyEqual(a, b);
            else
                fprintf('!');
            end
        end

        function TestEulerTh(testCase, anyNum1, anyNum2)
            if anyNum2.sign ~= 0 
                n = mod(anyNum2, 2^64);
                n = n.num;
                
                disp(n)
                if n > 1 && n < 2^50
                    d = gcd(anyNum1, n);
                    a = anyNum1 / d;
        
                    phi = eulerPhi(double(n));

                    testCase.verifyEqual(power_mod(a, phi, n), 1);
                end
            end
        end

        function TestNegDistributive(testCase, anyNum1, anyNum2)
            testCase.verifyEqual(-(anyNum1 + anyNum2), -anyNum1 - anyNum2);
        end

        function TestTriangleRule(testCase, anyNum1, anyNum2)
            x = abs(anyNum1 + anyNum2);
            y = abs(anyNum1) + abs(anyNum2);
            testCase.verifyTrue(x < y || x == y);
        end

        function TestAnyNumSum(testCase, anyNum1, anyNum2)
            c = anyNum1 + anyNum2;

            testCase.verifyEqual((c - anyNum1) - anyNum2, LongInt(0));
            testCase.verifyEqual((c - anyNum2) - anyNum1, LongInt(0));
            testCase.verifyEqual(c - anyNum1, anyNum2);
            testCase.verifyEqual(c - anyNum2, anyNum1);
        end
    end
end

function n = anyNum_test_n()
    n = 2^10;
end

function n = anyNum_max_length()
    n = 2^9 / 64 - 2;
end

function r = randuint64(dim1, dim2)
    arr = randi([0, intmax('uint32')], dim1, dim2, 'uint32');
    r = arrayfun(@(x) typecast([x randi([0, intmax('uint32')])], 'uint64'), arr);
end