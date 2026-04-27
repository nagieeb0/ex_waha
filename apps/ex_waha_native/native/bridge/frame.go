// Length-prefixed JSON framing for the Elixir <-> Go bridge.
//
// Wire format: [4-byte big-endian length][UTF-8 JSON body]
//
// stdoutMu serializes writes so concurrent emitEvent() and reply() calls
// don't interleave bytes.

package main

import (
	"bufio"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"sync"
)

type frame struct {
	Type    string                 `json:"type"`
	Ref     *string                `json:"ref,omitempty"`
	Session string                 `json:"session,omitempty"`
	Op      string                 `json:"op,omitempty"`
	Args    map[string]interface{} `json:"args,omitempty"`
	OK      *bool                  `json:"ok,omitempty"`
	Result  interface{}            `json:"result,omitempty"`
	Error   string                 `json:"error,omitempty"`
	Code    string                 `json:"code,omitempty"`
	Kind    string                 `json:"kind,omitempty"`
	Payload interface{}            `json:"payload,omitempty"`
}

var stdoutMu sync.Mutex

func readFrame(r *bufio.Reader) (*frame, error) {
	var lenBuf [4]byte
	if _, err := io.ReadFull(r, lenBuf[:]); err != nil {
		return nil, err
	}
	length := binary.BigEndian.Uint32(lenBuf[:])

	payload := make([]byte, length)
	if _, err := io.ReadFull(r, payload); err != nil {
		return nil, err
	}

	var f frame
	if err := json.Unmarshal(payload, &f); err != nil {
		return nil, fmt.Errorf("decode: %w", err)
	}

	return &f, nil
}

func writeFrame(f *frame) error {
	stdoutMu.Lock()
	defer stdoutMu.Unlock()

	payload, err := json.Marshal(f)
	if err != nil {
		return err
	}

	var lenBuf [4]byte
	binary.BigEndian.PutUint32(lenBuf[:], uint32(len(payload)))

	if _, err := os.Stdout.Write(lenBuf[:]); err != nil {
		return err
	}
	if _, err := os.Stdout.Write(payload); err != nil {
		return err
	}

	return nil
}

func reply(ref *string, ok bool, result interface{}, errMsg, code string) {
	resp := &frame{
		Type:   "response",
		Ref:    ref,
		OK:     &ok,
		Result: result,
		Error:  errMsg,
		Code:   code,
	}
	if err := writeFrame(resp); err != nil {
		fmt.Fprintf(os.Stderr, "writeFrame: %v\n", err)
	}
}

func emitEvent(session, kind string, payload interface{}) {
	if err := writeFrame(&frame{
		Type:    "event",
		Session: session,
		Kind:    kind,
		Payload: payload,
	}); err != nil {
		fmt.Fprintf(os.Stderr, "emitEvent: %v\n", err)
	}
}
