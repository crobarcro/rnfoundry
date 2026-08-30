classdef XFemmSessionAnalysis < handle
    %XFEMMSESSIONANALYSIS Own one xfemm session and its input FEM file.
    %   This class deliberately contains no machine-topology or positioning
    %   policy. Topology-specific code operates on the owned Session.
    properties (SetAccess = private)
        FemmProblem
        FemFileName
        Session
    end
    methods
        function obj = XFemmSessionAnalysis(femmProblem, femFileName)
            if nargin < 2 || isempty(femFileName)
                femFileName = [tempname(), '_rnfoundry_em.fem'];
            end
            if exist('xfemm.femmsession','class') ~= 8
                error('rnfoundry:em:XFemmUnavailable', ...
                      'xfemm.femmsession is not available on the current path.');
            end
            obj.FemmProblem = femmProblem;
            obj.FemFileName = femFileName;
            try
                writefemmfile(obj.FemFileName, obj.FemmProblem);
                obj.Session = xfemm.femmsession(obj.FemFileName);
            catch err
                obj.cleanupFile();
                rethrow(err);
            end
        end
        function solve(obj)
            obj.requireSession();
            obj.Session.solve();
        end
        function delete(obj)
            if ~isempty(obj.Session)
                try
                    delete(obj.Session);
                catch
                    % Destructors must still release the owned temporary file.
                end
                obj.Session = [];
            end
            obj.cleanupFile();
        end
    end
    methods (Access = private)
        function requireSession(obj)
            if isempty(obj.Session)
                error('rnfoundry:em:ClosedXFemmSession','The xfemm session is closed.');
            end
        end
        function cleanupFile(obj)
            if ~isempty(obj.FemFileName) && exist(obj.FemFileName,'file') == 2
                delete(obj.FemFileName);
            end
        end
    end
end
