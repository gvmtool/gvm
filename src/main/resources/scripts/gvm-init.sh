#!/bin/bash

export GVM_SERVICE="@GVM_SERVICE@"

PATH="$HOME/.gvm/bin:$PATH"

GROOVY_HOME="$HOME/.gvm/groovy/current"
GRAILS_HOME="$HOME/.gvm/grails/current"
GRIFFON_HOME="$HOME/.gvm/griffon/current"
GRADLE_HOME="$HOME/.gvm/gradle/current"
VERTX_HOME="$HOME/.gvm/vert.x/current"

export PATH="$GROOVY_HOME/bin:$GRAILS_HOME/bin:$GRIFFON_HOME/bin:$GRADLE_HOME/bin:$VERTX_HOME/bin:$PATH"
