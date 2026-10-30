// Saved decrypt password: the recovery remembers what unlocked /data, so the
// next boot can unlock without asking. Lives in a header because GUI2 is a
// shared library of its own now: both it and the recovery binary need these,
// and only the OTG copy needs the partition manager that lives in the binary.
#pragma once

#include <sys/stat.h>
#include <sys/system_properties.h>

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

#include <android/log.h>
#include <openssl/evp.h>

#ifndef TW_DECRYPT_LOG
#define TW_DECRYPT_LOG(...) __android_log_print(ANDROID_LOG_INFO, "gui2-decrypt", __VA_ARGS__)
#endif

namespace gui2_backend {
namespace {


// Persist lives on its own partition and is readable before /data unlocks,
// which is the whole point: the next boot reads the password back before it
// can mount anything that is encrypted.
constexpr const char* kPersistDir = "/mnt/vendor/persist/TWRP";
constexpr const char* kSavedPasswordPath = "/mnt/vendor/persist/TWRP/.twrp_crypto_pwd";
constexpr size_t kMaxSavedPassword = 256;
constexpr size_t kMaxSavedFileSize = kMaxSavedPassword + 64;
// "TWG2" is the original AES format: the key depended on whether the serial
// happened to be readable at that moment. "TWG3" stores that fact in a flag
// byte, so encrypt and decrypt always derive the same key. Files without
// either magic come from the earlier obfuscation scheme (read once for
// compatibility).
constexpr char kEncryptedMagic[4] = { 'T', 'W', 'G', '2' };
constexpr char kBoundMagic[4] = { 'T', 'W', 'G', '3' };
constexpr uint8_t kFlagDeviceBound = 0x01;
constexpr size_t kMagicSize = sizeof(kEncryptedMagic);
constexpr size_t kFlagSize = 1;
constexpr size_t kIvSize = 16;
constexpr uint8_t kLegacyObfuscation = 0x5A;

std::string read_device_secret() {
  // The property is the reliable source: init derives it from bootconfig on
  // Android 12+ and from the kernel cmdline before that, so it is available
  // from the moment recovery starts and does not depend on which proc files
  // happen to be readable.
  char prop[PROP_VALUE_MAX] = {};
  if (__system_property_get("ro.boot.serialno", prop) > 0 && prop[0] != '\0')
    return std::string(prop);
  prop[0] = '\0';
  if (__system_property_get("ro.serialno", prop) > 0 && prop[0] != '\0')
    return std::string(prop);
  FILE* cmdline = fopen("/proc/cmdline", "r");
  if (cmdline != nullptr) {
    char buffer[4096];
    const size_t size = fread(buffer, 1, sizeof(buffer) - 1, cmdline);
    fclose(cmdline);
    buffer[size] = '\0';
    const std::string line(buffer, size);
    static const char key[] = "androidboot.serialno=";
    const size_t pos = line.find(key);
    if (pos != std::string::npos) {
      const size_t start = pos + sizeof(key) - 1;
      size_t end = line.find_first_of(" \n", start);
      if (end == std::string::npos) end = line.size();
      if (end > start) return line.substr(start, end - start);
    }
  }
  FILE* dt = fopen("/proc/device-tree/serial-number", "rb");
  if (dt != nullptr) {
    char buffer[256];
    const size_t size = fread(buffer, 1, sizeof(buffer) - 1, dt);
    fclose(dt);
    std::string serial(buffer, size);
    while (!serial.empty() &&
           (serial.back() == '\0' || serial.back() == '\n' || serial.back() == ' '))
      serial.pop_back();
    if (!serial.empty()) return serial;
  }
  return std::string();
}

// Device-bound key: the file only decrypts on the device that wrote it. The
// key is SHA256(salt || serial); when no serial can be read, the salt alone
// is used, which is weaker, so it is logged.
void derive_password_key(uint8_t key[32], bool use_serial) {
  const std::string secret = use_serial ? read_device_secret() : std::string();
  if (use_serial && secret.empty())
    TW_DECRYPT_LOG("saved-password: no device serial found; using the salt-only key\n");
  static const char salt[] = "TWRP GUI2 saved crypto password v2";
  EVP_MD_CTX* ctx = EVP_MD_CTX_new();
  if (ctx == nullptr) {
    memset(key, 0, 32);
    return;
  }
  EVP_DigestInit_ex(ctx, EVP_sha256(), nullptr);
  EVP_DigestUpdate(ctx, salt, sizeof(salt) - 1);
  if (!secret.empty()) EVP_DigestUpdate(ctx, secret.data(), secret.size());
  unsigned int length = 0;
  EVP_DigestFinal_ex(ctx, key, &length);
  EVP_MD_CTX_free(ctx);
}

bool aes_encrypt_password(const std::string& plain, std::vector<uint8_t>& out) {
  const std::string secret = read_device_secret();
  const bool bound = !secret.empty();
  uint8_t key[32];
  derive_password_key(key, bound);
  if (!bound)
    TW_DECRYPT_LOG("saved-password: no device serial; writing a salt-only (not device-bound) file\n");
  uint8_t iv[16];
  FILE* random = fopen("/dev/urandom", "rb");
  const size_t got = random == nullptr ? 0 : fread(iv, 1, sizeof(iv), random);
  if (random != nullptr) fclose(random);
  if (got != sizeof(iv)) memset(iv, 0, sizeof(iv));

  out.assign(kMagicSize + kFlagSize + kIvSize, 0);
  memcpy(out.data(), kBoundMagic, kMagicSize);
  out[kMagicSize] = bound ? kFlagDeviceBound : 0;
  memcpy(out.data() + kMagicSize + kFlagSize, iv, kIvSize);

  std::vector<uint8_t> body(plain.size() + 16);
  int out_len = 0;
  int final_len = 0;
  bool ok = false;
  EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
  if (ctx != nullptr) {
    ok = EVP_EncryptInit_ex(ctx, EVP_aes_256_cbc(), nullptr, key, iv) != 0 &&
         EVP_EncryptUpdate(ctx, body.data(), &out_len,
                           reinterpret_cast<const uint8_t*>(plain.data()),
                           static_cast<int>(plain.size())) != 0 &&
         EVP_EncryptFinal_ex(ctx, body.data() + out_len, &final_len) != 0;
    EVP_CIPHER_CTX_free(ctx);
  }
  if (!ok) return false;
  body.resize(static_cast<size_t>(out_len) + static_cast<size_t>(final_len));
  out.insert(out.end(), body.begin(), body.end());
  return true;
}

bool decrypt_with_key(const uint8_t* iv, const uint8_t* ciphertext, size_t ciphertext_size,
                      const uint8_t key[32], std::string& plain) {
  if (ciphertext_size == 0 || ciphertext_size % 16 != 0) return false;
  std::string out;
  out.resize(ciphertext_size + 16);
  int out_len = 0;
  int final_len = 0;
  bool ok = false;
  EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
  if (ctx != nullptr) {
    ok = EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), nullptr, key, iv) != 0 &&
         EVP_DecryptUpdate(ctx, reinterpret_cast<uint8_t*>(out.data()), &out_len,
                           ciphertext, static_cast<int>(ciphertext_size)) != 0 &&
         EVP_DecryptFinal_ex(ctx, reinterpret_cast<uint8_t*>(out.data()) + out_len,
                             &final_len) != 0;
    EVP_CIPHER_CTX_free(ctx);
  }
  if (!ok) return false;
  out.resize(static_cast<size_t>(out_len) + static_cast<size_t>(final_len));
  plain.swap(out);
  return true;
}

bool aes_decrypt_password(const uint8_t* data, size_t size, std::string& plain) {
  uint8_t key[32];
  if (size >= kMagicSize && memcmp(data, kBoundMagic, kMagicSize) == 0) {
    // TWG3: the flag byte records how the key was derived at save time.
    const size_t header = kMagicSize + kFlagSize + kIvSize;
    if (size < header + 16) return false;
    const bool bound = (data[kMagicSize] & kFlagDeviceBound) != 0;
    derive_password_key(key, bound);
    return decrypt_with_key(data + kMagicSize + kFlagSize, data + header, size - header,
                            key, plain);
  }
  if (size >= kMagicSize && memcmp(data, kEncryptedMagic, kMagicSize) == 0) {
    // TWG2: no flag byte. Try the device-bound derivation first, then the
    // salt-only one that older images wrote when the serial was unreadable.
    const size_t header = kMagicSize + kIvSize;
    if (size < header + 16) return false;
    derive_password_key(key, true);
    if (decrypt_with_key(data + kMagicSize, data + header, size - header, key, plain))
      return true;
    derive_password_key(key, false);
    return decrypt_with_key(data + kMagicSize, data + header, size - header, key, plain);
  }
  return false;
}

std::string load_password_file(const std::string& path) {
  FILE* file = fopen(path.c_str(), "rb");
  if (file == nullptr) return std::string();
  uint8_t raw[kMaxSavedFileSize];
  const size_t size = fread(raw, 1, sizeof(raw), file);
  fclose(file);
  if (size == 0) return std::string();
  if (size >= kMagicSize &&
      (memcmp(raw, kEncryptedMagic, kMagicSize) == 0 ||
       memcmp(raw, kBoundMagic, kMagicSize) == 0)) {
    std::string plain;
    if (!aes_decrypt_password(raw, size, plain)) {
      TW_DECRYPT_LOG("saved-password: %s does not decrypt on this device\n", path.c_str());
      return std::string();
    }
    if (plain.size() > kMaxSavedPassword) return std::string();
    return plain;
  }
  // The old scheme: single-byte obfuscation without device binding. Read once
  // for compatibility; the next successful unlock rewrites it in the new form.
  std::string password;
  password.reserve(size);
  for (size_t i = 0; i < size; ++i)
    password.push_back(static_cast<char>(raw[i] ^ kLegacyObfuscation));
  if (password.size() > kMaxSavedPassword) password.resize(kMaxSavedPassword);
  return password;
}

}  // namespace


inline std::string load_saved_crypto_password() {
  struct stat st {};
  const bool exists = stat(kSavedPasswordPath, &st) == 0;
  TW_DECRYPT_LOG("saved-password: load %s exists=%d size=%ld\n", kSavedPasswordPath,
          exists ? 1 : 0, exists ? static_cast<long>(st.st_size) : -1L);
  std::string password = load_password_file(kSavedPasswordPath);
  TW_DECRYPT_LOG("saved-password: load result len=%zu\n", password.size());
  return password;
}

inline void store_saved_crypto_password(const std::string& password) {
  if (password.empty() || password.size() > kMaxSavedPassword) return;
  std::vector<uint8_t> file;
  if (!aes_encrypt_password(password, file)) return;
  // The folder normally exists already (the settings file lives there);
  // EEXIST is fine, anything else just means the write below fails too.
  if (mkdir(kPersistDir, 0777) != 0 && errno != EEXIST)
    TW_DECRYPT_LOG("saved-password: mkdir %s failed (errno=%d)\n", kPersistDir, errno);
  FILE* out = fopen(kSavedPasswordPath, "wb");
  if (out == nullptr) {
    TW_DECRYPT_LOG("saved-password: open %s for write failed (errno=%d)\n",
            kSavedPasswordPath, errno);
    return;
  }
  const size_t written = fwrite(file.data(), 1, file.size(), out);
  fclose(out);
  if (written != file.size()) {
    TW_DECRYPT_LOG("saved-password: short write %zu/%zu to %s\n", written, file.size(),
            kSavedPasswordPath);
    remove(kSavedPasswordPath);
    return;
  }
  chmod(kSavedPasswordPath, 0600);
  TW_DECRYPT_LOG("saved-password: stored %zu bytes to %s\n", written, kSavedPasswordPath);
}

inline void clear_saved_crypto_password() { remove(kSavedPasswordPath); }

// A user-made copy of the same file on a USB stick is an external key: the
// device never writes it, and it is left in place when it stops working.


}  // namespace gui2_backend
