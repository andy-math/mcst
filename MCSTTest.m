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
            self.verifyEqual(MCSTTest.readFile('main.m'), MCSTTest.readFile('test/main.m'));
        end
        function testOutputM(self)
            self.verifyEqual(MCSTTest.readFile('output.m'), MCSTTest.readFile('test/output.m'));
        end
        function testMainM2(self)
            self.verifyEqual(MCSTTest.readFile('test/main.m'), MCSTTest.readFile('test2/main.m'));
        end
        function testOutputM2(self)
            self.verifyEqual(MCSTTest.readFile('test/output.m'), MCSTTest.readFile('test2/output.m'));
        end
        function testMainPy(self)
            self.verifyEqual(MCSTTest.readFile('py/main.py'), MCSTTest.readFile('py2/main.py'));
        end
        function testOutputPy(self)
            self.verifyEqual(MCSTTest.readFile('py/output.py'), MCSTTest.readFile('py2/output.py'));
        end
        function testNodesM(self)
            files = dir('mcst');
            for i = 1:numel(files)
                if ~(startsWith(files(i).name, '.') || endsWith(files(i).name, '.asv'))
                    self.verifyEqual(MCSTTest.readFile(['mcst/', files(i).name]), MCSTTest.readFile(['test/', files(i).name]));
                end
            end
        end
        function testNodesPy(self)
            files = dir('mcst');
            for i = 1:numel(files)
                if ~(startsWith(files(i).name, '.') || endsWith(files(i).name, '.asv'))
                    self.verifyEqual(MCSTTest.readFile(['py/nodes/', files(i).name(1:end-2), '.py']), ...
                        MCSTTest.readFile(['py2/nodes/', files(i).name(1:end-2), '.py']));
                end
            end
        end
    end
end