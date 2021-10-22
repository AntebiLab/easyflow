function fcssave(fcsfile,overwrite) %#ok<INUSD>
%edit and save fcs files
%fcssave(fcsfile,overwrite)
% fcsfile - structure with the fcsfile data
% overwrite - if exist, overwrite without asking. value is ignored.

%use the structure:
% fcsfile
%   var_name
%   var_value
%   fcsdata
%   Offsets
%   dirname
%   filename

curdir=pwd;

for index=1:length(fcsfile)
    
    %filename=fcsfile(index).var_value{strcmp(fcsfile(index).var_name,'$FIL')};
    %TBD: what to do if no $FIL exist.
    filename=fcsfile(index).filename;
    if exist(fcsfile(index).dirname,'dir')
        cd(fcsfile(index).dirname)
    elseif ~isempty(fcsfile(index).dirname)
        error(['Directory ' fcsfile(index).dirname ' does not exist.'])
    end
    
    %open file
    if exist('overwrite','var') || ~exist(filename,'file')
        fid = fopen(filename,'w','b');
    else
        button = questdlg('File already exist. Overwrite?','FCS Save','No');
        if ~strcmp(button,'Yes')
            continue;
        else
            fid = fopen(filename,'w','b');
        end
    end
    fseek(fid,0,'bof');
    
    %verify offsets
    datastart=fcsfile(index).Offsets(3);
    dataend=fcsfile(index).Offsets(4);
    %recalc the data start and end position and the test end position
    while datastart~=256 ...header size
            +1+length(fcsfile(index).var_value)*2+length([fcsfile(index).var_value{:}])+length([fcsfile(index).var_name{:}]) ...text size
            +5 ...%fill
            || dataend~=datastart+length(fcsfile(index).fcsdata(:))*4-1
        datastart=256 ...header size
            +1+length(fcsfile(index).var_value)*2+length([fcsfile(index).var_value{:}])+length([fcsfile(index).var_name{:}]) ...text size
            +5;%fill
        dataend=datastart+length(fcsfile(index).fcsdata(:))*4-1;
        fcsfile(index).var_value{strcmp(fcsfile(index).var_name,'$BEGINDATA')}=int2str(datastart);
        %enddata is padded to 19 chars
        tmp=char({'1234567890123456789';num2str(dataend)});
        fcsfile(index).var_value{strcmp(fcsfile(index).var_name,'$ENDDATA')}=tmp(2,:);
        fcsfile(index).Offsets(2)=datastart-6;
        fcsfile(index).Offsets(3)=datastart;
        fcsfile(index).Offsets(4)=dataend;
    end
    
    
    %remake the text section
    tmp=[fcsfile(index).var_name,fcsfile(index).var_value]';
    sep=cell(size(tmp(:)));
    [sep{:}]=deal(fcsfile(index).seperator);
    tmp=[tmp(:),sep]';
    fcsfile(index).fcstext=[fcsfile(index).seperator,[tmp{:}]];
    
    %remake the header section
    tmp=[char(' '.*ones(6,8-size(num2str(fcsfile(index).Offsets),2))),num2str(fcsfile(index).Offsets)]';
    fcsfile(index).fcsheader=['FCS3.0    ',tmp(:)'];
    
    %write the header
    fwrite(fid,fcsfile(index).fcsheader,'*char');
    %write text section
    fwrite(fid,' '*ones(fcsfile(index).Offsets(1)-ftell(fid),1),'*char');
    fwrite(fid,fcsfile(index).fcstext,'*char');
    %write data section
    fwrite(fid,' '*ones(fcsfile(index).Offsets(3)-ftell(fid),1),'*char');
    if strcmp(fcsfile(index).var_value(strcmp(fcsfile(index).var_name,'$BYTEORD')),'1,2,3,4')
        fwrite(fid,fcsfile(index).fcsdata','float32',0,'l');
    else
        fwrite(fid,fcsfile(index).fcsdata','float32',0,'b');
    end
    %write analysis section
    %assumes no such section
    fwrite(fid,fcsfile(index).fcsanalysis,'*char');
    
    fclose(fid);
    
end

cd(curdir);

end