% Ryan M Davis - rmd12@duke.edu
% This is a helper function for the Luxtron script

function luxtronKeyPressCallback(src,eventdata,s,t,t_wait,save_dir)

if eventdata.Key == 'q'
    disp('Terminating the measurement');
    fprintf(s,'T');
    fprintf(s,'D');
    fclose(s);
    delete(s);
    stop(t);
    delete(t);
    stop(t_wait);
    delete(t_wait);
    close(gcf);

    luxtron=evalin('base','luxtron');
    temperature_values=luxtron.temperature_values;
    timestamps_sec=luxtron.timestamps_sec;
    timestamps_sec=timestamps_sec(1:size(temperature_values,1));

    c=clock;
    year=c(1);
    month=c(2);
    day=c(3);

    file_name=strcat('Luxtron data_',num2str(month),'-',num2str(day),'-',num2str(year),'-',num2str(round(luxtron.timestamps_sec(1))));
    file_path=strcat(save_dir,file_name,'.mat');
    save(file_path,'temperature_values','timestamps_sec');
else
    display('press ''q'' to quit');
end