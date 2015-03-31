function luxtronTimerCallback(obj,event,s,t_wait,t)

% if we still have not read the previous measurement, then the readings are
% occuring too fast
if strcmp(t_wait.Running,'on')
    stop(t_wait);
    stop(t);
    error('You are sampling temperature too quickly.  Increase time_between_measurements or decrease measurement_poll_frequency');
end

% remove extra data from serial port
while s.bytesAvailable
    fscanf(s);
end

fprintf(s,'I'); %initiate temperature measurement

c=clock;
time_at_start_of_meas=strcat(num2str(c(4)),':',num2str(c(5)),':',num2str(c(6)));
time_at_start_of_meas_sec=60^2*c(4)+60*c(5)+c(6);

% load luxtron structure
luxtron=evalin('base','luxtron');

% save time
luxtron.timestamps={luxtron.timestamps{1:end},time_at_start_of_meas};

% save number of seconds
luxtron.timestamps_sec=[luxtron.timestamps_sec(1:end),time_at_start_of_meas_sec];

% save data back in workspace
assignin('base','luxtron',luxtron);

% start the timer for reading
start(t_wait);