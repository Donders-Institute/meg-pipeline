function dataout = eyelink_gaze2degree(cfg, datain)

% EYELINK_GAZE2DEGREE converts an eyelink gaze signals into degrees of
% visual angle, relative to the center of the screen.
% It assumes the gaze channels to be called gazeX and gazeY.

% cfg = ft_checkconfig(cfg, 'required', {'display' 'screensize', 'screendist'});
cfg = ft_checkconfig(cfg, 'required', {'screensize', 'screendist'});

cfg.display = ft_getopt(cfg, 'display', [1920 1080]); % width x height
pixpercmX   = cfg.display(1)./cfg.screensize(1);
pixpercmY   = cfg.display(2)./cfg.screensize(2);

xchan = match_str(datain.label, 'gazeX');
ychan = match_str(datain.label, 'gazeY');
assert(numel(xchan)==1 && numel(ychan)==1); % only one eye can be processed at the time

dataout = datain;
for k = 1:numel(dataout.trial)
  X = datain.trial{k}(xchan, :) - cfg.display(1)./2; % relative to center
  Y = datain.trial{k}(ychan, :) - cfg.display(2)./2;
  
  % convert into cm
  X = X./pixpercmX;
  Y = Y./pixpercmY;
  R = sqrt(X.^2 + Y.^2);

  % convert into tangens
  Ydat = [X;Y;R];
  Xdat = cfg.screendist.*ones(size(Ydat));
  
  dataout.trial{k} = atan2d(Ydat, Xdat);
end

dataout.label = {'degX';'degY';'degR'};
