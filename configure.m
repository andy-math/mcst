function [mdir, pydir] = configure()
    if ~isfolder('test.m')
        mkdir('test.m');
    end
    if ~isfolder('test.m/m')
        mkdir('test.m/m');
    end
    if ~isfolder('test.m/py')
        mkdir('test.m/py');
    end
    mdir = 'test.m/m';
    pydir = 'test.m/py';
end