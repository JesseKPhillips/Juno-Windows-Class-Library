juno:
	dmd -c juno/xml/dom.d
	dmd -c juno/net/mail.d
	dmd -lib -ofjuno.lib $(args) @juno/juno.args dom.obj mail.obj
