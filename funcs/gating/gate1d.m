function gate=gate1d(gate,data,gatecol,outcol)
%GATE1D create and edit a one dimensional gate for facs measurments.
%   GATE=GATE1D
%   GATE is [min max height] values for the gate. the user need to click on two
%   points (the min and the max). right click uses Inf.
%
%gate1d
%   create ptope for the data ploted in gca
%gate1d(gate)
%   edit the gate given with the data plotted in gca
%gate1d(gate,data)
%   filters the data according to the gate returns logical places where the
%   data passed the gate
%gate1d(gate,data,gatecol)
%   filters the data in column gatecol according to the gate returns 
%   logical places where the data passed the gate
%gate1d(gate, data, gatecol, outcol)
%   return the data in column outcol whenever the data in gatecol passes
%   the gate.

WBDF = get(gcf,'WindowButtonDownFcn');
WBUF = get(gcf,'WindowButtonUpFcn');
WBMF = get(gcf,'WindowButtonMotionFcn');
pntr = get(gcf,'Pointer');

switch nargin
    case 0
        gate=gate1d_create;
    case 1
        gate=gate1d_create(gate);
    case 2
        gate=gate1d_apply(gate,data);
    case 3
        gate=gate1d_apply(gate,data(:,gatecol));
    case 4
        gatelogical=gate1d_apply(gate,data(:,gatecol));
        gate=data(gatelogical,outcol);
end

set(gcf,'WindowButtonDownFcn', WBDF);
set(gcf,'WindowButtonUpFcn', WBUF);
set(gcf,'WindowButtonMotionFcn', WBMF);
set(gcf,'Pointer', pntr);

    function gate=gate1d_create(gate)
        lh=line('Visible','off');
        ah=gca;
        values=axis;
        nearx=0.01*(values(2)-values(1));
        neary=0.01*(values(4)-values(3));
        editid=0;
        
        switch nargin
            case 0
                xdat=[];
                ydat=[];
                set(gcf,'WindowButtonDownFcn',@btndown)
                set(gcf,'WindowButtonUpFcn','')
                set(gcf,'WindowButtonMotionFcn','')
                set(gcf,'Pointer','crosshair')
            case 1
                editid=1;
                xdat=gate(1:2);
                ydat=[gate(3),gate(3)];
                set(lh,'XData',xdat,'YData',ydat,'Marker','+','Color','r','Visible','on');
                set(gcf,'WindowButtonMotionFcn',@selectchange)
                set(gcf,'WindowButtonUpFcn','')
                set(gcf,'WindowButtonDownFcn',@exitfcn)
        end
        uiwait;
        
        gate=[min(xdat),max(xdat),ydat(1)];
        
        function btndown(src,evnt)
            p=get(ah,'CurrentPoint');
            if strcmp(get(src,'SelectionType'),'normal')
                xdat = p(1,1);
                ydat = p(1,2);
                set(lh,'XData',xdat,'YData',ydat,'Marker','+','Color','r','Visible','on');
                set(src,'WindowButtonMotionFcn',@move)
                set(gcf,'WindowButtonUpFcn',@btnup)
            end
            
        end
        function btnup(src,evnt)
            p=get(ah,'CurrentPoint');
            if strcmp(get(src,'SelectionType'),'normal')
                xdat = [xdat,p(1,1)];
                ydat = [ydat,ydat];
                set(lh,'XData',xdat,'YData',ydat,'Marker','+','Color','r');
                set(gcf,'WindowButtonMotionFcn',@selectchange)
            end
            if editid==0
                set(src,'WindowButtonDownFcn','')
                set(src,'WindowButtonMotionFcn','')
                set(src,'Pointer','Arrow')
                uiresume;
            end
            set(src,'WindowButtonUpFcn','')
        end
        function move(src,evnt)
            p=get(ah,'CurrentPoint');
            set(lh,'XData',[xdat,min(max(p(1,1),values(1)),values(2))],'YData',[ydat,ydat],'Marker','+','Color','r');
        end
        function clickchange(src,evnt)
            p=get(ah,'CurrentPoint');
            if strcmp(get(src,'SelectionType'),'normal')
                if abs(p(1,1)-xdat(1)) < abs(p(1,1)-xdat(2))
                    xdat=xdat(2);
                else
                    xdat=xdat(1);
                end
                ydat = ydat(1);
                set(lh,'XData',[xdat,min(max(p(1,1),values(1)),values(2))],'YData',[ydat,ydat],'Marker','+','Color','r');
                set(src,'WindowButtonMotionFcn',@move)
                set(gcf,'WindowButtonUpFcn',@btnup)
            end
            
        end
        function selectchange(src,evnt)
            p=get(ah,'CurrentPoint');
            if abs(p(1,1)-xdat(1)) < abs(p(1,1)-xdat(2)) && abs(p(1,1)-xdat(1)) < nearx && abs(p(1,2)-ydat(1)) < neary
                set(gcf,'WindowButtonDownFcn',@clickchange)
                set(gcf,'Pointer','left')
            elseif abs(p(1,1)-xdat(1)) > abs(p(1,1)-xdat(2)) && abs(p(1,1)-xdat(2)) < nearx && abs(p(1,2)-ydat(2)) < neary
                set(gcf,'WindowButtonDownFcn',@clickchange)
                set(gcf,'Pointer','right')
            else
                set(gcf,'WindowButtonDownFcn',@exitfcn)
                set(gcf,'Pointer','Arrow')
            end
            
        end
        function exitfcn(src,evnt)
            if strcmp(get(src,'SelectionType'),'alt')
                set(src,'WindowButtonDownFcn','')
                set(src,'WindowButtonUpFcn','')
                set(src,'WindowButtonMotionFcn','')
                uiresume;
            end
        end
    end
    function gatelogical=gate1d_apply(gate,data)
        
        gatelogical=and(data>gate(1),data<gate(2));
        
    end
end
