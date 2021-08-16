function [controller, display1, display2, display3, display4] = mmc_connect()
% FUNCTION [controller, display1, display2] = mmc_connect()
%
% Establish serial connections to the 5 arduino microcontrollers
% (controller, displays) and outputs the serial objects.
% Delete the serial object variables to disconnect.

%get list of all available serial ports
splist = serialportlist("available");

%for every available serial port, query for version #
for i = 1:length(splist)
    %start serial connection with current available port
    tmp.serial = serialport(splist(i),57600,"Timeout",5);
    pause(2);
    
    %send version query to serial object
    mmc_send_command(tmp, 'Get-version')
    pause(0.5);
    tmp = mmc_read_serial(tmp); %read and parse incoming serial data
        
    %get timestamp for program start
    mmc_send_command(tmp, 'Get-timestamp')
    while (tmp.serial.NumBytesAvailable<1)
        pause(0.01);
    end
    tmp = mmc_read_serial(tmp);
     
    if isfield(tmp,'program')
        switch tmp.program
            case 9340
                tmp.log.datenum = [];
                tmp.log.datestr = [];
                tmp.log.commandnum = [];
                tmp.log.commandname = [];
                tmp.log.duration = [];
                tmp.log.predelay = [];
                tmp.log.color1 = [];
                tmp.log.backgroundcolor = [];
                tmp.log.position = [];
                tmp.log.frequency = [];
                tmp.log.trigger = [];
                tmp.log.bytes = [];
                tmp.log.message = [];
                
                switch tmp.programnum
                    case 1
                        display1 = tmp;
                        fprintf(['Connected to display1 (version ' num2str(tmp.version) ') on ' splist{i} '\n']);
                    case 2
                        display2 = tmp;
                        fprintf(['Connected to display2 (version ' num2str(tmp.version) ') on ' splist{i} '\n']);
                    case 3
                        display3 = tmp;
                        fprintf(['Connected to display3 (version ' num2str(tmp.version) ') on ' splist{i} '\n']);
                    case 4
                        display4 = tmp;
                        fprintf(['Connected to display4 (version ' num2str(tmp.version) ') on ' splist{i} '\n']);
                    otherwise
                        warning(['unexpected program # (#' num2str(tmp.programnum)]);
                        clear tmp;
                end

            case 1000
                tmp.log.datenum = [];
                tmp.log.datestr = [];
                tmp.log.commandnum = [];
                tmp.log.commandname = [];
                tmp.log.pinnumber = [];
                tmp.log.duration = [];
                tmp.log.predelay = [];
                tmp.log.bytes = [];
                tmp.log.message = [];
                controller = tmp;
                fprintf(['Connected to controller (version ' num2str(tmp.version) ') on ' splist{i} '\n']);

            otherwise 
                clear tmp;
        end
    else
        clear tmp;
    end
end
clear tmp;

%check that all serial connections are established
assert(exist('display1','var'),'Did not detect display1');
assert(exist('display2','var'),'Did not detect display2');
assert(exist('display3','var'),'Did not detect display3');
assert(exist('display4','var'),'Did not detect display4');
assert(exist('controller','var'),'Did not detect controller');
