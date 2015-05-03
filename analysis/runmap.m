function experim_json = runmap(experiment_name,experim_json)
% SUPPLY Compute the supply of the set of tasks

    %% If already executed, do not run
    if (ismember('results',fieldnames(experim_json.global)))
        if (ismember('runmap',fieldnames(experim_json.global.results)))
            return
        end
    end

    %% Conclusion
    savejson('',experim_json,strcat(experiment_name,'.output.json'));    
end