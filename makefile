
juno:
    dmd -c juno/xml/dom.d
    dmd -lib -ofjuno.lib $(args) @juno/juno.args dom.obj
