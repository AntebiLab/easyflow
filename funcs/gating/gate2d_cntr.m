function gate=gate2d_cntr(gate,data,datay,gatecoly,outcol)
%GATE2D create a two dimensional gate for facs measurments using the contours.
%   GATE=GATE2D_cntr
%   Uses the current plot to define a two dimensional gate based on a
%   density contour plot.
%   You can click to select a contour line or use arrows to move it
%   up/down. Hold the shift key to finely adjust. To choose right click
%   within the contour.
%
%gate2d
%   create ptope for the data ploted in gca
%gate2d(gate)
%   edit the gate given with the data plotted in gca

WBDF = get(gcf,'WindowButtonDownFcn');
WBUF = get(gcf,'WindowButtonUpFcn');
WBMF = get(gcf,'WindowButtonMotionFcn');
pntr = get(gcf,'Pointer');

switch nargin
    case 0
        gate=gate2d_create;
    case 1
        gate=gate2d_create(gate);
end

set(gcf,'WindowButtonDownFcn', WBDF);
set(gcf,'WindowButtonUpFcn', WBUF);
set(gcf,'WindowButtonMotionFcn', WBMF);
set(gcf,'Pointer', pntr);

    function gate=gate2d_create(gate)
        %first get all data oints from current axis
        xpt=get(findobj(gca,'Type','line'),'XData');
        ypt=get(findobj(gca,'Type','line'),'YData');
        if iscell(xpt)
            xpt=[xpt{:}];
        end
        if iscell(ypt)
            ypt=[ypt{:}];
        end
        %generate the log density matrix
        [dm,xmesh,ymesh]=(density([xpt(:),ypt(:)]));
        dm=log(dm);
        hold on
        [C,h]=contour(xmesh,ymesh,dm);
        hold off
        hv=line('Visible','off');
        Cv=[];
        dmv=min(dm(:));
        
        %some variables to be used later
        stepsize=range(dm(:))/20;
        dmax=max(dm(:));
        dmin=min(dm(:));
        ah=gca;
        %make the boundaries minimal
        dm(1,:)=dmin;
        dm(end,:)=dmin;
        dm(:,1)=dmin;
        dm(:,end)=dmin;
        
        switch nargin
            case 0
                gate=[];
                wbdf=get(gcf,'WindowButtonDownFcn');
                wkpf=set(gcf,'WindowKeyPressFcn');
                set(gcf,'Pointer','crosshair')
                
                set(gcf,'WindowButtonDownFcn',@btndown)
                set(gcf,'WindowKeyPressFcn',@keypress)
                set(gcf,'Pointer','crosshair')
            case 1
        end
        uiwait;
        
        function btndown(src,evnt)
            if strcmp(get(src,'SelectionType'),'normal')
                %select specific contour
                delete(hv);
                p=get(ah,'CurrentPoint');
                [xv,xv]=min(abs(xmesh(1,:)-p(1,1)));
                [yv,yv]=min(abs(ymesh(:,1)-p(1,2)));
                dmv=dm(yv,xv);
                hold on
                [Cv,hv]=contour(xmesh,ymesh,dm,[dmv,dmv]);
                hold off
                set(hv,'linewidth',3)
                set(hv,'linecolor','k')
            elseif strcmp(get(src,'SelectionType'),'alt')
                %select the clicked contour
                p=get(ah,'CurrentPoint');
                idx=1;
                csize=[];
                while idx<size(Cv,2)
                    csize(end+1,1)=idx+1;
                    csize(end,2)=idx+Cv(2,idx);
                    idx=idx+1+Cv(2,idx);
                end
                isin=[];
                for i=1:size(csize,1)
                    isin(i)=inpolygon(p(1,1),p(1,2),Cv(1,csize(i,1):csize(i,2)),Cv(2,csize(i,1):csize(i,2)));
                end
                if sum(isin)~=1
                    %in more than one or on the boundary of two
                    return
                end
                gate=Cv(:,csize(isin==1,1):csize(isin==1,2));
                
                
                hold on
                delete(h);
                delete(hv);
                plot(gate(1,:),gate(2,:),'r');
                hold off
                set(src,'WindowButtonDownFcn',wbdf)
                set(gcf,'WindowKeyPressFcn',wkpf)
                set(src,'Pointer','Arrow')
                uiresume;
            end
            
        end
        function keypress(src,evnt)
            if isempty(evnt.Modifier)
                if strcmp(evnt.Key,'f1')
                    %show help
                    msgbox({'You can click to select a contour line or use arrows to move it up/down.',...
                        'Hold the shift key to finely adjust.',...
                        'To select - right click within the contour.'}...
                        ,'EasyFlow','help','modal');
                    uiwait;
                end
                if strcmp(evnt.Key,'uparrow')
                    %move contour
                    delete(hv);
                    dmv=min(dmv+stepsize,dmax);
                    hold on
                    [Cv,hv]=contour(xmesh,ymesh,dm,[dmv,dmv]);
                    hold off
                    set(hv,'linewidth',3)
                    set(hv,'linecolor','k')
                end
                if strcmp(evnt.Key,'downarrow')
                    %move contour
                    delete(hv);
                    dmv=max(dmv-stepsize,dmin);
                    hold on
                    [Cv,hv]=contour(xmesh,ymesh,dm,[dmv,dmv]);
                    hold off
                    set(hv,'linewidth',3)
                    set(hv,'linecolor','k')
                end
            end
            if strcmp(evnt.Modifier,'shift')
                if strcmp(evnt.Key,'uparrow')
                    %move contour
                    delete(hv);
                    dmv=min(dmv+stepsize/20,dmax);
                    hold on
                    [Cv,hv]=contour(xmesh,ymesh,dm,[dmv,dmv]);
                    hold off
                    set(hv,'linewidth',3)
                    set(hv,'linecolor','k')
                end
                if strcmp(evnt.Key,'downarrow')
                    %move contour
                    delete(hv);
                    dmv=max(dmv-stepsize/20,dmin);
                    hold on
                    [Cv,hv]=contour(xmesh,ymesh,dm,[dmv,dmv]);
                    hold off
                    set(hv,'linewidth',3)
                    set(hv,'linecolor','k')
                end
            end
        end
    end
end