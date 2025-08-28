#ifndef NETWORK_SERVICE_LINUX_H_
#define NETWORK_SERVICE_LINUX_H_

#include <string>

class NetworkServiceLinux {
public:
    static bool IsConnectedToWifiOrEthernet();
    static std::string GetNetworkType();
    static bool IsConnected();

private:
    static std::string GetInterfaceType(const std::string& interface_name);
    static bool IsInterfaceUp(const std::string& interface_name);
};

#endif  // NETWORK_SERVICE_LINUX_H_ 