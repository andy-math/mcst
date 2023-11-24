function [mdir, pydir] = configure()
    if ~isfolder('test_m')
        mkdir('test_m');
    end
    if ~isfolder('test_m/m')
        mkdir('test_m/m');
    end
    if ~isfolder('test_m/py')
        mkdir('test_m/py');
    end
    mdir = 'test_m/m';
    pydir = 'test_m/py';
end