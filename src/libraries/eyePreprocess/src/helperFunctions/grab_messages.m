function message_array = grab_messages(eventData,t_ms)
% this function puts the message array `eventData.name` wrt `eventData.t` timepoints into a string array `messages` wrt `t_ms` timepoints

% we start with empty string object instead of `missing` because we want to append rather than fill
message_array = repmat("", size(t_ms,1), 1);

% better assert than regret
assert(all(diff(eventData.t) >= 0), "eventData.t must be non-decreasing")
assert(all(diff(t_ms) > 0), "t_ms must be increasing");

% loop through `t_ms`, and inductively fill each cell of the new message array with the messages 
% that have passed up to that time and they were not already put in the previous cells
iEvent = 1;
for iT_ms = 1:size(t_ms,1)
    % reached the end of the `t_ms` time array; gather any last events, put them in the last cell and exit
    if iT_ms == size(t_ms,1)
        for iEvent_ = iEvent:size(eventData.t,1)
            message_array(iT_ms) =   message_array(iT_ms) + "::" + eventData.name(iEvent_) + "::";
        end
        break
    end
    % gather all previous events that have not been gathered before
    while t_ms(iT_ms) >= eventData.t(iEvent)
        message_array(iT_ms) = message_array(iT_ms) + "::" + eventData.name(iEvent) + "::";
        iEvent = iEvent + 1;
        
        % if no more events, exit
        if iEvent > size(eventData.t,1)
            break
        end
    end
    % if no more events, exit
    if iEvent > size(eventData.t,1)
        break
    end
end

%remove newline characters
message_array = regexprep(message_array,"[\n\r]+","");    

end