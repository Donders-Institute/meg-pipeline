function trlout = prj_util_epochtrl(trlin, fsample, maxdur)

% PRJ_UTIL_EPOCHTRL is a utility function that converts the epochs, defined
% in the input trl-matrix into slightly overlapping 5 second epochs. This
% can be useful for artifact detection purposes. If the respective input
% epoch is shorter than 4 seconds, it is left unaffected.
%
% use as
%  
%   trlout = prj_util_epochtrl(trlin, [fsample], [maxdur])
%
% where trlin is an Nx3 FieldTrip style trl matrix, and the optional
% fsample reflects the sampling rate of the raw data (default: 1200 Hz).
% The optional maxdur is the length of the chunks (default: 5 s).

if nargin<2 || isempty(fsample)
  fsample = 1200;
end

if nargin<3
  maxdur = 5;
end

if istable(trlin)
  trlin = table2array(trlin(:,1:3));
end

nsmp = maxdur*fsample;
stepsize = round(0.95*nsmp);

trlout = zeros(0,3);
for k = 1:size(trlin, 1)
  thistrl  = trlin(k, 1:3);
  if thistrl(2) - thistrl(1) + 1 > nsmp
    tmp = [];
    tmp(:,1) = (thistrl(1):stepsize:thistrl(2))';
    tmp(:,2) = tmp(:,1) + nsmp - 1;
    tmp(:,3) = 0;

    % do not go beyond the boundary of the input epoch
    tmp(tmp(:,2)>thistrl(2),2) = thistrl(2);
    
    % make the last one a bit longer, if too short
    if tmp(end,2)-tmp(end,1)-1 < nsmp/4
      tmp(end,2) = tmp(end,2) - round(nsmp/2);
    end
    
    trlout = cat(1, trlout, tmp);
  else
    trlout = cat(1, trlout, thistrl);
  end
end
