function subj = prj_subjinfo(sub, ses)

% PRJ_SUBJINFO is a bookkeeping function, that returns subject
% (and optionally session) specific information, regarding filenames,
% paths, and other metadata. The idea is to keep this information at
% a single location, rather than having to deal with it in all 
% downstream analysis steps. Also, although it is the intention to
% work with standardized paths/filenames/etc. there will always be
% exceptions to the rules. The exceptions can be also stored here.
%
% Just like with the other functions in this repo, it is recommended
% to replace the 'prj' affix with a project specific prefix to avoid
% clashes on the matlab path.
%
% Use as
%   subj = prj_subjinfo(sub, [ses])
%
% where sub is a string that names the subject, and the optional ses
% names the session. The latter may be needed in case of multiple 
% sessions per subject. If sub/ses are numeric, these are translated
% into the standard sub-001, and ses-meg01. Note the lowercase sub/ses
% (so no Sub/SUB etc), the hyphen (so no underscore), and the three
% digit expansion of the subject number (i.e. 1 will become 001, and
% not 1, and also not 01)

if nargin<2
  ses = 1;
end

if ~ischar(sub)
  sub = sprintf('sub-%03d', sub);
end

if ~ischar(ses)
  ses = sprintf('ses-meg%02d', ses);
end

projectdir = '/project/3026001.01/';
procstr    = 'processed'; % can also be derived

subj.subjname   = sub;
subj.sessname   = ses;
subj.projectdir = projectdir;
subj.rawdir     = fullfile(subj.projectdir, 'raw', subj.subjname, subj.sessname, 'meg');
subj.procdir    = fullfile(subj.projectdir, procstr, subj.subjname);

% The following works if there's a single *.ds in the session's folder
d = dir(fullfile(subj.rawdir, '*.ds'));
if numel(d)==1
  subj.dataset = fullfile(d.folder, d.name);
else
  error('no single raw dataset could be found');
end

% The following works if there's EDF2ASC converted eyelink data in the session's eyelink
% subfolder that is at the same level as ../meg
eyelinkdir = fullfile(subj.rawdir(1:end-3), 'eyelink'); % assuming rawdir ends with /meg
subj.eyelinkdir = eyelinkdir;
d = dir(fullfile(eyelinkdir, '*.asc'));

% Eyelink data may be stored in multiple files per corresponding MEG
% dataset. Here it is assumed that there's just a single MEG dataset per
% session, so that there is an unambiguous one-to-one (or multiple-to-one)
% asc-file to ds-folder mapping.
for k = 1:numel(d)
  subj.eyelinkfile{k,1} = fullfile(d(k).folder, d(k).name);
end
