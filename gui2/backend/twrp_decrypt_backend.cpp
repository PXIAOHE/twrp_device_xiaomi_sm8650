#include "twrp_decrypt_backend.h"

#include <openssl/evp.h>

#include <utility>

#include <sys/stat.h>
#include <sys/system_properties.h>
#include <unistd.h>

#include <cerrno>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

#include "data.hpp"
#include "partitions.hpp"
#include "twcommon.h"
#include "twrp_operation.h"
#include "twrpinstall/include/set_metadata.h"
#include "variables.h"

namespace gui2_backend {

twrp_decrypt_backend::~twrp_decrypt_backend() {
  if (worker_.joinable()) worker_.join();
}

bool twrp_decrypt_backend::is_encrypted() {
  if (DataManager::GetIntValue(TW_IS_FBE)) return TWPartition::DataIsLocked();
  return DataManager::GetIntValue(TW_IS_ENCRYPTED) != 0;
}

lock_kind twrp_decrypt_backend::kind() {
  switch (DataManager::GetIntValue(TW_CRYPTO_PWTYPE)) {
    case 1:
      return lock_kind::PASSWORD;
    case 2:
      return lock_kind::PATTERN;
    case 3:
      return lock_kind::PIN;
    default:
      return lock_kind::DEFAULT;
  }
}

void twrp_decrypt_backend::select_user() {
  DataManager::SetValue("tw_crypto_user_id", "0");
  DataManager::SetValue(TW_CRYPTO_PWTYPE, DataManager::GetStrValue("tw_crypto_pwtype_0"));
}

void twrp_decrypt_backend::join_finished_thread() {
  if (!running_.load() && worker_.joinable()) worker_.join();
}

bool twrp_decrypt_backend::start(const std::string& password) {
  if (running_.load()) return false;
  join_finished_thread();

  {
    std::lock_guard<std::mutex> lock(mutex_);
    state_ = decrypt_state::RUNNING;
  }
  running_.store(true);
  worker_ = std::thread(&twrp_decrypt_backend::run, this, password);
  return true;
}

bool twrp_decrypt_backend::start_refresh() {
  if (running_.load()) return false;
  join_finished_thread();

  {
    std::lock_guard<std::mutex> lock(mutex_);
    state_ = decrypt_state::RUNNING;
  }
  running_.store(true);
  worker_ = std::thread(&twrp_decrypt_backend::run_refresh, this);
  return true;
}

// GUIAction::refreshsizes
void twrp_decrypt_backend::run_refresh() {
  operation_start("Refreshing Sizes");
  // Defer the directory walk so leaving the decrypt prompt stays responsive.
  PartitionManager.UpdateSystemDetails(true);
  operation_end(0);
  {
    std::lock_guard<std::mutex> lock(mutex_);
    state_ = decrypt_state::DONE;
  }
  running_.store(false);
}

// The worker owns its password; do not publish it through global UI state.
void twrp_decrypt_backend::run(std::string password) {
  int op_status = 0;

  operation_start("Decrypt");
  {
    std::string userID;

    if (DataManager::GetIntValue(TW_IS_FBE)) {  // for FBE
      DataManager::GetValue("tw_crypto_user_id", userID);
      if (userID != "") {
        op_status = PartitionManager.DecryptDevice(password, atoi(userID.c_str()));
        if (userID != "0") {
          if (op_status != 0) op_status = 1;
          operation_end(op_status);
          finish(op_status);
          return;
        }
      } else {
        LOGINFO("User ID not found\n");
        op_status = 1;
      }
    } else {  // for FDE
      op_status = PartitionManager.DecryptDevice(password);
    }

    if (op_status != 0)
      op_status = 1;
    else {
      DataManager::SetValue(TW_IS_ENCRYPTED, 0);
      // Remember what unlocked the partition so the next boot can skip the
      // prompt; the General Settings switch can veto this, and the
      // default-password sentinel is not a real secret.
      if (!password.empty() && password != "!" &&
          DataManager::GetStrValue("tw_gui2_remember_pwd") != "0")
        store_saved_crypto_password(password);
      DataManager::SetBackupFolder();
      PartitionManager.AddMtpStorage("/data");

      int has_datamedia;

      // Refresh storage metadata after unlocking data.
      DataManager::GetValue(TW_HAS_DATA_MEDIA, has_datamedia);
      if (has_datamedia != 0) {
        if (tw_get_default_metadata(DataManager::GetCurrentStoragePath().c_str()) != 0) {
          LOGINFO("Failed to get default contexts and file mode for storage files.\n");
        } else {
          LOGINFO("Got default contexts and file mode for storage files.\n");
        }
      }
    }
  }

  operation_end(op_status);
  finish(op_status);
}

void twrp_decrypt_backend::finish(int op_status) {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    state_ = op_status == 0 ? decrypt_state::DONE : decrypt_state::FAILED;
  }
  running_.store(false);
}

decrypt_state twrp_decrypt_backend::state() {
  std::lock_guard<std::mutex> lock(mutex_);
  return state_;
}

void twrp_decrypt_backend::acknowledge() {
  join_finished_thread();
  std::lock_guard<std::mutex> lock(mutex_);
  if (state_ != decrypt_state::RUNNING) state_ = decrypt_state::IDLE;
}

std::string load_otg_crypto_password() {
  std::vector<PartitionList> list;
  PartitionManager.GetPartitionList("mount", &list);
  for (const PartitionList& entry : list) {
    const std::string& point = entry.mount_point;
    if (point.rfind("/usbotg", 0) != 0 && point.rfind("/usb-otg", 0) != 0 &&
        point.rfind("/usb_otg", 0) != 0)
      continue;
    if (!PartitionManager.IsMountedByPath(point)) {
      if (!PartitionManager.MountByPath(point, false)) {
        LOGINFO("saved-password: could not mount %s\n", point.c_str());
        continue;
      }
    }
    std::string password = load_password_file(point + "/TWRP/.twrp_crypto_pwd");
    if (password.empty()) password = load_password_file(point + "/TWRP/twrp_crypto_pwd");
    if (!password.empty()) {
      LOGINFO("saved-password: using the copy on %s\n", point.c_str());
      return password;
    }
  }
  return std::string();
}
}  // namespace gui2_backend
