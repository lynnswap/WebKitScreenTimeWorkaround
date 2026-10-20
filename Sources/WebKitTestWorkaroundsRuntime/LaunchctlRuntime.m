#import "WebKitTestWorkaroundsRuntime.h"

#if TARGET_OS_SIMULATOR

#include <errno.h>
#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

extern char **environ;

@interface WKTWLaunchctlResult ()
@property (nonatomic) int exitStatus;
@property (nonatomic, copy) NSData *output;
@end

@implementation WKTWLaunchctlResult
@end

static WKTWLaunchctlResult *CommandFailure(int code, NSString *operation, NSError **error)
{
    if (error) {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:code userInfo:@{
            NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@: %s", operation, strerror(code)],
        }];
    }
    return nil;
}

@implementation WKTWLaunchctl

+ (WKTWLaunchctlResult *)runWithArguments:(NSArray<NSString *> *)arguments error:(NSError **)error
{
    NSString *root = NSProcessInfo.processInfo.environment[@"SIMULATOR_ROOT"];
    if (!root.length)
        return CommandFailure(EINVAL, @"SIMULATOR_ROOT is unavailable", error);
    NSString *executable = [root stringByAppendingPathComponent:@"bin/launchctl"];

    // A temporary file drains both streams without a pipe filling while we wait.
    FILE *capture = tmpfile();
    if (!capture)
        return CommandFailure(errno, @"Could not capture launchctl output", error);

    char **argv = calloc(arguments.count + 2, sizeof(char *));
    if (!argv) {
        fclose(capture);
        return CommandFailure(ENOMEM, @"Could not allocate launchctl arguments", error);
    }
    argv[0] = (char *)executable.fileSystemRepresentation;
    for (NSUInteger index = 0; index < arguments.count; ++index)
        argv[index + 1] = (char *)arguments[index].UTF8String;

    posix_spawn_file_actions_t actions;
    int code = posix_spawn_file_actions_init(&actions);
    if (code) {
        free(argv);
        fclose(capture);
        return CommandFailure(code, @"Could not initialize launchctl file actions", error);
    }
    int descriptor = fileno(capture);
    code = posix_spawn_file_actions_adddup2(&actions, descriptor, STDOUT_FILENO);
    if (!code)
        code = posix_spawn_file_actions_adddup2(&actions, descriptor, STDERR_FILENO);
    if (!code && descriptor > STDERR_FILENO)
        code = posix_spawn_file_actions_addclose(&actions, descriptor);

    pid_t pid;
    if (!code)
        code = posix_spawn(&pid, executable.fileSystemRepresentation, &actions, NULL, argv, environ);
    posix_spawn_file_actions_destroy(&actions);
    free(argv);
    if (code) {
        fclose(capture);
        return CommandFailure(code, @"Could not start launchctl", error);
    }

    int status;
    pid_t waited;
    do {
        waited = waitpid(pid, &status, 0);
    } while (waited < 0 && errno == EINTR);
    if (waited < 0) {
        code = errno;
        fclose(capture);
        return CommandFailure(code, @"Could not wait for launchctl", error);
    }
    if (fseek(capture, 0, SEEK_SET)) {
        code = errno;
        fclose(capture);
        return CommandFailure(code, @"Could not read launchctl output", error);
    }
    NSMutableData *output = [NSMutableData data];
    char buffer[4096];
    size_t count;
    while ((count = fread(buffer, 1, sizeof(buffer), capture)))
        [output appendBytes:buffer length:count];
    if (ferror(capture)) {
        code = errno;
        fclose(capture);
        return CommandFailure(code, @"Could not read launchctl output", error);
    }
    fclose(capture);

    WKTWLaunchctlResult *result = [WKTWLaunchctlResult new];
    result.exitStatus = WIFEXITED(status) ? WEXITSTATUS(status) : 128 + WTERMSIG(status);
    result.output = output;
    return result;
}

@end

#endif
