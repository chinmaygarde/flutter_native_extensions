#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "dart_api.h"

char* NewReversedString(const char *str) {
  const size_t length = strlen(str);
  char *reversed = calloc(length + 1, sizeof(char));

  if (reversed == NULL) {
    return NULL;
  }

  for (size_t i = 0; i < length; i++) {
    reversed[i] = str[length - i - 1];
  }

  return reversed;
}

// The signature of your custom callback.
typedef void(*OnRootIsolateDidStart)(void);

// This symbol is present in the Flutter engine.
extern OnRootIsolateDidStart gOnRootIsolateDidStart;

// This gets run during dylib initialization and registers your custom callback that
// gets called on isolate initialization.
void RegisterRootIsolateDidStartCallback(void) __attribute__((constructor));

// Forward decl of you function.
void CustomOnRootIsolateDidStart(void);

// Gets called on dylib initialization.
void RegisterRootIsolateDidStartCallback(void) {
  gOnRootIsolateDidStart = &CustomOnRootIsolateDidStart;
}

// This function is called by the VM and is responsible for converting Dart argument handles to
// native types as necessary and setting the return value of the invocation.
void NewReversedStringWrapper(Dart_NativeArguments arguments) {
  // Parse arguments and convert from Dart types to native types. All this should
  // be templated.
  Dart_Handle string_argument = Dart_GetNativeArgument(arguments, 0);
  assert(!Dart_IsError(string_argument));

  const char *string = NULL;
  Dart_Handle result = Dart_StringToCString(string_argument, &string);
  assert(!Dart_IsError(result));
  assert(string != NULL);

  // FINALLY! Call the C method.
  char *reversed = NewReversedString(string);

  // Convert back to Dart handles and set the return value.
  Dart_Handle return_value = Dart_NewStringFromCString(reversed);
  assert(!Dart_IsError(return_value));
  Dart_SetReturnValue(arguments, return_value);

  // Cleanup.
  free(reversed);
}

// This will get called by the Dart code when it finds a native call in your library.
// "Your library" in this case is the root library. But, if the native call originates
// from another Dart library, the "CustomOnRootIsolateDidStart" can be updated
// to reference the library by name.
Dart_NativeFunction CustomNativeEntryResolver(Dart_Handle name,
                                              int num_of_arguments,
                                              bool* auto_setup_scope) {
  // TODO: We would have a map here that matches by name and arity. But we only
  // have one function, so just return that pointer.
  return &NewReversedStringWrapper;
}

const uint8_t* CustomNativeEntrySymbol(Dart_NativeFunction native_function) {
  // TODO: We would lookup the name by the the function pointer in a map of registrations.
  // But, we only have a single method, so just return its name.
  return (const uint8_t *)"reverseStringInNativeCode";
}

void CustomOnRootIsolateDidStart(void) {
  // This is on Flutters "UI" thread and is invoked as soon as the isolate is launched.

  // If you added your native call in a library other than the ROOT library, you can
  // use Dart_LookupLibrary by name and use that for the first argument.

  Dart_Handle handle = Dart_SetNativeResolver(Dart_RootLibrary(), &CustomNativeEntryResolver, &CustomNativeEntrySymbol);
  assert(!Dart_IsError(handle));
}

int main(int argc, char* argv[]) {
  @autoreleasepool {
    return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
  }
}
