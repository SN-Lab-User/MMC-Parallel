global exp

reward_dur = 0.1;

%connect to setup
[controller, display1, display2, display3, display4] = mmc_connect();
         
%calculate progress of the experiment and update GUI
progress_text = 'Running pre-test';
app.ProgressTextLabel.Text = progress_text;
progress = 100;
app.ph.XData = [0 progress progress 0]; 
drawnow %update graphics    
reading = 0;

while exp.stop==0
    %read sensors indefinitely
    if reading==0
        starttime = clock;
        param.duration = 0;
        mmc_send_command(controller, 'Read-sensors', param);
        reading = 1;
    end
    
    %check for pokes
    controller = mmc_read_serial(controller);

    for i = length(controller.log)
        if etime(datevec(controller.log(i).datenum), starttime)>0
            if strcmp(controller.log(i).commandname,'sensor read')
                mmc_send_command(controller, 'Stop');
                reading = 0;
                param.duration = reward_dur; param.relay = controller.log(i).sensor; 
                switch controller.log(i).sensor
                    case 1
                         mmc_send_command(display1, 'Display-rectangle', 'middle rectangle 1s');
                         mmc_send_command(controller, 'Toggle-relay', param);
                    case 2
                         mmc_send_command(display2, 'Display-rectangle', 'middle rectangle 1s');
                         mmc_send_command(controller, 'Toggle-relay', param);
                    case 3
                         mmc_send_command(display3, 'Display-rectangle', 'middle rectangle 1s');
                         mmc_send_command(controller, 'Toggle-relay', param);
                    case 4
                         mmc_send_command(display4, 'Display-rectangle', 'middle rectangle 1s');
                         mmc_send_command(controller, 'Toggle-relay', param);
                end
            end
        end
    end
    pause(0.01);
end 
mmc_send_command(display1, 'Display-rectangle', 'middle rectangle 1s');
mmc_send_command(display2, 'Display-rectangle', 'middle rectangle 1s');
mmc_send_command(display3, 'Display-rectangle', 'middle rectangle 1s');
mmc_send_command(display4, 'Display-rectangle', 'middle rectangle 1s');
mmc_send_command(controller, 'Stop');

%save exp struct
exp.controller = controller;
exp.display1 = display1;
exp.display2 = display2;
exp.display3 = display3;
exp.display4 = display4;
exp.controller.serial = '';
exp.display1.serial = '';
exp.display2.serial = '';
exp.display3.serial = '';
exp.display4.serial = '';
save(exp.metadata.savedir,'exp');
clear all
