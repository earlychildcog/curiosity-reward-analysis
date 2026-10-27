%% Calculate N missing pairs (for ICC)

function T = fET_calculateMissingPairsICC(T)

T.Npairs_lat = ~isnan(T.t_Box2_afterB1_DiffScore_12m) + ~isnan(T.t_Box2_afterB1_DiffScore_18m) + ~isnan(T.t_Box2_afterB1_DiffScore_24m) -1;
T.Npairs_lat(T.Npairs_lat<0) = 0; T.Npairs_lat(T.Npairs_lat==2) = 3;
Npairs_missing_lat = length(T.Npairs_lat)*3 - sum(T.Npairs_lat)
Npairs_missing_prop = (length(T.Npairs_lat)*3 - sum(T.Npairs_lat)) / (length(T.Npairs_lat)*3)

T.Npairs_prop = ~isnan(T.prop_OpenedBothBoxes_DiffScore_12m) + ~isnan(T.prop_OpenedBothBoxes_DiffScore_18m) + ~isnan(T.prop_OpenedBothBoxes_DiffScore_24m) -1;
T.Npairs_prop(T.Npairs_prop<0) = 0; T.Npairs_prop(T.Npairs_prop==2) = 3;
Npairs_Nmissing_prop = length(T.Npairs_prop)*3 - sum(T.Npairs_prop)
Npairs_propmissing_prop = (length(T.Npairs_prop)*3 - sum(T.Npairs_prop)) / (length(T.Npairs_prop)*3)

end