function fcsfile = fcsload(filename)
%edit and save fcs files
%
%fcsfile=fcsload(filname)
%   loads the file given and stores the data and metadata in the structure
%   fcsfile


curdir=pwd;

%check inputs
%TBD:if no input open a dialog
if nargin==0
    [filename,pathname] = uigetfile('*.fcs','MultiSelect','on');
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
        pathname = pwd;
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
        fid = fopen(curfile,'r','b');
    else
        error(['File ',curfile,' does not exist.'])
    end
    fseek(fid,0,'bof');
    
    %read the header
    fcsheader=fread(fid,58,'*char')';
    %check version is FCS3.0
    if ~strcmp(fcsheader(1:6),'FCS3.0')
        %error('Not an FCS3.0 file');
    end
    %get the offsets for the different sections
    %TBD: if offset is 0 it might be stated in the text section
    Offsets=str2num(reshape(fcsheader(11:end),8,6)'); %#ok<ST2NM>
    
    %read text section
    fseek(fid,Offsets(1),'bof');
    fcstext=fread(fid,Offsets(2)-Offsets(1)+1,'*char')';
    %parse text section
    if strcmp('\',fcstext(1))
        %TBR 20150605 parsedtext=textscan(fcstext(2:end),'%s','delimiter',['\' fcstext(1)],'Whitespace','','bufsize',length(fcstext));
        parsedtext=textscan(fcstext(2:end),'%s','delimiter',['\' fcstext(1)],'Whitespace','','EndOfLine','');
    else
        parsedtext=textscan(fcstext(2:end),'%s','delimiter',fcstext(1),'Whitespace','','EndOfLine','');
    end
    var_name=parsedtext{1}(1:2:end);
    var_value=parsedtext{1}(2:2:end);
    if length(var_value)<length(var_name)
        var_name(end)=[];
    end
    %read data section
    %floor is since some FACSs gives the EOF as the end of the data
    %section.
    if strcmp(var_value(strcmp(var_name,'$DATATYPE')),'I')
        switch var_value{strcmp(var_name,'$P1B')}
            case '16'
                fmt='uint16';
                psize=2;
            case '32'
                fmt='uint32';
                psize=4;
        end
    else
        fmt='single';
        psize=4;
    end
    fseek(fid,Offsets(3),'bof');
    fcsdata=[];
    if Offsets(3)==0
        Offsets(3)=str2double(var_value(strcmp(var_name,'$BEGINDATA')));
    end
    if Offsets(4)==0
        Offsets(4)=str2double(var_value(strcmp(var_name,'$ENDDATA')));
    end
    if Offsets(3)~=Offsets(4) 
        if strcmp(var_value(strcmp(var_name,'$BYTEORD')),'1,2,3,4')
            m = memmapfile(curfile,'Offset',Offsets(3),'Format',fmt,'Repeat',floor((Offsets(4)-Offsets(3)+1)/psize));
            fcsdata=m.data;
        else
            m = memmapfile(curfile,'Offset',Offsets(3),'Format',fmt,'Repeat',floor((Offsets(4)-Offsets(3)+1)/psize));
            fcsdata=swapbytes(m.data);
        end
    elseif Offsets(3)==0
    end

    %assume no analysis section
    fcsanalysis='00000000';
    
    %output
    fcsfile(index).fcsheader=fcsheader;
    fcsfile(index).Offsets=Offsets;
    fcsfile(index).fcstext=fcstext;
    fcsfile(index).seperator=fcstext(1);
    fcsfile(index).var_name=var_name;
    fcsfile(index).var_value=var_value;
    mtxdata=reshape(single(fcsdata),...
        str2double(fcsfile(index).var_value{strcmp(fcsfile(index).var_name,'$PAR')}),...
        str2double(fcsfile(index).var_value{strcmp(fcsfile(index).var_name,'$TOT')}))';
    fcsfile(index).fcsdata=mtxdata;
    fcsfile(index).fcsanalysis=fcsanalysis;
    fcsfile(index).filename=curfile;
    fcsfile(index).dirname=pathname;
    %close file
    fclose(fid);
    
end
cd(curdir);

end