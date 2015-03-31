% Ryan M Davis - rmd12@duke.edu
% This is a helper function for the Luxtron script

function luxtronReadCallback(src,eventdata,s,f_,t_wait,save_dir) %#ok<INUSL>


%% read data
fprintf(s,'Q'); %enable output to RS-232 port

if (s.bytesAvailable)
    t_ret=fscanf(s);
    display_message=strcat({'At time: '},{num2str(toc)},{'  temperature was'},{t_ret});
    display(display_message{:});

    %% parse the t_ret string into four temperature probe measurements
    % find the semicolons
    temp_start=zeros(1,4);
    for probe_num=1:4
        temp_start(probe_num)=strfind(t_ret,strcat(num2str(probe_num),':'))+2;
    end

    % loop through the four probe readins in the string read from luxtron 
    % and convert to a number
    for probe_num=1:4

        % find the location of the next delimiter (semicolon or end)
        if probe_num==4 next_delimiter=size(t_ret,2); %#ok<SEPEX,NASGU>
        else next_delimeter=temp_start(probe_num+1)-1;
        end

        % now find the unit (C) if it exists
        temp_end=strfind(t_ret(temp_start(probe_num):next_delimeter),'C')+temp_start(probe_num)-2;

        % if it exists then convert the temperature string to double, otherwise
        % set it to a negative number, which will be recognized as an error
        % later in this code
        if ~isempty(temp_end)
            t(probe_num)=str2double(t_ret(temp_start(probe_num):temp_end)); %#ok<AGROW>
        else
            t(probe_num)=-1; %#ok<AGROW>
        end
    end

    %% record and plot data
    % load luxtron structure 
    luxtron=evalin('base','luxtron');

    %write the temperature values to the base workspace
    luxtron.temperature_values=[luxtron.temperature_values(1:end,:);t];
    assignin('base','luxtron',luxtron);
    
    %plot the latest temperature values
    timestamps_sec=evalin('base','luxtron.timestamps_sec');

    %determine which channels are active, and only print those channels
    channels_with_data=double(luxtron.temperature_values(1,:)>0).*(1:4);
    print_channels=channels_with_data(channels_with_data>0);

    figure(f_);
    plot(timestamps_sec-timestamps_sec(1),luxtron.temperature_values(:,print_channels));
    xlabel('time (s)','FontSize',18);
    ylabel('temperature (\circC)','FontSize',18);
    
    temperature_values=luxtron.temperature_values; %#ok<NASGU>
    save(strcat(save_dir,'\backup.mat'),'timestamps_sec','temperature_values');

    stop(t_wait);
end
