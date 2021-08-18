function splists = mmc_detect_pl()
% FUNCTION splists = mmc_detect_pl()
%
% Search through all connected serial ports to find all serial components
% controller, displays) for each MMC setup

%get list of all available serial ports
if nargin==0
    splist = serialportlist("available");
end
splists = strings(5,8); %5 devices per setup; 8 setups max

%for every available serial port, query for version #
for i = 1:length(splist)
    %start serial connection with current available port
    tmp.serial = serialport(splist(i),57600,"Timeout",5);
    pause(2);
    
    %send version query to serial object
    mmc_send_command_pl(tmp, 'Get-version')
    pause(0.5);
    tmp = mmc_read_serial_pl(tmp); %read and parse incoming serial data
    
    if isfield(tmp,'program')
        switch tmp.program
            case 9340
                if ~any(tmp.programnum==1:40)
                    warning(['unexpected program # (' num2str(tmp.programnum) ')']);
                end
                setupNum = ceil(tmp.programnum/5);
                deviceNum = mod(tmp.programnum-1,4)+1;
                splists(deviceNum+1,setupNum) = splist(i);

            case 1000
                if ~any(tmp.programnum==[1:8])
                    warning(['unexpected program # (' num2str(tmp.programnum) ')']);
                end
                splists(1,tmp.programnum) = splist(i);
                
            otherwise 
                clear tmp;
        end
    else
        clear tmp;
    end
end
clear tmp;
