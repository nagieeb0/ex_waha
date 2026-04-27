// Package main is the Elixir <-> whatsmeow bridge process.
//
// Architecture:
//
//	stdin  <- length-prefixed JSON requests from BEAM Port
//	stdout -> length-prefixed JSON responses + async events
//	stderr -> diagnostic logs (never JSON, never framed)
//
// One long-lived process per BEAM node. Sessions multiplex by the `session`
// field on each request.
package main

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"os"
	"os/signal"
	"syscall"
)

func main() {
	mgr := newSessionManager()
	defer mgr.shutdown()

	// Handle SIGTERM/SIGINT cleanly so whatsmeow disconnects.
	ctx, cancel := context.WithCancel(context.Background())
	go func() {
		sig := make(chan os.Signal, 1)
		signal.Notify(sig, os.Interrupt, syscall.SIGTERM)
		<-sig
		cancel()
		mgr.shutdown()
		os.Exit(0)
	}()

	reader := bufio.NewReaderSize(os.Stdin, 64*1024)

	for {
		msg, err := readFrame(reader)
		if err == io.EOF {
			return
		}
		if err != nil {
			fmt.Fprintf(os.Stderr, "bridge: read error: %v\n", err)
			os.Exit(1)
		}

		go dispatch(ctx, mgr, msg)
	}
}

func dispatch(ctx context.Context, mgr *sessionManager, msg *frame) {
	defer func() {
		if r := recover(); r != nil {
			fmt.Fprintf(os.Stderr, "bridge: panic in dispatch %s: %v\n", msg.Op, r)
			reply(msg.Ref, false, nil, fmt.Sprintf("panic: %v", r), "panic")
		}
	}()

	switch msg.Op {
	case "ping":
		reply(msg.Ref, true, map[string]string{"pong": msg.Session}, "", "")

	case "open_session":
		handleOpenSession(ctx, mgr, msg)

	case "close_session":
		handleCloseSession(mgr, msg)

	case "send_text":
		handleSendText(ctx, mgr, msg)

	case "logout":
		handleLogout(ctx, mgr, msg)

	case "request_pairing_code":
		handleRequestPairingCode(ctx, mgr, msg)

	default:
		reply(msg.Ref, false, nil, "unknown op: "+msg.Op, "unknown_op")
	}
}
