#pragma once

#include <cstdarg>
#include <cstdio>
#include <ctime>
#include <unistd.h>

// 启动留痕：每走一步往 persist 上写一行并 fsync。
// recovery 里 /mnt/vendor/persist 在 UI 之前就挂好了，进程崩了这行也还在，
// 拿回来就能知道它停在哪一步。
inline void boot_note(const char* fmt, ...) {
  static const char* kPath = "/mnt/vendor/persist/TWRP/boot.log";
  FILE* f = fopen(kPath, "a");
  if (f == nullptr) return;
  std::time_t t = std::time(nullptr);
  struct tm parts {};
  localtime_r(&t, &parts);
  fprintf(f, "[%02d:%02d:%02d pid=%d] ", parts.tm_hour, parts.tm_min, parts.tm_sec,
          static_cast<int>(getpid()));
  va_list ap;
  va_start(ap, fmt);
  vfprintf(f, fmt, ap);
  va_end(ap);
  fputc('\n', f);
  fflush(f);
  fsync(fileno(f));
  fclose(f);
}
