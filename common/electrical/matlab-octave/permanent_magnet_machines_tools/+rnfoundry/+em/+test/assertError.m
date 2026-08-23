function assertError(f, identifier)
failed = false;
try
    f();
catch err
    failed = true;
    assert(strcmp(err.identifier,identifier), ...
           'Expected %s, received %s (%s).',identifier,err.identifier,err.message);
end
assert(failed,'Expected error %s was not raised.',identifier);
end
