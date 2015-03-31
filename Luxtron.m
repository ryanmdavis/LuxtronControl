% A script for acquiring Luxtron data
%
% Ryan M Davis - rmd12@duke.edu
%
% The user should set these parameters:
%   time_between_measurements - this is how frequently the script will
%       record a temperature measurement
%   measurement_poll_frequency - after the "initiate temperature 
%       measurement"  has been given to the Luxtron, this variable tells 
%       script how often to check if the measurement is ready to be read.
%   com_port - the com port that the luxtron is connected to.  This can be
%       found under control panel --> device manager
%   save_dir - the directory where the measurements will be saved.  The
%       file name is based on the time,date that the measurements finished.  On
%       the off-chance that something goes wrong, the temperature measurements
%       are backed-up in real time in the file 'backup.mat'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% user inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
luxtron=struct('com_port',[],'measurement_poll_frequency',[],'time_between_measurements',[],'save_dir',[]);
luxtron.com_port='COM8';
luxtron.measurement_poll_frequency=1; %sec
luxtron.time_between_measurements=3; %sec
luxtron.save_dir='C:\Users\Ryan2\Documents\MATLAB\Luxtron Control\data\';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up figure for display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
luxtron.f_=figure;
drawnow;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% close previous connection to Luxtron if it is open
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
serial_ports=instrfind;
for inst_num=1:size(serial_ports,2)
    if strcmp(serial_ports(inst_num).Port,luxtron.com_port)&&strcmp(serial_ports(inst_num).Status,'open')
        fclose(serial_ports(inst_num));
    end
end
clear serial_ports inst_num

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
luxtron.s=serial(luxtron.com_port);
fopen(luxtron.s);
fprintf(luxtron.s,'E'); %enable remote mode
% fprintf(s,'R'); %enable remote run mode
fprintf(luxtron.s,'T'); %standby mode

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% remove extra data from serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while luxtron.s.bytesAvailable
    fscanf(luxtron.s);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set measurement wait - allow time for luxtron to take measurement before
% reading the temperature values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
luxtron.t_wait = timer('StartDelay',0, 'Period', luxtron.measurement_poll_frequency, 'ExecutionMode', 'fixedRate');
luxtron.t_wait.TimerFcn = {@luxtronReadCallback,luxtron.s,luxtron.f_,luxtron.t_wait,luxtron.save_dir};
tic;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set measurement timing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
luxtron.t = timer('StartDelay', 0, 'Period', luxtron.time_between_measurements, 'ExecutionMode', 'fixedRate');
luxtron.t.TimerFcn = {@luxtronTimerCallback,luxtron.s,luxtron.t_wait,luxtron.t};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up figure callback for exiting program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(luxtron.f_,'KeyPressFcn',{@luxtronKeyPressCallback,luxtron.s,luxtron.t,luxtron.t_wait,luxtron.save_dir});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize variables that hold luxtron data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
luxtron.timestamps={};
luxtron.timestamps_sec=[];
luxtron.temperature_values=[];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% start Luxtron measurements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start(luxtron.t);