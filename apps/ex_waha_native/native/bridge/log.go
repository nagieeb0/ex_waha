// stderr logger adapter for whatsmeow's waLog interface.

package main

import (
	"fmt"
	"os"

	waLog "go.mau.fi/whatsmeow/util/log"
)

type stderrLog struct {
	module string
}

func stderrLogger(module string) waLog.Logger {
	return &stderrLog{module: module}
}

func (l *stderrLog) Errorf(format string, args ...interface{}) {
	l.write("ERR", format, args...)
}

func (l *stderrLog) Warnf(format string, args ...interface{}) {
	l.write("WARN", format, args...)
}

func (l *stderrLog) Infof(format string, args ...interface{}) {
	l.write("INFO", format, args...)
}

func (l *stderrLog) Debugf(format string, args ...interface{}) {
	// Debug is too chatty for production; keep available behind WAHA_DEBUG=1.
	if os.Getenv("WAHA_DEBUG") == "1" {
		l.write("DBG", format, args...)
	}
}

func (l *stderrLog) Sub(module string) waLog.Logger {
	return &stderrLog{module: l.module + "." + module}
}

func (l *stderrLog) write(level, format string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, "[%s] %s: "+format+"\n", append([]interface{}{l.module, level}, args...)...)
}
