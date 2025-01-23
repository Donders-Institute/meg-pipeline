function dataout = prj_util_rejectvisual_chunked(cfg, data)

% PRJ_UTIL_REJECTVISUAL_CHUNKED performs a rejectvisual-stytle (summary
% method) data cleaning (replacing identified chunks of data with nans),
% based on user defined chunk length. This might be useful functionality to
% quickly identify bad segments of data (e.g. SQUID jumps). In
% ft_rejectvisual the rejection of a 'trial' is an all-or-none phenomenon,
% which leads to potentially too much data loss if the trials are long.
% Here ft_redefinetrial is used first to chunk the data into user specified
% length chunks, and after the application of ft_rejectvisual the data are
% stitched back together. 
%
% Us as:
%   dataout = prj_util_rejectvisual_chunked(cfg, data)

cfg.layout = ft_getopt(cfg, 'layout');
cfg.length = ft_getopt(cfg, 'length', 2); % chunklength 

% ensure the data to have a sampleinfo field
data = ft_checkdata(data, 'hassampleinfo', 'yes');
sampleinfoorig = data.sampleinfo;
trialinfoorig  = data.trialinfo;
timeorig       = data.time;

nsmp = round(data.fsample.*cfg.length);
nrpt = numel(data.trial);

% ensure that there are gaps between the consecutive trials to be sure that
% the stitching together works
data.sampleinfo = data.sampleinfo + (0:nsmp:(nrpt-1)*nsmp)'*[1 1];

cfgr                 = [];
cfgr.length          = cfg.length;
cfgr.updatetrialinfo = 'yes';
cfgr.keeppartial     = 'yes';
data = ft_redefinetrial(cfg, data);

cfgv = [];
cfgv.method = 'summary';
cfgv.keeptrial = 'nan';
cfgv.layout = cfg.layout;
data = ft_rejectvisual(cfgv, data);

cfgr            = [];
cfgr.continuous = 'yes';
dataout = ft_redefinetrial(cfgr, data);
dataout.sampleinfo = sampleinfoorig;
dataout.trialinfo  = trialinfoorig;
dataout.time       = timeorig;