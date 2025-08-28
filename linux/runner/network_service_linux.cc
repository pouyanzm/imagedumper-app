#include "network_service_linux.h"
#include <fstream>
#include <sstream>
#include <vector>
#include <filesystem>
#include <algorithm>
#include <sys/socket.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <unistd.h>

bool NetworkServiceLinux::IsConnectedToWifiOrEthernet() {
    std::string networkType = GetNetworkType();
    return networkType == "wifi" || networkType == "ethernet";
}

std::string NetworkServiceLinux::GetNetworkType() {
    if (!IsConnected()) {
        return "none";
    }

    std::vector<std::string> active_interfaces;
    
    // Get all network interfaces
    struct ifaddrs *ifaddr, *ifa;
    if (getifaddrs(&ifaddr) == -1) {
        return "none";
    }

    // Check each interface
    for (ifa = ifaddr; ifa != nullptr; ifa = ifa->ifa_next) {
        if (ifa->ifa_addr == nullptr) continue;
        
        // Only check IPv4 interfaces
        if (ifa->ifa_addr->sa_family == AF_INET) {
            std::string interface_name = ifa->ifa_name;
            
            // Skip loopback
            if (interface_name == "lo") continue;
            
            // Check if interface has a valid IP address
            struct sockaddr_in* addr_in = (struct sockaddr_in*)ifa->ifa_addr;
            if (addr_in->sin_addr.s_addr != 0) {
                if (IsInterfaceUp(interface_name)) {
                    active_interfaces.push_back(interface_name);
                }
            }
        }
    }
    
    freeifaddrs(ifaddr);

    // Determine the primary network type
    std::string primary_type = "none";
    
    for (const auto& interface : active_interfaces) {
        std::string type = GetInterfaceType(interface);
        
        // Priority: ethernet > wifi > mobile
        if (type == "ethernet") {
            primary_type = "ethernet";
            break; // Ethernet has highest priority
        } else if (type == "wifi" && primary_type != "ethernet") {
            primary_type = "wifi";
        } else if (type == "mobile" && primary_type == "none") {
            primary_type = "mobile";
        }
    }
    
    return primary_type;
}

bool NetworkServiceLinux::IsConnected() {
    // Check if we can create a socket and there are active interfaces
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock == -1) {
        return false;
    }
    close(sock);
    
    // Check if we have any non-loopback interfaces with valid IPs
    struct ifaddrs *ifaddr, *ifa;
    if (getifaddrs(&ifaddr) == -1) {
        return false;
    }
    
    bool connected = false;
    for (ifa = ifaddr; ifa != nullptr; ifa = ifa->ifa_next) {
        if (ifa->ifa_addr == nullptr) continue;
        
        if (ifa->ifa_addr->sa_family == AF_INET) {
            std::string interface_name = ifa->ifa_name;
            if (interface_name != "lo") { // Skip loopback
                struct sockaddr_in* addr_in = (struct sockaddr_in*)ifa->ifa_addr;
                if (addr_in->sin_addr.s_addr != 0) {
                    connected = true;
                    break;
                }
            }
        }
    }
    
    freeifaddrs(ifaddr);
    return connected;
}

std::string NetworkServiceLinux::GetInterfaceType(const std::string& interface_name) {
    // Check interface type based on naming convention and /sys filesystem
    
    // Check wireless interfaces
    std::string wireless_path = "/sys/class/net/" + interface_name + "/wireless";
    if (std::filesystem::exists(wireless_path)) {
        return "wifi";
    }
    
    // Check interface type from /sys/class/net/<interface>/type
    std::string type_path = "/sys/class/net/" + interface_name + "/type";
    std::ifstream type_file(type_path);
    if (type_file.is_open()) {
        std::string type_str;
        std::getline(type_file, type_str);
        int type = std::stoi(type_str);
        
        // Type 1 is typically Ethernet
        if (type == 1) {
            // Further classify based on interface name
            if (interface_name.find("wl") != std::string::npos || 
                interface_name.find("wlan") != std::string::npos ||
                interface_name.find("wifi") != std::string::npos) {
                return "wifi";
            } else if (interface_name.find("eth") != std::string::npos ||
                       interface_name.find("en") != std::string::npos ||
                       interface_name.find("em") != std::string::npos) {
                return "ethernet";
            } else if (interface_name.find("wwan") != std::string::npos ||
                       interface_name.find("ppp") != std::string::npos ||
                       interface_name.find("usb") != std::string::npos) {
                return "mobile";
            }
            
            // Default for type 1 is ethernet
            return "ethernet";
        }
    }
    
    // Fallback: classify based on interface name patterns
    if (interface_name.find("wl") != std::string::npos || 
        interface_name.find("wlan") != std::string::npos ||
        interface_name.find("wifi") != std::string::npos) {
        return "wifi";
    } else if (interface_name.find("eth") != std::string::npos ||
               interface_name.find("en") != std::string::npos ||
               interface_name.find("em") != std::string::npos) {
        return "ethernet";
    } else if (interface_name.find("wwan") != std::string::npos ||
               interface_name.find("ppp") != std::string::npos) {
        return "mobile";
    }
    
    return "ethernet"; // Default fallback
}

bool NetworkServiceLinux::IsInterfaceUp(const std::string& interface_name) {
    std::string operstate_path = "/sys/class/net/" + interface_name + "/operstate";
    std::ifstream operstate_file(operstate_path);
    
    if (operstate_file.is_open()) {
        std::string state;
        std::getline(operstate_file, state);
        return state == "up";
    }
    
    return false;
} 