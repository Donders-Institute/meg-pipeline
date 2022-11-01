function [event_asc, align_params, fname_asc, N] = multisens_eyelink_events(sub, ses)

datadir   = fullfile('/project/3026001.01/raw/', sprintf('sub-%03d/ses-meg%02d',sub,ses));
megdir    = fullfile(datadir, 'meg');
eyedir    = fullfile(datadir, 'eyelink');
d         = dir(fullfile(megdir, '*.ds'));
fname_meg = fullfile(d.folder, d.name);

% read in the MEG events
event_meg = ft_read_event(fname_meg);
event_meg = event_meg(:);
event_meg_all = event_meg;

% in these data, the eyelink is stored in multiple files per session
d         = dir(fullfile(eyedir, '*.asc'));
fname_asc = cell(numel(d), 1);
event_asc = cell(numel(d), 1);

% loop across the files
for k = 2:numel(d)
  fname_asc{k,1} = fullfile(d(k).folder, d(k).name);
  tmp = ft_read_event(fname_asc{k});
  event_asc{k,1}     = tmp(:); % this one will be pruned according to the matching triggers with MEG
  event_asc_all{k,1} = tmp(:); % store as a separate copy, all events

  % now the events need to be mapped onto each other in order to get the time
  % axes aligned. For this, we select the UPPT001 triggers from the MEG, and
  % the INPUT events from the eyelink data, because they are the stimulus
  % presentation events sent out by the bitsi to the eyelink and MEG
  % acquisition computers
  selmeg = strcmp({event_meg_all.type}', 'UPPT001');
  event_meg = event_meg_all(selmeg);
  event_meg = event_meg(:); % make column
  
  selasc = strcmp({event_asc{k}.type}', 'INPUT');
  event_asc{k} = event_asc{k}(selasc);

  % the eyelink events also codes the end of a trigger pulse, as 0, remove
  % those too.
  val = [event_asc{k}.value];
  event_asc{k} = event_asc{k}(val~=0);

  % The easiest way in which both sets of events can be mapped onto each
  % other is - when the assumption is valid that all triggers are present in
  % both 'channels' (with no 'noise' in between)
  val_meg = [event_meg.value];
  val_asc = [event_asc{k}.value];
  
  val_meg = val_meg(~ismember(val_meg,[111 112 131 132])); % remove the regular ones
  val_asc = val_asc(~ismember(val_asc,[111 112 131 132]));

  [keep_meg, keep_asc] = align_triggers(val_meg, val_asc, 100);
  assert(isequal(val_meg(keep_meg), val_asc(keep_asc)));
  
  event_meg    = event_meg(keep_meg);
  event_asc{k} = event_asc{k}(keep_asc);

  % the eyelink data could have a discontinuous time axis (jumps in the
  % timestamp trace), and since the other events
  % (saccades/fixations/eyeblinks) are expressed in timestamps, we should 
  % align the triggers based on the timestamps
  smp_asc = [event_asc{k}.timestamp];
  smp_meg = [event_meg.sample]; % assuming MEG to be derived from a continuous recording

  offset_meg = mean(smp_meg);
  offset_asc = mean(smp_asc);

  x = smp_asc - offset_asc;
  y = smp_meg - offset_meg;
  slope = y/x; % this should be about 1.2 (1kHz vs. 1.2kHz)

  % plot the residuals between the MEG samples and the 'modelled' MEG samples
  res = smp_meg - offset_meg - slope.*(smp_asc - offset_asc); % conclusion: it is anywhere between -1.5 of 1.5 samples
  figure;histogram(res);

  S    = [event_asc_all{k}.timestamp];
  Snew = slope.*(S-offset_asc) + offset_meg;

  % remap the event_asc_all's samples to samples of the MEG recording
  for kk = 1:numel(event_asc_all{k})
    event_asc_all{k}(kk).sample   = Snew(kk);
    event_asc_all{k}(kk).duration = round(event_asc_all{k}(kk).duration.*slope);
  end
  align_params(k,:) = [slope offset_meg offset_asc];
end

N = cellfun(@numel, event_asc_all);
event_asc = cat(1, event_asc_all{:});

% save the results
savedir = fullfile('/project/3026001.01/processed', sprintf('sub-%0.3d', sub));
fname   = fullfile(savedir, sprintf('sub-%0.3d_ses-%0.3d_eyelink_events.mat', sub, ses));
save(fname, 'event_asc', 'N', 'align_params', 'fname_asc');

