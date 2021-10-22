function fcsfile = fcsedit(fcsfile)

h=figure('MenuBar','none'...
    ,'Name','EasyFlow - Edit FCS File'...
    ,'NumberTitle','off'...
    );

righticn(:,:,1)=NaN.*ones(16,16);
righticn(:,:,2)=NaN.*ones(16,16);
righticn(:,:,3)=NaN.*ones(16,16);

righticn(7:10,2:10,2)=0.5;
righticn(4:13,11,2)=0.5;
righticn(5:12,12,2)=0.5;
righticn(6:11,13,2)=0.5;
righticn(7:10,14,2)=0.5;
righticn(8:9,15,2)=0.5;

righticn(:,:,1)=rem(1,~isnan(righticn(:,:,2)));
righticn(:,:,3)=rem(1,~isnan(righticn(:,:,2)));

th = uitoolbar(h);
uipushtool(th,'CData',righticn(:,end:-1:1,:),...
           'TooltipString','My push tool',...
           'HandleVisibility','off',...
           'ClickedCallback',@nextfile);
uipushtool(th,'CData',righticn,...
           'TooltipString','My push tool',...
           'HandleVisibility','off',...
           'ClickedCallback',@prevfile);



pos=get(h,'position');
pos(1:2)=[1 1];
table=uitable(h,...
    'Position',pos,...
    'ColumnEditable',logical([0,1]),...
    'ColumnName',{'Variable','Value'},...
    'ColumnWidth',{0,0},...
    'CellEditCallback',@changeparam);



index=1;
loadparam;
uiwait(h);

    function loadparam()
        set(table,'Data',[fcsfile(index).var_name,fcsfile(index).var_value])
        set(table,'ColumnWidth',{0,0})
        get(table,'Extent');
        floor((pos(3)-ans(3)-16)/2);
        set(table,'ColumnWidth',{ans,ans})
    end
    function changeparam(hObject,eventdata)
        data=get(table,'Data');
        %recalc the data starting position
        datastart=256 ...header size
            +1+length(data)*2+length([data{:}]) ...text size
            +5;%fill
        dataend=datastart+length(fcsfile(index).fcsdata)*4-1;
        
        data{strcmp(data(:,1),'$BEGINDATA'),2}=int2str(datastart);
        %enddata is padded to 19 chars
        tmp=char({'1234567890123456789';num2str(dataend)});
        data{strcmp(data(:,1),'$ENDDATA'),2}=tmp(2,:);
        fcsfile(index).Offsets(3)=datastart;
        fcsfile(index).Offsets(4)=dataend;
        %check that these changes don't change the sizes of the sections.
        if datastart~=256 ...header size
                +1+length(data)*2+length([data{:}]) ...text size
                +5 ...%fill
                || dataend~=datastart+length(fcsfile(index).fcsdata)*4-1
            changeparam(hObject,eventdata);
        end
        fcsfile(index).var_name=data(:,1);
        fcsfile(index).var_value=data(:,2);
    end
    function nextfile(hObject,eventData)
        index=mod(index,length(fcsfile))+1;
        loadparam;
    end
    function prevfile(hObject,eventData)
        index=mod(index-2,length(fcsfile))+1;
        loadparam;
    end

end