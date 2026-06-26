package main

import (
	"encoding/json"
	"unsafe"
)

type Action struct {
	Id     string      `json:"id"`
	Method Method      `json:"method"`
	Data   interface{} `json:"data"`
}

type ActionResult struct {
	Id       string      `json:"id"`
	Method   Method      `json:"method"`
	Data     interface{} `json:"data"`
	Code     int         `json:"code"`
	callback unsafe.Pointer
}

func (result ActionResult) Json() ([]byte, error) {
	data, err := json.Marshal(result)
	return data, err
}

func (result ActionResult) success(data interface{}) {
	result.Code = 0
	result.Data = data
	result.send()
}

func (result ActionResult) error(data interface{}) {
	result.Code = -1
	result.Data = data
	result.send()
}

// NOTE: 使用 comma-ok 类型断言，避免外部传入错误类型时 Go panic 崩溃。
// 虽然是本地 IPC，但防御性编程能防止意外 crash。

func asString(data interface{}) (string, bool) {
	s, ok := data.(string)
	return s, ok
}

func asBool(data interface{}) (bool, bool) {
	b, ok := data.(bool)
	return b, ok
}

func handleAction(action *Action, result ActionResult) {
	switch action.Method {
	case initClashMethod:
		paramsString, ok := asString(action.Data)
		if !ok {
			result.error("invalid data type for initClash")
			return
		}
		result.success(handleInitClash(paramsString))
		return
	case getIsInitMethod:
		result.success(handleGetIsInit())
		return
	case forceGcMethod:
		handleForceGC()
		result.success(true)
		return
	case shutdownMethod:
		result.success(handleShutdown())
		return
	case validateConfigMethod:
		path, ok := asString(action.Data)
		if !ok {
			result.error("invalid data type for validateConfig")
			return
		}
		result.success(handleValidateConfig(path))
		return
	case updateConfigMethod:
		data, ok := asString(action.Data)
		if !ok {
			result.error("invalid data type for updateConfig")
			return
		}
		result.success(handleUpdateConfig([]byte(data)))
		return
	case setupConfigMethod:
		data, ok := asString(action.Data)
		if !ok {
			result.error("invalid data type for setupConfig")
			return
		}
		result.success(handleSetupConfig([]byte(data)))
		return
	case getProxiesMethod:
		result.success(handleGetProxies())
		return
	case changeProxyMethod:
		data, ok := asString(action.Data)
		if !ok {
			result.error("invalid data type for changeProxy")
			return
		}
		handleChangeProxy(data, func(value string) {
			result.success(value)
		})
		return
	case getTrafficMethod:
		data, ok := asBool(action.Data)
		if !ok {
			result.error("invalid data type for getTraffic")
			return
		}
		result.success(handleGetTraffic(data))
		return
	case getTotalTrafficMethod:
		data, ok := asBool(action.Data)
		if !ok {
			result.error("invalid data type for getTotalTraffic")
			return
		}
		result.success(handleGetTotalTraffic(data))
		return
	case resetTrafficMethod:
		handleResetTraffic()
		result.success(true)
		return
	case asyncTestDelayMethod:
		data, ok := asString(action.Data)
		if !ok {
			result.error("invalid data type for asyncTestDelay")
			return
		}
		handleAsyncTestDelay(data, func(value string) {
			result.success(value)
		})
		return
	case getConnectionsMethod:
		result.success(handleGetConnections())
		return
	case closeConnectionsMethod:
		result.success(handleCloseConnections())
		return
	case resetConnectionsMethod:
		result.success(handleResetConnections())
		return
	case getConfigMethod:
		path, ok := asString(action.Data)
		if !ok {
			result.error("invalid data type for getConfig")
			return
		}
		config, err := handleGetConfig(path)
		if err != nil {
			result.error(err)
			return
		}
		result.success(config)
		return
	case closeConnectionMethod:
		id, ok := asString(action.Data)
		if !ok {
			result.error("invalid data type for closeConnection")
			return
		}
		result.success(handleCloseConnection(id))
		return
	case getExternalProvidersMethod:
		result.success(handleGetExternalProviders())
		return
	case getExternalProviderMethod:
		externalProviderName, ok := asString(action.Data)
		if !ok {
			result.error("invalid data type for getExternalProvider")
			return
		}
		result.success(handleGetExternalProvider(externalProviderName))
	case updateGeoDataMethod:
		paramsString, ok := asString(action.Data)
		if !ok {
			result.error("invalid data type for updateGeoData")
			return
		}
		var params = map[string]string{}
		err := json.Unmarshal([]byte(paramsString), &params)
		if err != nil {
			result.success(err.Error())
			return
		}
		geoType := params["geo-type"]
		geoName := params["geo-name"]
		handleUpdateGeoData(geoType, geoName, func(value string) {
			result.success(value)
		})
		return
	case updateExternalProviderMethod:
		providerName, ok := asString(action.Data)
		if !ok {
			result.error("invalid data type for updateExternalProvider")
			return
		}
		handleUpdateExternalProvider(providerName, func(value string) {
			result.success(value)
		})
		return
	case sideLoadExternalProviderMethod:
		paramsString, ok := asString(action.Data)
		if !ok {
			result.error("invalid data type for sideLoadExternalProvider")
			return
		}
		var params = map[string]string{}
		err := json.Unmarshal([]byte(paramsString), &params)
		if err != nil {
			result.success(err.Error())
			return
		}
		providerName := params["providerName"]
		data := params["data"]
		handleSideLoadExternalProvider(providerName, []byte(data), func(value string) {
			result.success(value)
		})
		return
	case startLogMethod:
		handleStartLog()
		result.success(true)
		return
	case stopLogMethod:
		handleStopLog()
		result.success(true)
		return
	case startListenerMethod:
		result.success(handleStartListener())
		return
	case stopListenerMethod:
		result.success(handleStopListener())
		return
	case getCountryCodeMethod:
		ip, ok := asString(action.Data)
		if !ok {
			result.error("invalid data type for getCountryCode")
			return
		}
		handleGetCountryCode(ip, func(value string) {
			result.success(value)
		})
		return
	case getMemoryMethod:
		handleGetMemory(func(value string) {
			result.success(value)
		})
		return
	case crashMethod:
		result.success(true)
		handleCrash()
	case deleteFile:
		path, ok := asString(action.Data)
		if !ok {
			result.error("invalid data type for deleteFile")
			return
		}
		handleDelFile(path, result)
		return
	default:
		nextHandle(action, result)
	}
}
