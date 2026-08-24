//go:build singbox

// 实验性 sing-box 引擎,当前未被任何代码引用,且依赖的 SagerNet/sing-box
// 已不在模块依赖图中。默认不参与编译;需要时使用 `-tags singbox` 并补回依赖。

package singbox

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"runtime/debug"
	"strconv"
	"sync"
	"time"

	"github.com/SagerNet/sing-box"
	"github.com/SagerNet/sing-box/common/urltest"
	"github.com/SagerNet/sing-box/option"
)

// Engine manages the sing-box instance lifecycle
type Engine struct {
	mu          sync.Mutex
	box         *box.Box
	homeDir     string
	isInit      bool
	currentJSON []byte
	selectedMap map[string]string
	testURL     string

	// Log
	logChan   chan LogEvent
	logCancel context.CancelFunc

	// Provider manager
	providerMgr *ProviderManager

	// Clash API / stats (accessed through box)
	// statsManager and connManager are obtained from box at runtime
}

var DefaultEngine = &Engine{
	logChan: make(chan LogEvent, 512),
}

// Init initializes the engine with home directory
func (e *Engine) Init(homeDir string, version int) bool {
	e.mu.Lock()
	defer e.mu.Unlock()

	e.homeDir = homeDir
	e.isInit = true
	e.providerMgr = NewProviderManager(homeDir)
	return true
}

// SetupConfig loads a Clash YAML config, converts it, and starts the box
func (e *Engine) SetupConfig(paramsJSON []byte) string {
	e.mu.Lock()
	defer e.mu.Unlock()

	if !e.isInit {
		return "not initialized"
	}

	var params SetupParams
	if err := json.Unmarshal(paramsJSON, &params); err != nil {
		return err.Error()
	}
	e.selectedMap = params.SelectedMap
	if params.TestURL != "" {
		e.testURL = params.TestURL
	}

	// Read the Clash YAML config
	yamlPath := filepath.Join(e.homeDir, "config.yaml")
	yamlBytes, err := os.ReadFile(yamlPath)
	if err != nil {
		return "read config error: " + err.Error()
	}

	// Convert Clash YAML → sing-box JSON
	singboxJSON, err := ConvertClashToSingbox(yamlBytes, params)
	if err != nil {
		return "convert error: " + err.Error()
	}
	e.currentJSON = singboxJSON

	// Save converted config for debugging
	singboxPath := filepath.Join(e.homeDir, "singbox.json")
	_ = os.WriteFile(singboxPath, singboxJSON, 0644)

	return e.startBox(singboxJSON)
}

// startBox creates and starts a sing-box instance from JSON config
func (e *Engine) startBox(configJSON []byte) string {
	// Close existing instance
	if e.box != nil {
		e.box.Close()
		e.box = nil
	}

	// Parse options
	var options option.Options
	if err := options.UnmarshalJSON(configJSON); err != nil {
		return "parse error: " + err.Error()
	}

	// Create box
	instance, err := box.New(box.Options{
		Options: options,
	})
	if err != nil {
		return "create error: " + err.Error()
	}

	// Start
	if err := instance.Start(); err != nil {
		instance.Close()
		return "start error: " + err.Error()
	}

	e.box = instance
	return ""
}

// RestartBox rebuilds the box with modified config
func (e *Engine) RestartBox() string {
	e.mu.Lock()
	defer e.mu.Unlock()
	if e.currentJSON == nil {
		return "no config"
	}
	return e.startBox(e.currentJSON)
}

// Shutdown closes the engine
func (e *Engine) Shutdown() bool {
	e.mu.Lock()
	defer e.mu.Unlock()

	if e.box != nil {
		e.box.Close()
		e.box = nil
	}
	e.isInit = false
	e.currentJSON = nil
	return true
}

// IsInit returns whether the engine is initialized
func (e *Engine) IsInit() bool {
	e.mu.Lock()
	defer e.mu.Unlock()
	return e.isInit
}

// ForceGC forces garbage collection
func (e *Engine) ForceGC() {
	runtime.GC()
	debug.FreeOSMemory()
}

// ValidateConfig checks if a config file is valid
func (e *Engine) ValidateConfig(path string) string {
	buf, err := os.ReadFile(path)
	if err != nil {
		return err.Error()
	}

	// Try to convert and parse
	jsonBytes, err := ConvertClashToSingbox(buf, SetupParams{})
	if err != nil {
		return err.Error()
	}

	var options option.Options
	if err := options.UnmarshalJSON(jsonBytes); err != nil {
		return err.Error()
	}
	return ""
}

// GetConfig reads and parses a config file
func (e *Engine) GetConfig(path string) (json.RawMessage, error) {
	buf, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	// Convert Clash YAML → sing-box JSON and return as raw
	jsonBytes, err := ConvertClashToSingbox(buf, SetupParams{})
	if err != nil {
		return nil, err
	}
	return json.RawMessage(jsonBytes), nil
}

// UpdateConfig applies runtime config changes
func (e *Engine) UpdateConfig(paramsJSON []byte) string {
	e.mu.Lock()
	defer e.mu.Unlock()

	var params UpdateParams
	if err := json.Unmarshal(paramsJSON, &params); err != nil {
		return err.Error()
	}

	if e.currentJSON == nil {
		return "no active config"
	}

	// Patch the current sing-box JSON
	patched, err := PatchSingboxConfig(e.currentJSON, &params)
	if err != nil {
		return "patch error: " + err.Error()
	}
	e.currentJSON = patched

	return e.startBox(patched)
}

// GetProxies returns all proxy groups and their members
func (e *Engine) GetProxies() ProxiesData {
	e.mu.Lock()
	defer e.mu.Unlock()

	result := ProxiesData{
		Proxies: make(map[string]interface{}),
		All:     []string{},
	}

	if e.box == nil {
		return result
	}

	outboundMgr := e.box.Outbound()
	if outboundMgr == nil {
		return result
	}

	tags := outboundMgr.Outbounds()
	for _, tag := range tags {
		ob := outboundMgr.Get(tag)
		if ob == nil {
			continue
		}

		proxyInfo := map[string]interface{}{
			"name": tag,
			"type": ob.Type(),
			"now":  "",
		}

		// Check if it's a group type
		if isGroupOutboundType(ob.Type()) {
			result.All = append(result.All, tag)
			// Get current selection for selector-type outbounds
			if sel, ok := ob.(interface{ Now() string }); ok {
				proxyInfo["now"] = sel.Now()
			}
			// Get member list
			if group, ok := ob.(interface{ Outbounds() []string }); ok {
				members := group.Outbounds()
				memberProxies := make([]interface{}, 0, len(members))
				for _, m := range members {
					mob := outboundMgr.Get(m)
					if mob != nil {
						memberProxies = append(memberProxies, map[string]interface{}{
							"name": m,
							"type": mob.Type(),
						})
					}
				}
				proxyInfo["all"] = memberProxies
			}
		}

		result.Proxies[tag] = proxyInfo
	}

	return result
}

// ChangeProxy changes the selected proxy in a group
func (e *Engine) ChangeProxy(groupName, proxyName string) string {
	e.mu.Lock()
	defer e.mu.Unlock()

	if e.box == nil {
		return "not running"
	}

	outboundMgr := e.box.Outbound()
	if outboundMgr == nil {
		return "no outbound manager"
	}

	ob := outboundMgr.Get(groupName)
	if ob == nil {
		return "group not found: " + groupName
	}

	type selectAble interface {
		Select(tag string) error
	}

	if sel, ok := ob.(selectAble); ok {
		if err := sel.Select(proxyName); err != nil {
			return err.Error()
		}
		return ""
	}

	return "group is not selectable"
}

// TestDelay tests the latency of a proxy
func (e *Engine) TestDelay(proxyName, testURL string, timeout int64) Delay {
	if testURL == "" {
		testURL = e.testURL
	}
	if testURL == "" {
		testURL = "https://www.gstatic.com/generate_204"
	}

	e.mu.Lock()
	box := e.box
	e.mu.Unlock()

	result := Delay{Name: proxyName, Url: testURL, Value: -1}
	if box == nil {
		return result
	}

	outboundMgr := box.Outbound()
	if outboundMgr == nil {
		return result
	}

	ob := outboundMgr.Get(proxyName)
	if ob == nil {
		return result
	}

	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(timeout)*time.Millisecond)
	defer cancel()

	delay, err := urltest.URLTest(ctx, testURL, ob)
	if err != nil || delay == 0 {
		return result
	}

	result.Value = int32(delay)
	return result
}

// GetTraffic returns current upload/download traffic
func (e *Engine) GetTraffic(onlyProxy bool) Traffic {
	e.mu.Lock()
	defer e.mu.Unlock()

	if e.box == nil {
		return Traffic{}
	}

	// Get traffic from the box's network manager
	// sing-box exposes traffic through N.Network interface
	type trafficGetter interface {
		NowTraffic() (int64, int64)
	}

	if n := e.box.Network(); n != nil {
		if tg, ok := n.(trafficGetter); ok {
			up, down := tg.NowTraffic()
			return Traffic{Up: up, Down: down}
		}
	}

	return Traffic{}
}

// GetTotalTraffic returns total accumulated traffic
func (e *Engine) GetTotalTraffic(onlyProxy bool) Traffic {
	e.mu.Lock()
	defer e.mu.Unlock()

	if e.box == nil {
		return Traffic{}
	}

	type totalTrafficGetter interface {
		TotalTraffic() (int64, int64)
	}

	if n := e.box.Network(); n != nil {
		if tg, ok := n.(totalTrafficGetter); ok {
			up, down := tg.TotalTraffic()
			return Traffic{Up: up, Down: down}
		}
	}

	return Traffic{}
}

// ResetTraffic resets traffic counters
func (e *Engine) ResetTraffic() {
	// sing-box traffic counters are usually session-based
	// Resetting requires restarting the traffic monitor
}

// GetConnections returns active connections as JSON
func (e *Engine) GetConnections() string {
	e.mu.Lock()
	defer e.mu.Unlock()

	if e.box == nil {
		return "{}"
	}

	type connLister interface {
		Connections() []interface{}
	}

	if n := e.box.Network(); n != nil {
		if cl, ok := n.(connLister); ok {
			conns := cl.Connections()
			data, _ := json.Marshal(conns)
			return string(data)
		}
	}

	return "{}"
}

// CloseConnection closes a specific connection by ID
func (e *Engine) CloseConnection(id string) bool {
	e.mu.Lock()
	defer e.mu.Unlock()

	if e.box == nil {
		return false
	}

	type connCloser interface {
		CloseConnection(id string) bool
	}

	if n := e.box.Network(); n != nil {
		if cc, ok := n.(connCloser); ok {
			return cc.CloseConnection(id)
		}
	}

	return false
}

// CloseConnections closes all connections
func (e *Engine) CloseConnections() bool {
	e.mu.Lock()
	defer e.mu.Unlock()

	if e.box == nil {
		return false
	}

	type connCloser interface {
		CloseConnections() bool
	}

	if n := e.box.Network(); n != nil {
		if cc, ok := n.(connCloser); ok {
			return cc.CloseConnections()
		}
	}

	return false
}

// GetCountryCode returns the country code for an IP
func (e *Engine) GetCountryCode(ip string) string {
	e.mu.Lock()
	defer e.mu.Unlock()

	type geoLookup interface {
		LookupCode(ip string) string
	}

	// sing-box provides geo lookup through route/router
	if e.box != nil {
		type routerGetter interface {
			Router() interface{}
		}
		if rg, ok := e.box.(routerGetter); ok {
			router := rg.Router()
			if gl, ok := router.(geoLookup); ok {
				return gl.LookupCode(ip)
			}
		}
	}
	return ""
}

// GetMemory returns memory usage
func (e *Engine) GetMemory() uint64 {
	var stats runtime.MemStats
	runtime.ReadMemStats(&stats)
	return stats.Sys
}

// StartLog starts the log subscriber
func (e *Engine) StartLog() {
	e.mu.Lock()
	defer e.mu.Unlock()

	// sing-box log is configured at box creation time
	// Events are received through the log observable
	// For now, this is a placeholder - the actual log hook
	// is set up during box creation
}

// StopLog stops the log subscriber
func (e *Engine) StopLog() {
	e.mu.Lock()
	defer e.mu.Unlock()

	if e.logCancel != nil {
		e.logCancel()
		e.logCancel = nil
	}
}

// Suspend suspends or resumes the engine
func (e *Engine) Suspend(suspended bool) bool {
	// sing-box doesn't have a suspend concept
	// We could close/reopen, but that would break connections
	// For now, this is a no-op
	return true
}

// StartListener starts accepting connections
func (e *Engine) StartListener() bool {
	e.mu.Lock()
	defer e.mu.Unlock()

	if e.currentJSON == nil {
		return false
	}

	if e.box != nil {
		// Already running
		return true
	}

	return e.startBox(e.currentJSON) == ""
}

// StopListener stops accepting connections
func (e *Engine) StopListener() bool {
	e.mu.Lock()
	defer e.mu.Unlock()

	if e.box != nil {
		e.box.Close()
		e.box = nil
	}
	return true
}

// GetExternalProviders returns external provider list
func (e *Engine) GetExternalProviders() string {
	if e.providerMgr == nil {
		return "[]"
	}
	return e.providerMgr.GetAll()
}

// GetExternalProvider returns a specific external provider
func (e *Engine) GetExternalProvider(name string) string {
	if e.providerMgr == nil {
		return ""
	}
	return e.providerMgr.Get(name)
}

// UpdateExternalProvider updates a specific provider
func (e *Engine) UpdateExternalProvider(name string) string {
	if e.providerMgr == nil {
		return "provider manager not initialized"
	}
	return e.providerMgr.Update(name)
}

// UpdateGeoData updates geo data files
func (e *Engine) UpdateGeoData(geoType, geoName string) string {
	// sing-box has built-in geo data handling
	// For now, download to home directory
	path := filepath.Join(e.homeDir, geoName)

	switch geoType {
	case "MMDB", "GEOIP":
		// Download from sing-box's default source
		_, err := box.DownloadGeoResources(e.homeDir, &option.BoxSettings{
			GeoIP: &option.GeoIPOptions{
				Path: path,
			},
		})
		if err != nil {
			return err.Error()
		}
	case "GEOSITE":
		_, err := box.DownloadGeoResources(e.homeDir, &option.BoxSettings{
			GeoSite: &option.GeoSiteOptions{
				Path: path,
			},
		})
		if err != nil {
			return err.Error()
		}
	}
	return ""
}

// UpdateDns updates the system DNS
func (e *Engine) UpdateDns(value string) {
	// sing-box DNS is configured in the config
	// Runtime DNS updates would require config reload
}

// isGroupOutboundType checks if an outbound type is a group
func isGroupOutboundType(t string) bool {
	switch t {
	case "selector", "urltest", "fallback", "loadbalance":
		return true
	}
	return false
}

// Delay data type
type Delay struct {
	Url   string `json:"url"`
	Name  string `json:"name"`
	Value int32  `json:"value"`
}

// Traffic data type
type Traffic struct {
	Up   int64 `json:"up"`
	Down int64 `json:"down"`
}

// SetupParams for config setup
type SetupParams struct {
	SelectedMap map[string]string `json:"selected-map"`
	TestURL     string            `json:"test-url"`
}

// UpdateParams for runtime config updates
type UpdateParams struct {
	Tun             *TunUpdate        `json:"tun"`
	MixedPort       *int              `json:"mixed-port"`
	AllowLan        *bool             `json:"allow-lan"`
	FindProcessMode *string           `json:"find-process-mode"`
	Mode            *string           `json:"mode"`
	LogLevel        *string           `json:"log-level"`
	IPv6            *bool             `json:"ipv6"`
	TCPConcurrent   *bool             `json:"tcp-concurrent"`
	InterfaceName   *string           `json:"interface-name"`
	UnifiedDelay    *bool             `json:"unified-delay"`
}

type TunUpdate struct {
	Enable       bool    `json:"enable"`
	Device       *string `json:"device"`
	Stack        *string `json:"stack"`
	DNSHijack    *[]string `json:"dns-hijack"`
	AutoRoute    *bool   `json:"auto-route"`
	RouteAddress *[]string `json:"route-address"`
}

// LogEvent for log messages
type LogEvent struct {
	Level     string `json:"level"`
	Payload   string `json:"payload"`
	Timestamp int64  `json:"timestamp"`
}

// Message for event push
type Message struct {
	Type string      `json:"type"`
	Data interface{} `json:"data"`
}

// InitParams for engine initialization
type InitParams struct {
	HomeDir string `json:"home-dir"`
	Version int    `json:"version"`
}

// ChangeProxyParams for proxy selection
type ChangeProxyParams struct {
	GroupName string `json:"group-name"`
	ProxyName string `json:"proxy-name"`
}

// TestDelayParams for latency testing
type TestDelayParams struct {
	ProxyName string `json:"proxy-name"`
	TestUrl   string `json:"test-url"`
	Timeout   int64  `json:"timeout"`
}

// ProxiesData contains proxy information
type ProxiesData struct {
	Proxies map[string]interface{} `json:"proxies"`
	All     []string               `json:"all"`
}

// Connection represents an active connection
type Connection struct {
	ID          string      `json:"id"`
	Upload      int64       `json:"upload"`
	Download    int64       `json:"download"`
	Start       string      `json:"start"`
	Metadata    interface{} `json:"metadata"`
	Chain       []string    `json:"chains"`
	Rule        string      `json:"rule"`
	RulePayload string      `json:"rulePayload"`
}

// FormatDuration formats a duration as HH:MM:SS
func FormatDuration(d time.Duration) string {
	h := int(d.Hours())
	m := int(d.Minutes()) % 60
	s := int(d.Seconds()) % 60
	return fmt.Sprintf("%02d:%02d:%02d", h, m, s)
}

// GetRunTime returns the uptime string
func (e *Engine) GetRunTime(startTime time.Time) string {
	return FormatDuration(time.Since(startTime))
}
