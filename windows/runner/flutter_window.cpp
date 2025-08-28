#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "network_service_windows.h"
#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/standard_method_codec.h>
#include <thread>
#include <chrono>

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project), is_monitoring_(false) {}

FlutterWindow::~FlutterWindow() {
  StopNetworkMonitoring();
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  
  // Set up method channel for network service
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "network_service",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name().compare("isConnectedToWifiOrEthernet") == 0) {
          bool isWifiOrEthernet = NetworkServiceWindows::IsConnectedToWifiOrEthernet();
          result->Success(flutter::EncodableValue(isWifiOrEthernet));
        } else if (call.method_name().compare("getNetworkType") == 0) {
          std::string networkType = NetworkServiceWindows::GetNetworkType();
          result->Success(flutter::EncodableValue(networkType));
        } else if (call.method_name().compare("isConnected") == 0) {
          bool isConnected = NetworkServiceWindows::IsConnected();
          result->Success(flutter::EncodableValue(isConnected));
        } else if (call.method_name().compare("startNetworkMonitoring") == 0) {
          this->StartNetworkMonitoring();
          result->Success();
        } else if (call.method_name().compare("stopNetworkMonitoring") == 0) {
          this->StopNetworkMonitoring();
          result->Success();
        } else {
          result->NotImplemented();
        }
      });

  // Set up event channel for network events
  auto event_channel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "network_service/events",
      &flutter::StandardMethodCodec::GetInstance());

  event_channel->SetStreamHandler(std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
      [this](const flutter::EncodableValue* arguments,
              std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) 
              -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        event_sink_ = std::move(events);
        return nullptr;
      },
      [this](const flutter::EncodableValue* arguments) 
              -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        event_sink_.reset();
        return nullptr;
      }));
  
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::StartNetworkMonitoring() {
  if (is_monitoring_.load()) {
    return;
  }
  
  is_monitoring_.store(true);
  
  monitoring_thread_ = std::thread([this]() {
    std::string lastNetworkType = "";
    bool lastIsConnected = false;
    bool lastIsWifiOrEthernet = false;
    
    while (is_monitoring_.load()) {
      std::string currentNetworkType = NetworkServiceWindows::GetNetworkType();
      bool currentIsConnected = NetworkServiceWindows::IsConnected();
      bool currentIsWifiOrEthernet = NetworkServiceWindows::IsConnectedToWifiOrEthernet();
      
      // Check if network state changed
      if (currentNetworkType != lastNetworkType || 
          currentIsConnected != lastIsConnected ||
          currentIsWifiOrEthernet != lastIsWifiOrEthernet) {
        
        lastNetworkType = currentNetworkType;
        lastIsConnected = currentIsConnected;
        lastIsWifiOrEthernet = currentIsWifiOrEthernet;
        
        SendNetworkUpdate();
      }
      
      std::this_thread::sleep_for(std::chrono::milliseconds(1000)); // Check every second
    }
  });
  
  // Send initial state
  SendNetworkUpdate();
}

void FlutterWindow::StopNetworkMonitoring() {
  if (is_monitoring_.load()) {
    is_monitoring_.store(false);
    if (monitoring_thread_.joinable()) {
      monitoring_thread_.join();
    }
  }
}

void FlutterWindow::SendNetworkUpdate() {
  if (event_sink_) {
    auto networkData = flutter::EncodableMap{
      {flutter::EncodableValue("isConnected"), flutter::EncodableValue(NetworkServiceWindows::IsConnected())},
      {flutter::EncodableValue("isWifiOrEthernet"), flutter::EncodableValue(NetworkServiceWindows::IsConnectedToWifiOrEthernet())},
      {flutter::EncodableValue("networkType"), flutter::EncodableValue(NetworkServiceWindows::GetNetworkType())},
      {flutter::EncodableValue("timestamp"), flutter::EncodableValue(static_cast<int64_t>(std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count()))}
    };
    
    event_sink_->Success(flutter::EncodableValue(networkData));
  }
}
