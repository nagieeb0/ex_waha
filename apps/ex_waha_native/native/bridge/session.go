// Session manager — keeps one whatsmeow.Client per session_id.

package main

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"path/filepath"
	"sync"

	"go.mau.fi/whatsmeow"
	"go.mau.fi/whatsmeow/store/sqlstore"
	waLog "go.mau.fi/whatsmeow/util/log"

	_ "modernc.org/sqlite"
)

type sessionEntry struct {
	id        string
	container *sqlstore.Container
	client    *whatsmeow.Client
}

type sessionManager struct {
	mu       sync.RWMutex
	sessions map[string]*sessionEntry
	logger   waLog.Logger
}

func newSessionManager() *sessionManager {
	return &sessionManager{
		sessions: make(map[string]*sessionEntry),
		// Direct logs to stderr so they don't corrupt the stdout protocol.
		logger: stderrLogger("bridge"),
	}
}

func (m *sessionManager) shutdown() {
	m.mu.Lock()
	defer m.mu.Unlock()

	for id, entry := range m.sessions {
		if entry.client != nil {
			entry.client.Disconnect()
		}
		if entry.container != nil {
			_ = entry.container.Close()
		}
		delete(m.sessions, id)
	}
}

func (m *sessionManager) get(id string) (*sessionEntry, bool) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	e, ok := m.sessions[id]
	return e, ok
}

// open creates the sqlstore container, loads or creates the device, and
// builds a whatsmeow.Client. The caller is responsible for connecting
// and registering an event handler.
func (m *sessionManager) open(ctx context.Context, id string, store storeConfig) (*sessionEntry, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	if existing, ok := m.sessions[id]; ok {
		return existing, nil
	}

	dsn, err := store.dsn(id)
	if err != nil {
		return nil, err
	}

	dbLog := stderrLogger("db:" + id)
	container, err := sqlstore.New(ctx, "sqlite", dsn, dbLog)
	if err != nil {
		return nil, fmt.Errorf("sqlstore.New: %w", err)
	}

	device, err := container.GetFirstDevice(ctx)
	if err != nil {
		_ = container.Close()
		return nil, fmt.Errorf("GetFirstDevice: %w", err)
	}

	clientLog := stderrLogger("client:" + id)
	client := whatsmeow.NewClient(device, clientLog)

	entry := &sessionEntry{id: id, container: container, client: client}
	m.sessions[id] = entry
	return entry, nil
}

func (m *sessionManager) close(id string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	entry, ok := m.sessions[id]
	if !ok {
		return errors.New("not_found")
	}

	if entry.client != nil {
		entry.client.Disconnect()
	}
	if entry.container != nil {
		_ = entry.container.Close()
	}
	delete(m.sessions, id)
	return nil
}

// storeConfig represents the persistence backend for a session's device store.
type storeConfig struct {
	Kind string                 // "memory" | "sqlite"
	Path string                 // for sqlite
	Opts map[string]interface{} // for postgres (future)
}

func parseStoreConfig(args map[string]interface{}) storeConfig {
	store, _ := args["store"].(map[string]interface{})
	if store == nil {
		return storeConfig{Kind: "memory"}
	}

	cfg := storeConfig{Kind: stringFromMap(store, "kind", "memory")}
	cfg.Path = stringFromMap(store, "path", "")

	if opts, ok := store["opts"].(map[string]interface{}); ok {
		cfg.Opts = opts
	}

	return cfg
}

func (s storeConfig) dsn(sessionID string) (string, error) {
	switch s.Kind {
	case "memory":
		return "file:" + sessionID + "?mode=memory&cache=shared&_pragma=foreign_keys(1)", nil

	case "sqlite":
		path := s.Path
		if path == "" {
			path = filepath.Join("priv", "sessions", sessionID+".db")
		}
		return "file:" + path + "?_pragma=foreign_keys(1)", nil

	default:
		return "", fmt.Errorf("unsupported store kind: %s", s.Kind)
	}
}

func stringFromMap(m map[string]interface{}, key, def string) string {
	if v, ok := m[key].(string); ok {
		return v
	}
	return def
}

// dbAdapter exists so the import of database/sql is used (sqlstore depends
// on it transitively but we import the driver explicitly).
var _ = (*sql.DB)(nil)
