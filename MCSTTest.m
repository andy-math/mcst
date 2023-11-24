classdef MCSTTest < matlab.unittest.TestCase
    methods(Static)
        function content = readFile(filename)
            fid = fopen(filename);
            content = native2unicode(fread(fid).');
            fclose(fid);
            while contains(content, sprintf('\r\n'))
                content = replace(content, sprintf('\r\n'), newline);
            end
        end
    end
    methods (Test)
        function testMainM(self)
            self.verifyEqual(MCSTTest.readFile('main.m'), MCSTTest.readFile('test_m/m/main.m'));
        end
        function testOutputM(self)
            self.verifyEqual(MCSTTest.readFile('output.m'), MCSTTest.readFile('test_m/m/output.m'));
        end
        function testMainM2(self)
            self.verifyEqual(MCSTTest.readFile('test_m/m/main.m'), MCSTTest.readFile('test_py/m/main.m'));
        end
        function testOutputM2(self)
            self.verifyEqual(MCSTTest.readFile('test_m/m/output.m'), MCSTTest.readFile('test_py/m/output.m'));
        end
        function testMainPy(self)
            self.verifyEqual(MCSTTest.readFile('test_m/py/main.py'), MCSTTest.readFile('test_py/py/main.py'));
        end
        function testOutputPy(self)
            self.verifyEqual(MCSTTest.readFile('test_m/py/output.py'), MCSTTest.readFile('test_py/py/output.py'));
        end
        function testNodesM(self)
            files = dir('mcst');
            for i = 1:numel(files)
                if ~(startsWith(files(i).name, '.') || endsWith(files(i).name, '.asv'))
                    self.verifyEqual(MCSTTest.readFile(['mcst/', files(i).name]), MCSTTest.readFile(['test_m/m/', files(i).name]));
                end
            end
        end
        function testNodesPy(self)
            files = dir('mcst');
            for i = 1:numel(files)
                if ~(startsWith(files(i).name, '.') || endsWith(files(i).name, '.asv'))
                    self.verifyEqual(MCSTTest.readFile(['test_m/py/nodes/', files(i).name(1:end-2), '.py']), ...
                        MCSTTest.readFile(['test_py/py/nodes/', files(i).name(1:end-2), '.py']));
                end
            end
        end
    end
end