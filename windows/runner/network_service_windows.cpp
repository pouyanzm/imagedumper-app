#include "network_service_windows.h"
#include <windows.h>
#include <iphlpapi.h>
#include <wlanapi.h>
#include <wininet.h>
#include <iostream>

#pragma comment(lib, "iphlpapi.lib")
#pragma comment(lib, "wlanapi.lib")
#pragma comment(lib, "wininet.lib")

bool NetworkServiceWindows::IsConnectedToWifiOrEthernet() {
    std::string networkType = GetNetworkType();
    return networkType == "wifi" || networkType == "ethernet";
}

std::string NetworkServiceWindows::GetNetworkType() {
    // First, check if we have any internet connectivity
    if (!IsConnected()) {
        return "none";
    }

    // Get adapter information
    ULONG bufferSize = 0;
    DWORD result = GetAdaptersInfo(nullptr, &bufferSize);
    
    if (result != ERROR_BUFFER_OVERFLOW) {
        return "none";
    }

    PIP_ADAPTER_INFO adapterInfo = (PIP_ADAPTER_INFO)malloc(bufferSize);
    if (adapterInfo == nullptr) {
        return "none";
    }

    result = GetAdaptersInfo(adapterInfo, &bufferSize);
    if (result != NO_ERROR) {
        free(adapterInfo);
        return "none";
    }

    PIP_ADAPTER_INFO adapter = adapterInfo;
    std::string primaryNetworkType = "none";

    while (adapter) {
        // Check if adapter is connected (has a valid IP)
        if (strcmp(adapter->IpAddressList.IpAddress.String, "0.0.0.0") != 0) {
            std::string adapterTypeStr = GetAdapterTypeString(adapter->Type);
            
            // Priority: ethernet > wifi > mobile
            if (adapterTypeStr == "ethernet") {
                primaryNetworkType = "ethernet";
                break; // Ethernet has highest priority
            } else if (adapterTypeStr == "wifi" && primaryNetworkType != "ethernet") {
                primaryNetworkType = "wifi";
            } else if (adapterTypeStr == "mobile" && primaryNetworkType == "none") {
                primaryNetworkType = "mobile";
            }
        }
        adapter = adapter->Next;
    }

    free(adapterInfo);
    return primaryNetworkType;
}

bool NetworkServiceWindows::IsConnected() {
    // Simple check using InternetGetConnectedState
    DWORD flags;
    return InternetGetConnectedState(&flags, 0) != 0;
}

std::string NetworkServiceWindows::GetAdapterTypeString(DWORD adapterType) {
    switch (adapterType) {
        case MIB_IF_TYPE_ETHERNET:
        case IF_TYPE_GIGABITETHERNET:
        case IF_TYPE_FASTETHER:
        case IF_TYPE_FASTETHER_FX:
            return "ethernet";
        case IF_TYPE_IEEE80211:
            return "wifi";
        case IF_TYPE_WWANPP:
        case IF_TYPE_WWANPP2:
        case IF_TYPE_WWAN:
            return "mobile";
        case MIB_IF_TYPE_PPP:
        case MIB_IF_TYPE_SLIP:
            // These could be mobile connections
            return "mobile";
        default:
            // For unknown types, try to detect based on description
            return "none";
    }
} 