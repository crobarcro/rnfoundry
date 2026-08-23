function validateStructEnvelope(s, schema, type)
%VALIDATESTRUCTENVELOPE Validate a version-1 rnfoundry.em persistence header.
if ~isstruct(s) || ~isfield(s, 'Schema') || ~strcmp(s.Schema, schema) ...
        || ~isfield(s, 'SchemaVersion') || s.SchemaVersion ~= 1
    error('rnfoundry:em:UnsupportedSchema', ...
          'Only schema %s version 1 is supported.', schema);
end
if ~isfield(s, 'Type') || ~strcmp(s.Type, type)
    error('rnfoundry:em:UnsupportedType', ...
          'Expected persisted type %s.', type);
end
end
