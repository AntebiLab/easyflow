function fcsfile = fileload(filename)

[~, ~, ext] = fileparts(filename);

if strcmp(ext, '.fcs')
    fcsfile = fcsload(filename);
elseif strcmp(ext, '.xlsx')
    fcsfile = fcsload_xls(filename);
end

end