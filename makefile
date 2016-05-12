DEPS=source\juno\base\collections.d source\juno\base\core.d source\juno\base\environment.d source\juno\base\events.d source\juno\base\math.d source\juno\base\native.d source\juno\base\string.d source\juno\base\text.d source\juno\base\threading.d source\juno\base\time.d source\juno\locale\constants.d source\juno\locale\convert.d source\juno\locale\core.d source\juno\locale\numeric.d source\juno\locale\text.d source\juno\locale\time.d source\juno\io\core.d source\juno\io\filesystem.d source\juno\io\path.d source\juno\io\zip.d source\juno\com\core.d source\juno\com\client.d source\juno\com\server.d source\juno\com\reflect.d source\juno\xml\core.d source\juno\xml\xsl.d source\juno\xml\msxml.d source\juno\xml\streaming.d source\juno\xml\all.d source\juno\net\all.d source\juno\net\core.d source\juno\net\client.d source\juno\security\crypto.d source\juno\utils\process.d source\juno\utils\registry.d source\juno\media\constants.d source\juno\media\geometry.d source\juno\media\core.d source\juno\media\imaging.d source\juno\media\native.d source\juno\xml\xsl.d

juno: juno.lib source/juno.args
release: junoRelease source/juno.args

juno.lib: $(DEPS)
	dmd -w -lib -ofjuno.lib $(args) source/macro.ddoc @source/juno.args -Dddocs

junoRelease: $(DEPS)
	dmd -lib -ofjuno.lib -O -inline -release $(args) source/macro.ddoc @source/juno.args -Dddocs

events: juno examples/com/events.d
	dmd $(args) examples/com/events.d juno.lib -Isource/juno
latebinding: juno examples/com/latebinding.d
	dmd $(args) examples/com/latebinding.d juno.lib -Isource/juno
messagebeep: juno
	dmd $(args) examples/dll/messagebeep.d juno.lib -Isource/juno
relativepath: juno
	dmd $(args) examples/dll/relativepath.d juno.lib -Isource/juno
xmlwrite: juno examples/xml/write.d
	dmd $(args) examples/xml/write.d juno.lib -Isource/juno
xmlread: juno examples/xml/read.d
	dmd $(args) examples/xml/read.d juno.lib -Isource/juno
xmlnavigate: juno examples/xml/navigate.d
	dmd $(args) examples/xml/navigate.d juno.lib -Isource/juno
textimage: juno examples/media/textimage.d
	dmd $(args) examples/media/textimage.d juno.lib -Isource/juno
