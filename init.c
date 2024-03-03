#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include <string.h>

#include <dlfcn.h>

#include <bsp.h>
#include <rtems.h>
#include <rtems/shell.h>
#include <rtems/untar.h>
#include <rtems/ramdisk.h>
#include <rtems/rtl/dlfcn-shell.h>
#include <rtems/rtl/rtl-unresolved.h>

#include "init.h"

extern int _binary_tarfile_start;
extern int _binary_tarfile_size;

#define  RAMDISK_BLOCK_SIZE  (512)
#define  RAMDISK_BLOCK_COUNT 8192
#define  RAMDISK_PATH "/dev/rda"

void shell(void) {

    rtems_status_code ret;

    ret = ramdisk_register(
            RAMDISK_BLOCK_SIZE,
            RAMDISK_BLOCK_COUNT,
            false,
            RAMDISK_PATH);
    printf("RDISK: %s (%u)\n", rtems_status_text(ret), ret);

    ret = rtems_shell_init(
            "shell",
            RTEMS_MINIMUM_STACK_SIZE * 4,
            100,
            "/dev/console",
            false,
            false,
            NULL);
    printf("SHELL: %s (%u)\n", rtems_status_text(ret), ret);

    return;
}

void tarfs (void) {

    int ret;

    ret = Untar_FromMemory(
            (unsigned char *)(&_binary_tarfile_start),
            (unsigned long)&_binary_tarfile_size);
    printf("TARFS: %s (%u)\n", rtems_status_text(ret), ret);

    return;
}

static bool rtems_rtl_check_unresolved(rtems_rtl_unresolv_rec *rec, void *data)
{

    switch (rec->type)
    {
        case rtems_rtl_unresolved_symbol:
            printf("unresolved symbol: %s\n", rec->rec.name.name);
            break;
        default:
            break;
    }
    return false;
}

void dl_test(char *path) {

    int unresolved;
    void *dl_handle;

    dlerror();
    dl_handle = dlopen(path, RTLD_NOW | RTLD_GLOBAL);
    if (dl_handle == NULL)
    {
        printf("Error loading shared library: %s\n", dlerror());
    }
    else if (dlinfo(dl_handle, RTLD_DI_UNRESOLVED, &unresolved) < 0)
    {
        printf("dlinfo error checking unresolved status\n");
    }
    else if (unresolved)
    {
        printf("Module has unresolved externals\n");
        rtems_rtl_unresolved_iterate(rtems_rtl_check_unresolved, &(int) {0});
    }

    return;
}

rtems_task Init(rtems_task_argument ignored) {

    shell();
    tarfs();

#if 0
    printf ("\nLoading single object files!\n");
    dl_test("/mnt/obj0.o");
    dl_test("/mnt/obj1.o");
#else
    printf ("\nLoading a relocatable object file!\n");
    dl_test("/mnt/relocatable.obj");
#endif

    printf("Executing shell-script!\n");
    (void) rtems_shell_script ("dlcmds", 60 * 1024, 20, "/mnt/shell-script", "stdout", 0, 1, 1);

    //(void) rtems_task_delete(RTEMS_SELF);

    exit(0);
}

#define CONFIGURE_APPLICATION_NEEDS_CLOCK_DRIVER
#define CONFIGURE_APPLICATION_NEEDS_CONSOLE_DRIVER
#define CONFIGURE_APPLICATION_NEEDS_LIBBLOCK

#define CONFIGURE_UNLIMITED_OBJECTS
#define CONFIGURE_UNIFIED_WORK_AREAS

#define CONFIGURE_RTEMS_INIT_TASKS_TABLE

#define CONFIGURE_FILESYSTEM_IMFS
#define CONFIGURE_FILESYSTEM_RFS
#define CONFIGURE_FILESYSTEM_MSDOS

#define CONFIGURE_MAXIMUM_FILE_DESCRIPTORS 100

#define CONFIGURE_INIT

#include <rtems/confdefs.h>

#define CONFIGURE_SHELL_COMMANDS_INIT
#define CONFIGURE_SHELL_COMMANDS_ALL

extern int rtems_rtl_shell_command(int argc, char *argv[]);

rtems_shell_cmd_t rtems_shell_RTL_Command = {
    .name = "rtl", .usage = "rtl COMMAND...", .topic = "misc", .command = rtems_rtl_shell_command};
rtems_shell_cmd_t rtems_shell_dlopen_Command = {
    .name = "dlopen", .usage = "dlopen COMMAND...", .topic = "misc", .command = shell_dlopen};
rtems_shell_cmd_t rtems_shell_dlsym_Command = {
    .name = "dlsym", .usage = "dlsym COMMAND...", .topic = "misc", .command = shell_dlsym};

#define CONFIGURE_SHELL_USER_COMMANDS &rtems_shell_RTL_Command, &rtems_shell_dlopen_Command, &rtems_shell_dlsym_Command

#include <rtems/shellconfig.h>
