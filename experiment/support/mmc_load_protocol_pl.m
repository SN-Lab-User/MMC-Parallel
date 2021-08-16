function protocol = mmc_load_protocol(experiment_name, setup)

switch experiment_name
    case 'testexp_1'
        protocol.reps = 30;
        protocol(1).startfunction{1} = ['mmc_send_command(setup' setup '.display1, ''Display-rectangle'', ''middle rectangle'');'];
        protocol(1).startfunction{2} = ['param.duration = 0; mmc_send_command(setup' setup '.controller, ''Read-sensors'', param);'];
        protocol(1).endpoke = 1;
        protocol(1).endduration = [];
        protocol(1).endfunction{1} = ['mmc_send_command(setup' setup '.display1, ''Stop'');'];
        protocol(1).endfunction{2} = ['mmc_send_command(setup' setup '.controller, ''Stop'');'];
        protocol(1).endfunction{3} = ['param.duration = 1; param.relay = 1; mmc_send_command(controller, ''Toggle-relay'', param);'];
        
        protocol(2).startfunction{1} = ['mmc_send_command(setup' setup '.display3, ''Display-rectangle'', ''middle rectangle'');'];
        protocol(2).startfunction{2} = ['param.duration = 0; mmc_send_command(setup' setup '.controller, ''Read-sensors'', param);'];
        protocol(2).endpoke = 3;
        protocol(2).endduration = 10;
        protocol(2).endfunction{1} = ['mmc_send_command(setup' setup '.display3, ''Stop'');'];
        protocol(1).endfunction{2} = ['mmc_send_command(setup' setup '.controller, ''Stop'');'];
        protocol(2).endfunction{3} = ['param.duration = 1; param.relay = 3; mmc_send_command(setup' setup '.controller, ''Toggle-relay'', param);'];
        
    case 'testexp_2'
        protocol.reps = 30;
        protocol(1).startfunction{1} = ['mmc_send_command(setup' setup '.display1, ''Display-rectangle'', ''middle rectangle'');'];
        protocol(1).endpoke = 1;
        protocol(1).endduration = [];
        protocol(1).endfunction{1} = ['mmc_send_command(setup' setup '.display1, ''Stop'');'];
        protocol(1).endfunction{2} = ['param.duration = 1; param.relay = 1; mmc_send_command(setup' setup '.controller, ''Toggle-relay'', param);'];
        
        protocol(2).startfunction{1} = ['mmc_send_command(setup' setup '.display4, ''Display-rectangle'', ''middle rectangle'');'];
        protocol(2).endpoke = 4;
        protocol(2).endduration = 10;
        protocol(2).endfunction{1} = ['mmc_send_command(setup' setup '.display4, ''Stop'');'];
        protocol(2).endfunction{2} = ['param.duration = 1; param.relay = 4; mmc_send_command(setup' setup '.controller, ''Toggle-relay'', param);'];
        
end