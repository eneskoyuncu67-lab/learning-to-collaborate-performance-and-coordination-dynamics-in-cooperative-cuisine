function t = parse_env_time(s)
%PARSE_ENV_TIME Seconds-of-day from an ISO-like 'YYYY-MM-DDTHH:MM:SS...' string.
%   Also used for player_interactions timestamps, which share the same
%   'T...HH:MM:SS.ffffff' suffix format on a placeholder date.
try
    idx  = strfind(s,'T');
    ts   = s(idx+1:end);
    pts  = split(ts,':');
    t    = str2double(pts{1})*3600 + str2double(pts{2})*60 + str2double(pts{3});
catch
    t = NaN;
end
end
