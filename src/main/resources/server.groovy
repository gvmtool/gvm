import groovy.text.SimpleTemplateEngine
import java.util.zip.*
import org.vertx.groovy.core.http.RouteMatcher
import org.vertx.java.core.json.JsonObject


//
// datasource configuration
//

def config
def mongoJson = new File('srv/mongo.json')
if(mongoJson.exists()){
	config = new JsonObject(mongoJson.text).toMap()
} else {
	config = [address: 'mongo-persistor', db_name: 'gvm']
}
container.deployModule('vertx.mongo-persistor-v1.2', config)

def templateEngine = new SimpleTemplateEngine()


//
// route matcher implementations
//

def rm = new RouteMatcher()

rm.get("/") { req ->
	addPlainTextHeader req
	req.response.sendFile('build/scripts/install.sh')
}

rm.get("/selfupdate") { req ->
	addPlainTextHeader req
	req.response.sendFile('build/scripts/selfupdate.sh')
}

rm.get("/alive") { req ->
	addPlainTextHeader req
	req.response.end "OK"
}

rm.get("/res") { req ->
	def cmd = [action:"find", collection:"application", matcher:[_id:1]]
	vertx.eventBus.send("mongo-persistor", cmd){ msg ->
		addPlainTextHeader req
		def gvmVersion = msg.body.results[0].gvmVersion
		log 'initialise', 'gvm', gvmVersion, req
	}

	def zipFile = new File('build/distributions/gvm-scripts.zip')
	req.response.putHeader("Content-Type", "application/zip")
	req.response.sendFile zipFile.absolutePath
}

rm.get("/candidates") { req ->
	def cmd = [action:"find", collection:"candidates", matcher:[:], keys:[candidate:1]]
	vertx.eventBus.send("mongo-persistor", cmd){ msg ->
		def candidates = msg.body.results.collect(new TreeSet()) { it.candidate }
		addPlainTextHeader req
		req.response.end candidates.join(', ')
	}
}

rm.get("/candidates/:candidate") { req ->
	def candidate = req.params['candidate']
	def cmd = [action:"find", collection:"versions", matcher:[candidate:candidate], keys:["version":1]]
	vertx.eventBus.send("mongo-persistor", cmd){ msg ->
		def response
		if(msg.body.results){
			def versions = msg.body.results.collect(new TreeSet()) { it.version }
			response = versions.join(', ')

		} else {
			response = "invalid"
		}

		addPlainTextHeader req
		req.response.end response
	}
}

rm.get("/candidates/:candidate/default") { req ->
	def candidate = req.params['candidate']
	def cmd = [action:"find", collection:"candidates", matcher:[candidate:candidate], keys:["default":1]]
	vertx.eventBus.send("mongo-persistor", cmd){ msg ->
		addPlainTextHeader req
		def defaultVersion = msg.body.results.default
		req.response.end (defaultVersion ?: "")
	}
}

rm.get("/candidates/:candidate/list") { req ->
	def candidate = req.params['candidate']
	def current = req.params['current']
	def installed = req.params['installed']?.tokenize(',')
	def gtplFile = new File('build/templates/list.gtpl')

	def cmd = [action:"find", collection:"versions", matcher:[candidate:candidate], keys:["version":1], sort:["version":1]]
	vertx.eventBus.send("mongo-persistor", cmd){ msg ->
		def available = msg.body.results.collect { it.version }
		def binding = [candidate:candidate, available:available, current:current, installed:installed]
		def template = templateEngine.createTemplate(gtplFile).make(binding)
		addPlainTextHeader req
		req.response.end template.toString()
	}
}

rm.get("/candidates/:candidate/:version") { req ->
	def candidate = req.params['candidate']
	def version = req.params['version']
	def cmd = [action:"find", collection:"versions", matcher:[candidate:candidate, version:version]]
	vertx.eventBus.send("mongo-persistor", cmd){ msg ->
		addPlainTextHeader req
		if(msg.body.results) {
			req.response.end 'valid'
		} else {
			req.response.end 'invalid'
		}
	}
}

rm.get("/download/:candidate/:version") { req ->
	def candidate = req.params['candidate']
	def version = req.params['version']

	log 'install', candidate, version, req

	def cmd = [action:"find", collection:"versions", matcher:[candidate:candidate, version:version], keys:["url":1]]
	vertx.eventBus.send("mongo-persistor", cmd){ msg ->
		req.response.headers['Location'] = msg.body.results.url.first()
		req.response.statusCode = 302
		req.response.end()
	}
}

rm.get("/app/version") { req ->
	def cmd = [action:"find", collection:"application", matcher:[_id:1]]
	vertx.eventBus.send("mongo-persistor", cmd){ msg ->
		addPlainTextHeader req
		def gvmVersion = "${msg.body.results[0].gvmVersion}"
		req.response.end gvmVersion
	}
}

rm.get("/broadcast/:version") { req ->
	def gvmVersion, vertxVersion
	def cmd1 = [action:"find", collection:"application", matcher:[_id:1]]
	vertx.eventBus.send("mongo-persistor", cmd1){ msg ->
		addPlainTextHeader req
		gvmVersion = "${msg.body.results[0].gvmVersion}"
		vertxVersion = "${msg.body.results[0].vertxVersion}"
	}

	def cmd2 = [action:"find", collection:"broadcast", matcher:[:]]
	vertx.eventBus.send("mongo-persistor", cmd2){ msg ->
		def broadcasts = msg.body.results
		def version = req.params['version']
		def gtpFile, binding
		if(gvmVersion == version){
			gtplFile = new File('build/templates/broadcast.gtpl')
			binding = [gvmVersion:gvmVersion, vertxVersion:vertxVersion, broadcasts:broadcasts]
		} else {
			gtplFile = new File('build/templates/upgrade.gtpl')
			binding = [version:version, gvmVersion:gvmVersion]
		}
		def templateText = templateEngine.createTemplate(gtplFile).make(binding).toString()

		addPlainTextHeader req
		req.response.end templateText
	}

}


//
// leave here for legacy purposes
//

rm.get("/app/alive/:version") { req ->
	def legacyBroadcast = new File('build/templates/legacy.gtpl')
	def broadcast = legacyBroadcast.text
	addPlainTextHeader req
	req.response.end broadcast
}

rm.get("/res/init") { req ->
	log 'init', 'n/a', 'n/a', req
	addPlainTextHeader req
	req.response.sendFile 'srv/scripts/gvm-init.sh'
}

rm.get("/res/gvm") { req ->
	addPlainTextHeader req
	req.response.sendFile 'srv/scripts/gvm'
}


//
// private methods
//

private addPlainTextHeader(req){
	req.response.putHeader("Content-Type", "text/plain")
}

private log(command, candidate, version, req){
	def date = new Date()
	def host = req.headers['x-forwarded-for']
	def agent = req.headers['user-agent']
	def platform = req.params['platform']

	def document = [
		command:command,
		candidate:candidate,
		version:version,
		host:host,
		agent:agent,
		platform:platform,
		date:date
	]

	def cmd = [action:'save', collection:'audit', document:document] 

	vertx.eventBus.send 'mongo-persistor', cmd
}

//
// startup server
//
def port = System.getenv('PORT') ?: 8080
def host = System.getenv('PORT') ? '0.0.0.0' : 'localhost'
println "Starting vertx on $host:$port"
vertx.createHttpServer().requestHandler(rm.asClosure()).listen(port as int, host)



