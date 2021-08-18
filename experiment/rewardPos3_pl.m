%load metadata
expdir = fileparts(mfilename('fullpath'));
basedir = fileparts(expdir);
currentmetadata_filename = fullfile(basedir,'temp','current_metadata.mat');
progress_filename = fullfile(basedir,'temp','setup1_progress.mat');
load(currentmetadata_filename,'metadata');
progress.string = ['Trial ' num2str(t) ' of ' num2str(num_trials)];
progress.val = 100*t/num_trials;
save_prog = 0;
while save_prog==0
    try
        save(progress_filename,'progress');
        save_prog = 1;
    catch
        pause(0.1)
        save_prog = 1;
    end
end

%set experiment parameters
rewardPos = 3;
startPos = 1;
num_trials = 30;
num_channels = 6; %number of data channels
trial_timeout = 30; %min
exp_timeout = 30; %min
prereward_dur = 0.1;
correctreward_dur = 0.1;

%connect to setup
[controller, display1, display2, display3, display4] = mmc_connect_pl(metadata.splist);

%create data and metadata struct
pretrial_start_times = nan(1,num_trials);
trial_start_times = nan(1,num_trials);
first_choice = nan(1,num_trials);
first_choice_times = nan(1,num_trials);
correct_choice_times = nan(1,num_trials);
incorrect_choice_times = nan(1,num_trials);

% run experiment
expstarttime = clock;
current_log = 1;
for t = 1:num_trials
    if exp.stop==0
        pretrial_start_times(t) = now; %log pre trial start timestamp
        
        %calculate progress of the experiment and save to progress file
        progress.string = ['Trial ' num2str(t) ' of ' num2str(num_trials)];
        progress.val = 100*t/num_trials;
        save_prog = 0;
        while save_prog==0
            try
                save(progress_filename,'progress');
                save_prog = 1;
            catch
                pause(0.1)
                save_prog = 1;
            end
        end

        pretrialstarttime = clock;

        %send stimulus to display at start position
        mmc_send_command_pl(display1, 'Display-rectangle', 'middle rectangle');

        %read sensors indefinitely
        param.duration = 0; 
        mmc_send_command_pl(controller, 'Read-sensors', param);

        %check for pokes
        end_cond = 0;
        while end_cond==0
            controller = mmc_read_serial_pl(controller);
            
            if length(controller.log)>current_log
                for i = current_log+1:length(controller.log)
                    if etime(datevec(controller.log(i).datenum), pretrialstarttime)>0
                        if strcmp(controller.log(i).commandname,'sensor read')
                            if controller.log(i).sensor==1
                                end_cond = 1;
                                give_reward = 1;
                            end
                        end
                    end
                end
                current_log = length(controller.log);
            end
            if etime(clock,expstarttime)>exp_timeout*60
                exp.stop = 1;
                give_reward = 0;
            end
            if exp.stop==1
                end_cond = 1;
                stop_trial = t;
            end
            
            pause(0.01);
        end

        %after port 1 poke: stop display and sensor reads; give reward
        mmc_send_command_pl(display1, 'Stop');
        mmc_send_command_pl(controller, 'Stop');
        if give_reward==1
            param.duration = prereward_dur; param.relay = 1; 
            mmc_send_command_pl(controller, 'Toggle-relay', param);
        end

        trialstarttime = clock;
    end
    
    if exp.stop==0
        trial_start_times(t) = now; %log reward trial start timestamp
        
        %send stimulus to display at all possible reward position
        mmc_send_command_pl(display2, 'Display-rectangle', 'middle rectangle');
        mmc_send_command_pl(display3, 'Display-rectangle', 'middle rectangle');
        mmc_send_command_pl(display4, 'Display-rectangle', 'middle rectangle');

        %read sensors indefinitely
        param.duration = 0; 
        mmc_send_command_pl(controller, 'Read-sensors', param);

        %check for pokes or trial
        end_cond = 0;
        give_reward = 0;
        while end_cond==0
            controller = mmc_read_serial_pl(controller);

            if length(controller.log)>current_log
                for i = current_log+1:length(controller.log)
                    if etime(datevec(controller.log(i).datenum),trialstarttime)>0
                        if strcmp(controller.log(i).commandname,'sensor read')
                            current_time = now;
                            if controller.log(i).sensor == rewardPos
                                if isnan(first_choice(t))
                                    first_choice(t) = 1;
                                    first_choice_times(t) = current_time;
                                end
                                correct_choice_times(t) = current_time;
                                end_cond = 1;
                                give_reward = 1;
                            elseif controller.log(i).sensor ~= startPos
                                if isnan(first_choice(t))
                                    first_choice(t) = 0;
                                    first_choice_times(t) = current_time;
                                end
                                num_incorrect_pokes = sum(~isnan(incorrect_choice_times(:,t)));
                                if size(incorrect_choice_times,1)<(num_incorrect_pokes+1)
                                    incorrect_choice_times(end+1,:) = nan;
                                end
                                incorrect_choice_times(num_incorrect_pokes+1,t) = current_time;
                            end
                        end
                    end
                end
                current_log = length(controller.log);
            end
            if etime(clock,trialstarttime)>(trial_timeout*60)
                end_cond = 1;
                stop_trial = t;
            end
            if exp.stop==1
                end_cond = 1;
                stop_trial = t;
            end
            pause(0.01);
        end
            
        %after port correct poke or timeout: stop display and sensor reads; give reward
        mmc_send_command_pl(display2, 'Stop');
        mmc_send_command_pl(display3, 'Stop');
        mmc_send_command_pl(display4, 'Stop');
        mmc_send_command_pl(controller, 'Stop');
        if give_reward==1
            param.duration = correctreward_dur; param.relay = rewardPos; 
            mmc_send_command(controller, 'Toggle-relay', param);
        end
    else
        mmc_send_command_pl(display2, 'Stop');
        mmc_send_command_pl(display3, 'Stop');
        mmc_send_command_pl(display4, 'Stop');
        mmc_send_command_pl(controller, 'Stop');
        
        progress.string = ['Experiment stopped at trial ' num2str(stop_trial)];
        progress.val = 100*stop_trial/num_trials;
        save_prog = 0;
        while save_prog==0
            try
                save(progress_filename,'progress');
                save_prog = 1;
            catch
                pause(0.1)
                save_prog = 1;
            end
        end
    end
end 

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
exp.pretrial_start_time = pretrial_start_times;
exp.trial_start_times = trial_start_times;
exp.first_choice = first_choice;
exp.first_choice_times = first_choice_times;
exp.correct_choice_times = correct_choice_times;
exp.incorrect_choice_times = incorrect_choice_times;

save(metadata.savedir,'exp');

%calculate progress of the experiment and update GUI
timestr = datestr(now,'HH:MM');
progress.string = ['Experiment complete (' timestr ')'];
progress.val = 100;
save_prog = 0;
while save_prog==0
    try
        save(progress_filename,'progress');
        save_prog = 1;
    catch
        pause(0.1)
        save_prog = 1;
    end
end

        