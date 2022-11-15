function dataout = eyelink_voltage2gaze(cfg, datain)

% EYELINK_VOLTAGE2GAZE converts a ADC Voltage signal from eyelink data to a
% gaze signal (expressed in pixels), according to the SR-research
% documentation:
%
% R     = (voltage - minvoltage)/(maxvoltage - minvoltage)
% S     = R*(maxrange - minrange) + minrange
% Xgaze = S*(screenright  - screenleft + 1) + screenleft
% Ygaze = S*(screenbottom - screentop  + 1) + screentop

%cfg = ft_checkconfig(cfg, 'required', {'analog_dac_range', 'analog_x_range', 'analog_y_range' 'display'});

cfg.analog_dac_range = ft_getopt(cfg, 'analog_dac_range', [-5 5]);
cfg.analog_x_range   = ft_getopt(cfg, 'analog_x_range',   [0 1]);
cfg.analog_y_range   = ft_getopt(cfg, 'analog_y_range',   [0 1]);
cfg.display          = ft_getopt(cfg, 'display',          [0 0 1919 1079]);

minvoltage = cfg.analog_dac_range(1);
maxvoltage = cfg.analog_dac_range(2);
minrangeX  = cfg.analog_x_range(1);
maxrangeX  = cfg.analog_x_range(2);
minrangeY  = cfg.analog_y_range(1);
maxrangeY  = cfg.analog_y_range(2);
screenleft = cfg.display(1);
screentop  = cfg.display(2);
screenright = cfg.display(3);
screenbottom = cfg.display(4);

xchan = match_str(datain.label, {'UADC005';'UADC008'});
ychan = match_str(datain.label, {'UADC006';'UADC009'});

dataout = datain;
for k = 1:numel(dataout.trial)
  voltage = datain.trial{k}(xchan, :);
  R       = (voltage - minvoltage)/(maxvoltage - minvoltage);
  S       = R*(maxrangeX - minrangeX) + minrangeX;
  Xgaze   = S*(screenright  - screenleft + 1) + screenleft;
  dataout.trial{k}(xchan, :) = Xgaze;

  voltage = datain.trial{k}(ychan, :);
  R       = (voltage - minvoltage)/(maxvoltage - minvoltage);
  S       = R*(maxrangeY - minrangeY) + minrangeY;
  Ygaze   = S*(screenbottom - screentop  + 1) + screentop;
  dataout.trial{k}(ychan, :) = Ygaze;
end

if numel(xchan)==1
  % rename
  dataout.label{xchan} = 'gazeX';
end

if numel(ychan)==1
  dataout.label{ychan} = 'gazeY';
end

