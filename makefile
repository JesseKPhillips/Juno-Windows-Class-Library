DEPS=juno\base\collections.d juno\base\core.d juno\base\environment.d juno\base\events.d juno\base\math.d juno\base\native.d juno\base\string.d juno\base\text.d juno\base\threading.d juno\base\time.d juno\locale\constants.d juno\locale\convert.d juno\locale\core.d juno\locale\numeric.d juno\locale\text.d juno\locale\time.d juno\io\core.d juno\io\filesystem.d juno\io\path.d juno\io\zip.d juno\com\core.d juno\com\client.d juno\com\server.d juno\com\reflect.d juno\xml\core.d juno\xml\xsl.d juno\xml\msxml.d juno\xml\streaming.d juno\xml\all.d juno\net\all.d juno\net\core.d juno\net\client.d juno\security\crypto.d juno\utils\process.d juno\utils\registry.d juno\media\constants.d juno\media\geometry.d juno\media\core.d juno\media\imaging.d juno\media\native.d

juno: juno.lib juno/juno.args

xsl.obj: juno/xml/xsl.d
	dmd -c -property juno/xml/xsl.d -Dddoc
juno.lib: xsl.obj $(DEPS)
	dmd -lib -ofjuno.lib -property -O -inline -release $(args) @juno/juno.args xsl.obj -Dddoc

events: juno examples/com/events.d
	dmd $(args) examples/com/events.d juno.lib -Ijuno
latebinding: juno examples/com/latebinding.d
	dmd $(args) examples/com/latebinding.d juno.lib -Ijuno
messagebeep: juno
	dmd $(args) examples/dll/messagebeep.d juno.lib -Ijuno
relativepath: juno
	dmd $(args) examples/dll/relativepath.d juno.lib -Ijuno
xmlwrite: juno examples/xml/write.d
	dmd $(args) examples/xml/write.d juno.lib -Ijuno
xmlread: juno examples/xml/read.d
	dmd $(args) examples/xml/read.d juno.lib -Ijuno
xmlnavigate: juno examples/xml/navigate.d
	dmd $(args) examples/xml/navigate.d juno.lib -Ijuno
textimage: juno examples/media/textimage.d
	dmd $(args) examples/media/textimage.d juno.lib -Ijuno

client: juno examples/com/server/client.d examples/com/server/hello.d
	dmd $(args) examples/com/server/client.d examples/com/server/hello.d juno.lib -Ijuno
server: juno examples/com/server/server.d examples/com/server/hello.d client
	dmd $(args) -ofserver.dll examples/com/server/server.d examples/com/server/hello.d juno.lib -Ijuno examples/com/server/server.def
