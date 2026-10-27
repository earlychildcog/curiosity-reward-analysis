function [segmentStart, segmentEnd, badSegStart, badSegEnd] = fixSegments(segmentStart, segmentEnd)
% we have two arrays (let's say of timepoints)
% first array has the first time point and the second the last time point of each segment
% this fixes the arrays in case of superfluous points
% assumes both arrays are already sorted

segArray = [segmentStart; segmentEnd];
segInd = [-ones(size(segmentStart)); ones(size(segmentEnd))];
segIndNum = [[1:length(segmentStart)]'; [1:length(segmentEnd)]'];
[~, segSortNum] = sort(segArray);
segIndSort = [segInd(segSortNum)];

segIndBadAll = [1; segIndSort] + [segIndSort; -1];
segIndBadStart = (segIndBadAll(2:end) < 0);
segIndBadEnd = (segIndBadAll(1:end-1) > 0);
   

segIndNumSort = segIndNum(segSortNum);
segmentStart(segIndNumSort(segIndBadStart)) = [];
segmentEnd(segIndNumSort(segIndBadEnd)) = [];

badSegStart = segIndNumSort(segIndBadStart);
badSegEnd = segIndNumSort(segIndBadEnd);