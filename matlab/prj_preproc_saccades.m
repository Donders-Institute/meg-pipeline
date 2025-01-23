function [datvel, artifact, boolvec] = prj_preproc_saccades(dat, opts)

% PRJ_PREPROC_SACCADES serves the purpose as a custom function to be
% called in preproc, in order to maximize sensitivity to the features of a
% saccade.
% 
% The processing is as follows:
%  - 1. remove slow trend, (optional)
%  - 2. apply a median filter
%  - 3. compute the velocity (first derivative)
%  - 4. peak detection on the velocity signal (with a minimum threshold,
%  and a minimum peak distance -> relying on findpeaks function from signal
%  processing toolbox)

persistent counter

if isempty(counter)
  counter = 1;
end

if nargin<2
  opts = [];
end

opts.fsample = ft_getopt(opts, 'fsample');
if isempty(opts.fsample)
  ft_error('sampling frequency needs to be specified');
end

opts.demean        = ft_getopt(opts, 'demean', 0);
opts.smooth        = ft_getopt(opts, 'smooth', []); % optional smoothing parameter for first step boxcar smoothing, in s
opts.medfiltord    = ft_getopt(opts, 'medfiltord', 0.05); % median filter order, in s
opts.peakthreshold = ft_getopt(opts, 'peakthreshold', 30); % threshold parameter for velocity detection
opts.peakdistance  = ft_getopt(opts, 'peakdistance', 0.1);

opts.pretim        = ft_getopt(opts, 'pretim',  0.025);
opts.posttim       = ft_getopt(opts, 'posttim', 0.050);
opts.mask          = ft_getopt(opts, 'mask',    {});

datorig = dat;

% apply a little bit of padding; FIXME number of samples is currently hardcoded
padsmp = round(opts.fsample./40);
dat = ft_preproc_padding(dat, 'localmean', padsmp, padsmp);

% demean the signal
if opts.demean
  dat = dat - mean(dat);
end

[m,n] = size(dat);
% if m>1
%   error('only a single signal is allowed');
% end

% 1
if ~isempty(opts.smooth)
  smoothsmp1 = round(opts.fsample.*opts.smooth);
  dat        = dat - ft_preproc_smooth(dat, smoothsmp1);
end

% 2
if ~isempty(opts.medfiltord)
  medfiltord = 2.*round(0.5.*opts.fsample.*opts.medfiltord)+1; % should be odd-valued
  datm       = ft_preproc_medianfilter(dat, medfiltord);
else
  datm = dat;
end

% 3: compute velocity signal
dat  = [mean(datm(:,1:3),2)*ones(1,3) datm mean(datm(:,end-2:end),2)*ones(1,3)]; % extra pad to deal with derivative artifacts
datvel = convn(dat, [0.5 0 -0.5], 'same'); % first derivative = velocity
%datacc = convn(dat, [1 -2 1],     'same'); % second derivative = acceleration

datvel = datvel(:,4:end-3).*opts.fsample;
%datacc = datacc(:,4:end-3).*(opts.fsample^2);

if ~isempty(opts.mask)
  mask = ft_preproc_padding(opts.mask{counter}, 'edge', padsmp, padsmp);
  datvel(:,mask~=0) = nan;
end

if nargout>1
  [p, ix] = findpeaks(sqrt(sum(datvel.^2,1)), 'MinPeakHeight', opts.peakthreshold, 'MinPeakDistance', round(opts.fsample.*opts.peakdistance));
  ix      = ix-padsmp;

  on  = ix(:) - round(opts.fsample.*opts.pretim);
  off = ix(:) + round(opts.fsample.*opts.posttim);
  offset = -ix(:);


  artifact = [max(on, 1) min(off, size(datorig,2)) offset];

  datvel  = datvel(:,(padsmp+1):(end-padsmp)); % un-pad, this can be done with ft_preproc_padding
  boolvec = trl2boolvec(artifact, 'endsample', size(datorig,2));
else
  datvel = sqrt(sum(datvel(:,(padsmp+1):(end-padsmp)).^2,1));
end

n = max(numel(opts.mask), 1);
counter = counter + 1;
if counter>n
  counter = 1;
end

function boolvec = trl2boolvec(trl, varargin)

% TRL2BOOLVEC converts between two representations of events or trials.
%
% FieldTrip uses a number of representations for events that are conceptually very similar
%   event    = structure with type, value, sample, duration and offset
%   trl      = Nx3 numerical array with begsample, endsample, offset
%   trl      = table with 3 columns for begsample, endsample, offset
%   artifact = Nx2 numerical array with begsample, endsample
%   artifact = table with 2 columns for begsample, endsample
%   boolvec  = 1xNsamples boolean vector with a thresholded TTL/trigger sequence
%   boolvec  = MxNsamples boolean matrix with a thresholded TTL/trigger sequence
%
% If trl or artifact are represented as a MATLAB table, they can have additional
% columns. These additional columns have to be named and are not restricted to
% numerical values.
%
% See also ARTIFACT2BOOLVEC, ARTIFACT2EVENT, ARTIFACT2TRL, BOOLVEC2ARTIFACT, BOOLVEC2EVENT, BOOLVEC2TRL, EVENT2ARTIFACT, EVENT2BOOLVEC, EVENT2TRL, TRL2ARTIFACT, TRL2BOOLVEC, TRL2EVENT

% Copyright (C) 2009, Ingrid Nieuwenhuis
% Copyright (C) 2020, Robert Oostenveld
%
% This file is part of FieldTrip, see http://www.fieldtriptoolbox.org
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id$

% get the optional input arguments or set defaults
endsample = ft_getopt(varargin, 'endsample', []);

if isempty(endsample)
  if istable(trl)
    endsample = max(trl{:,2});
  elseif isnumeric(trl)
    endsample = max(trl(:,2));
  end
end

if isnumeric(trl)
  boolvec = false(1, endsample);
  begsample = trl(:,1);
  endsample = trl(:,2);
  for j=1:length(begsample)
    boolvec(1, begsample(j):endsample(j)) = true;
  end
elseif istable(trl)
  boolvec = false(1, endsample);
  if ~isempty(trl)
    begsample = trl.begsample;
    endsample = trl.endsample;
  else
    % an empty table does not contain any columns
    begsample = [];
    endsample = [];
  end
  for j=1:length(begsample)
    boolvec(1, begsample(j):endsample(j)) = true;
  end
elseif iscell(trl)
  if ~isempty(trl)
    % use recursion
    for i=1:numel(trl)
      boolvec(i,:) = trl2boolvec(trl{i}, varargin{:});
    end
  else
    % return an empty array of the expected length
    boolvec = zeros(0, endsample);
  end
end
