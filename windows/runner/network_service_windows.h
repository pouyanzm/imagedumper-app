#ifndef NETWORK_SERVICE_WINDOWS_H_
#define NETWORK_SERVICE_WINDOWS_H_

#include <string>

class NetworkServiceWindows {
public:
    static bool IsConnectedToWifiOrEthernet();
    static std::string GetNetworkType();
    static bool IsConnected();

private:
    static std::string GetAdapterTypeString(DWORD adapterType);
};

#endif  // NETWORK_SERVICE_WINDOWS_H_ 