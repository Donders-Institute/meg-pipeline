function cfg = prj_util_artifactdetect_saccades(dataset, trl, channel, blinkartifact)

% clear the persistent variable in the lower-level function. Note that this
% is a bit of a hacky solution, to allow a blink mask to be passed to the
% function (and to be correctly applied). The function preproc loops across
% input trials, but cannot pass additional trial-specific information (e.g.
% said blink mask). In order to be able to apply it, prj_preproc_saccades
% keeps track of a counter, which indexes the current trial. It is
% important that this variable is cleared (only once) before a new outer
% loop across trials is executed. Note that if you have renamed the
% prj_preproc_saccades function, you need to change the below line as well.
clear prj_preproc_saccades

if nargin<3 || isempty(channel)
  channel = 'UADC005';
end

if nargin>3
  createmask = true;
end

trltmp = prj_util_epochtrl(trl);

cfg                                = [];
cfg.dataset                        = dataset;
cfg.trl                            = trltmp;
cfg.continuous                     = 'yes';
cfg.memory                         = 'high';

hdr = ft_read_header(cfg.dataset);

opts = [];
opts.fsample = hdr.Fs;
opts.medfiltord = 0.05;

if createmask
  boolvec = artifact2boolvec(blinkartifact, 'endsample', hdr.nSamples.*hdr.nTrials);
  
  tmpdata          = [];
  tmpdata.trial{1} = boolvec;
  tmpdata.time{1}  = (1:numel(boolvec))./hdr.Fs;
  tmpdata.label    = {'boolvec'};

  tmpcfg     = [];
  tmpcfg.trl = trl;
  tmpdata    = ft_redefinetrial(tmpcfg, tmpdata);
  opts.mask  = tmpdata.trial;
end

% processing heuristics for the optimal detection of (lateral) saccades, assuming
% that channel is the name of an EOG channel, or the name of the analog
% eyetracker channel that measured the x-position of the eye
cfg.artfctdef.zvalue.channel         = channel;
cfg.artfctdef.zvalue.cutoff          = 1.5;
cfg.artfctdef.zvalue.interactive     = 'yes';
cfg.artfctdef.zvalue.custom.funhandle = @prj_preproc_saccades;
cfg.artfctdef.zvalue.custom.varargin  = opts;
cfg.artfctdef.zvalue.artfctpeak       = 'yes';
cfg.artfctdef.zvalue.artfctpeakrange  = [-0.02 0.02];
% the value for artfctpeakrange depends a bit on what is going to be done
% downstream: if only the fast flank is to be marked, then the values need
% to be small. If it's intended to discard some larger portion after the
% end of the saccade, obviously the second element needs to be extended a
% bit


% padding options that depend a bit on the intended downstream analysis.
% There is no one shoe fits all. Specifically, the fltpadding requires
% a non-zero value of 0.5*the intended cfg.padding in ft_preprocessing, to
% avoid highpassfilter ringing caused by a squidjump to affect the relevant
% data. Note that this slows down the current processing step, but better
% safe than sorry. If a very wide definition of epochs is already used,
% then fltpadding could be specified to 0 (because sufficient data is
% processed for artifacts anyhow)
cfg.artfctdef.zvalue.fltpadding    = 0;
cfg.artfctdef.zvalue.trlpadding    = 0;
cfg.artfctdef.zvalue.artpadding    = 0;

cfg = ft_artifact_zvalue(cfg);

function boolvec = artifact2boolvec(artifact, varargin)

% ARTIFACT2BOOLVEC converts between two representations of events or trials.
%
% FieldTrip uses a number of representations for events that are conceptually very similar
%   event    = structure with type, value, sample, duration and offset
%   trl      = Nx3 numerical array with begsample, endsample, offset
%   trl      = table with 3 columns for begsample, endsample, offset
%   artifact = Nx2 numerical array with begsample, endsample
%   artifact = table with 2 columns for begsample, endsample
%   boolvec  = 1xNsamples boolean vector with a thresholded TTL/trigger sequence
%   boolvec  = MxNsamples matrix vector with a thresholded TTL/trigger sequence
%
% If trl or artifact are represented as a MATLAB table, they can have additional
% columns. These additional columns have to be named and are not restricted to
% numerical values.
%
% This function makes a Boolean vector (or matrix when artifact is a cell-array of
% multiple artifact definitions) with 0 for artifact free sample and 1 for sample
% containing an artifact according to artifact specification. The length of the
% vector matches the last sample in the artifact definition, or endsample when
% specified.
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

% trl and artifact are similar, except for the offset column
trl = artifact2trl(artifact);
boolvec = trl2boolvec(trl, varargin{:});

