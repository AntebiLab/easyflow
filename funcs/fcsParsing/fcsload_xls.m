function fcsfile = fcsload_xls(filename)
%load fcs data from xls file
%
%fcsfile=fcsload_xls(filname)
%   loads the file given and stores the data and metadata in the structure
%   fcsfile


curdir=pwd;

%check inputs
%TBD:if no input open a dialog
if nargin==0
    [filename,pathname] = uigetfile('*.xlsx','MultiSelect','on');
    if isnumeric(filename)
        error('No file to load.');
    else
        cd(pathname);
    end
else
    [pathname, name, ext] = fileparts(filename);
    filename=[name ext];
    if ~isempty(pathname)
        cd(pathname);
    else
        pathname=pwd;
    end
end

if ~iscell(filename)
    filename={filename};
end

%set outputs
fcsfile(1:length(filename))=struct;

for index=1:length(filename)
    curfile=filename{index};
    %open file
    if exist(curfile,'file') && ~exist(curfile,'dir')
        [num, txt] = xlsread(curfile);
    else
        error(['File ',curfile,' does not exist.'])
    end
    
    [~, name, ~] = fileparts(curfile);
    fcsfilename = [name, '.fcs'];
    
    %
    fcsdata = single(num);
    var_name = {'$BEGINANALYSIS', '$BEGINDATA', '$BEGINSTEXT', '$BYTEORD', ...
        '$DATATYPE', '$ENDANALYSIS', '$ENDDATA', '$ENDSTEXT', '$MODE', ...
        '$NEXTDATA', '$PAR'}';
    var_value = {'58', '0', '0', '1,2,3,4', ...
        'F', '0', '0', '0', 'L', ...
        '0', num2str(size(txt,2))}';
    
    for pnum = 1:size(txt,2)
        pstr = num2str(pnum);
        var_name = [var_name; {['$P' pstr 'B'], ['$P' pstr 'E'], ['$P' pstr 'N'], ['$P' pstr 'R']}'];
        var_value = [var_value; {'32', '0,0', num2str(txt{1,pnum}), '4294967296'}'];
    end
    var_name = [var_name; {'$TOT'}];
    var_value = [var_value; num2str(size(num,1))];
    
    % Empty headers. will be generated in saving the file.
    fcsheader = '';
    Offsets = [58,0,0,0,0,0]';
    fcstext = '';
    fcsanalysis = '00000000';
    seperator = '/';


    
    %output
    fcsfile(index).fcsheader=fcsheader;
    fcsfile(index).Offsets=Offsets;
    fcsfile(index).fcstext=fcstext;
    fcsfile(index).seperator=seperator;
    fcsfile(index).var_name=var_name;
    fcsfile(index).var_value=var_value;
    fcsfile(index).fcsdata=fcsdata;
    fcsfile(index).fcsanalysis=fcsanalysis;
    fcsfile(index).filename=fcsfilename;
    fcsfile(index).dirname=pathname;
    
end

%save the files as fcs
fcssave(fcsfile);

cd(curdir);

end